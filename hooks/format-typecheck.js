#!/usr/bin/env node
// Stop hook: after a reply finishes, format and type-check the JS/TS files
// that reply actually touched. One formatter run per project root, one
// `tsc --noEmit` per tsconfig — never one process per file.
//
// Rewritten from a blank page 2026-08-22 (machinery rebuild). The contract is
// hooks/tests/format-typecheck.test.js, whose fake binaries log their argv, so
// the assertions prove the batching and the file lists, not just "exit 0".
//
// THE RULES THAT MUST NEVER BEND:
//   - NEVER block. Exit 0 whatever happens, type errors included. The reply is
//     already written when this runs; a nonzero exit would strand the session
//     over a formatting nicety. Findings go to stderr as a warning.
//   - NEVER touch a project this hook does not understand. No package.json
//     above the file, no formatter the project itself declares, no binary in
//     the project's own node_modules/.bin — silent no-op. It installs nothing,
//     and it never runs a tool the project did not choose.
//   - NEVER hang. Every child process has a hard timeout and is SIGKILLed past
//     it; the miss is reported, the session moves on.

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const TIMEOUT_MS =
  Number(process.env.CLAUDE_FMT_TIMEOUT_MS) > 0
    ? Number(process.env.CLAUDE_FMT_TIMEOUT_MS)
    : 30_000;
const FILE_CAP = 200;
const CODE_EXTENSIONS = new Set(['.js', '.jsx', '.mjs', '.cjs', '.ts', '.tsx', '.mts', '.cts']);
const GENERATED_DIRS = new Set(['node_modules', 'dist', 'build', '.next']);

// --- what did THIS reply edit? ----------------------------------------------
// The transcript is walked backwards. Everything after the last real user turn
// (one whose content is not just tool_result blocks) belongs to the current
// reply; anything earlier was already handled when its own reply ended.
function filesEditedThisReply(transcriptPath) {
  let lines;
  try {
    lines = fs.readFileSync(transcriptPath, 'utf8').split('\n');
  } catch {
    return [];
  }
  const found = [];
  for (let i = lines.length - 1; i >= 0; i--) {
    const text = lines[i].trim();
    if (!text) continue;
    let entry;
    try {
      entry = JSON.parse(text);
    } catch {
      continue; // a torn trailing line is normal while the file is appended to
    }
    const message = entry && entry.message;
    const role = (message && message.role) || entry.type;
    const content = message && message.content;

    if (role === 'user') {
      const onlyToolResults =
        Array.isArray(content) && content.some((block) => block && block.type === 'tool_result');
      if (!onlyToolResults) break; // the turn that started this reply
      continue;
    }
    if (role !== 'assistant' || !Array.isArray(content)) continue;
    for (const block of content) {
      if (!block || block.type !== 'tool_use') continue;
      if (!['Edit', 'Write', 'MultiEdit'].includes(block.name)) continue;
      const fp = block.input && block.input.file_path;
      if (typeof fp === 'string' && fp.trim()) found.push(fp);
    }
  }
  return found;
}

// --- project discovery ------------------------------------------------------
function nearestPackageRoot(file) {
  let dir = path.dirname(file);
  for (;;) {
    if (fs.existsSync(path.join(dir, 'package.json'))) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

function readPackageJson(root) {
  try {
    return JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
  } catch {
    return null;
  }
}

function declaresDependency(pkg, name) {
  if (!pkg) return false;
  return ['dependencies', 'devDependencies', 'peerDependencies'].some(
    (field) => pkg[field] && typeof pkg[field] === 'object' && Object.hasOwn(pkg[field], name)
  );
}

function installedBinary(root, name) {
  const candidate = path.join(root, 'node_modules', '.bin', name);
  return fs.existsSync(candidate) ? candidate : null;
}

// A formatter runs only when the project DECLARES it (its own config file or a
// dependency entry) AND it is installed locally. Declared-but-absent is not
// this hook's problem to fix; installed-but-undeclared is not its call to make.
function chooseFormatter(root, pkg) {
  const biomeDeclared =
    ['biome.json', 'biome.jsonc'].some((f) => fs.existsSync(path.join(root, f))) ||
    declaresDependency(pkg, '@biomejs/biome');
  if (biomeDeclared) {
    const bin = installedBinary(root, 'biome');
    if (bin) return { name: 'biome', bin, args: ['format', '--write'] };
  }

  const prettierDeclared =
    [
      '.prettierrc', '.prettierrc.json', '.prettierrc.json5', '.prettierrc.yaml',
      '.prettierrc.yml', '.prettierrc.js', '.prettierrc.cjs', '.prettierrc.mjs',
      '.prettierrc.toml', 'prettier.config.js', 'prettier.config.cjs',
      'prettier.config.mjs', 'prettier.config.ts',
    ].some((f) => fs.existsSync(path.join(root, f))) ||
    declaresDependency(pkg, 'prettier') ||
    (pkg && pkg.prettier !== undefined);
  if (prettierDeclared) {
    const bin = installedBinary(root, 'prettier');
    if (bin) return { name: 'prettier', bin, args: ['--write'] };
  }

  return null;
}

function dropGitignored(root, files) {
  const result = spawnSync('git', ['check-ignore', '--stdin'], {
    cwd: root,
    input: files.join('\n'),
    encoding: 'utf8',
    timeout: TIMEOUT_MS,
  });
  // 0 = some ignored, 1 = none ignored; anything else means "cannot tell", and
  // formatting a file git would have ignored is the cheaper mistake.
  if (result.error || (result.status !== 0 && result.status !== 1)) return files;
  const ignored = new Set(
    (result.stdout || '')
      .split('\n')
      .map((s) => s.trim())
      .filter(Boolean)
      .map((s) => path.resolve(root, s))
  );
  return files.filter((f) => !ignored.has(f));
}

function runChild(bin, args, cwd) {
  return spawnSync(bin, args, { cwd, encoding: 'utf8', timeout: TIMEOUT_MS, killSignal: 'SIGKILL' });
}

function lastLines(text, n = 40) {
  return (text || '').split('\n').filter(Boolean).slice(-n).join('\n');
}

// --- main -------------------------------------------------------------------
function main() {
  let payload;
  try {
    payload = JSON.parse(fs.readFileSync(0, 'utf8'));
  } catch {
    return;
  }
  if (!payload || typeof payload !== 'object') return;
  if (payload.stop_hook_active) return; // this hook triggered this stop: don't loop

  const transcript = payload.transcript_path || payload.transcriptPath;
  if (!transcript) return;
  const cwd = payload.cwd || process.cwd();

  let files = filesEditedThisReply(transcript)
    .map((f) => (path.isAbsolute(f) ? f : path.resolve(cwd, f)))
    .filter((f) => CODE_EXTENSIONS.has(path.extname(f).toLowerCase()))
    .filter((f) => !f.split(path.sep).some((seg) => GENERATED_DIRS.has(seg)))
    .filter((f) => fs.existsSync(f));
  files = [...new Set(files)].slice(0, FILE_CAP);
  if (files.length === 0) return;

  const byRoot = new Map();
  for (const f of files) {
    const root = nearestPackageRoot(f);
    if (!root) continue; // no package.json anywhere above: not our project
    if (!byRoot.has(root)) byRoot.set(root, []);
    byRoot.get(root).push(f);
  }

  const warnings = [];
  for (const [root, rootFiles] of byRoot) {
    const kept = dropGitignored(root, rootFiles);
    if (kept.length === 0) continue;
    const pkg = readPackageJson(root);

    const formatter = chooseFormatter(root, pkg);
    if (formatter) {
      const r = runChild(formatter.bin, [...formatter.args, ...kept], root);
      if (r.error && r.error.code === 'ETIMEDOUT') {
        warnings.push(`${formatter.name} timed out after ${TIMEOUT_MS / 1000}s in ${root}`);
      } else if (r.status !== 0) {
        warnings.push(
          `${formatter.name} exited ${r.status} in ${root}:\n${lastLines(r.stderr || r.stdout, 20)}`
        );
      }
    }

    const tsconfig = path.join(root, 'tsconfig.json');
    if (!fs.existsSync(tsconfig)) continue;
    const tsc = installedBinary(root, 'tsc');
    if (!tsc) continue; // TypeScript declared but not installed: not our call
    const r = runChild(tsc, ['--noEmit', '-p', tsconfig], root);
    if (r.error && r.error.code === 'ETIMEDOUT') {
      warnings.push(`tsc timed out after ${TIMEOUT_MS / 1000}s in ${root}`);
    } else if (r.status !== 0) {
      warnings.push(`tsc --noEmit found type errors in ${root}:\n${lastLines(r.stdout || r.stderr)}`);
    }
  }

  if (warnings.length) {
    process.stderr.write(
      `FORMAT/TYPECHECK (warning only — nothing was blocked):\n${warnings.join('\n\n')}\n`
    );
  }
}

try {
  main();
} catch {
  // A post-reply convenience must never surface as a session error.
}
process.exit(0);
