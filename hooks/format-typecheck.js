#!/usr/bin/env node
// format-typecheck — Stop hook.
//
// After a reply finishes, format and type-check the JS/TS files that were
// actually touched during that response. Batched: ONE formatter invocation per
// project root and ONE `tsc --noEmit` per tsconfig, never one per file.
//
// Hard rules baked in:
//  - NEVER blocks. Always exit 0, even on a type error. This runs after the
//    reply is already written, so blocking here strands the user with no way
//    forward. Findings go to stderr as a warning.
//  - NEVER runs in a repo it does not understand. No package.json at the root,
//    no formatter the project actually declares, no locally installed binary ->
//    silent no-op. It will not npx-install anything.
//  - Hard per-command timeout so a slow `tsc` cannot hang the session.
//  - Skips node_modules / dist / build / .next and anything gitignored.
//
// Formatter detection order: biome -> prettier -> none. Detection is by the
// project's OWN config files and package.json deps, never by assumption, and
// the tool must be present in the root's node_modules/.bin to be run.

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

// Hard per-command ceiling. Override only for tests / a genuinely slow monorepo
// — a formatter or tsc that outlives this gets SIGKILLed rather than hanging the
// session, and the miss is reported as a warning.
const CMD_TIMEOUT_MS = Number(process.env.CLAUDE_FMT_TIMEOUT_MS) > 0
  ? Number(process.env.CLAUDE_FMT_TIMEOUT_MS)
  : 30_000;
const MAX_FILES = 200; // argv sanity cap
const CODE_EXT = new Set(['.js', '.jsx', '.mjs', '.cjs', '.ts', '.tsx', '.mts', '.cts']);
const SKIP_DIRS = new Set(['node_modules', 'dist', 'build', '.next']);

// ---------------------------------------------------------------- transcript

// Files edited during THIS response only: walk the transcript backwards from
// the end and stop at the previous real user turn (a turn whose content is not
// just tool_result blocks). Everything after that point is the current response.
function editedThisResponse(transcriptPath) {
  let lines;
  try {
    lines = fs.readFileSync(transcriptPath, 'utf8').split('\n');
  } catch {
    return [];
  }

  const files = [];
  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i].trim();
    if (!line) continue;
    let entry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue; // a torn last line is normal while the file is being appended
    }
    const msg = entry && entry.message;
    const role = (msg && msg.role) || entry.type;
    const content = msg && msg.content;

    if (role === 'user') {
      const isToolResult =
        Array.isArray(content) && content.some((b) => b && b.type === 'tool_result');
      if (!isToolResult) break; // start of the current response — stop here
      continue;
    }

    if (role !== 'assistant' || !Array.isArray(content)) continue;
    for (const block of content) {
      if (!block || block.type !== 'tool_use') continue;
      if (!['Edit', 'Write', 'MultiEdit'].includes(block.name)) continue;
      const fp = block.input && block.input.file_path;
      if (typeof fp === 'string' && fp.trim()) files.push(fp);
    }
  }
  return files;
}

// ------------------------------------------------------------------- filters

function isCodeFile(p) {
  return CODE_EXT.has(path.extname(p).toLowerCase());
}

function inSkippedDir(p) {
  return p.split(path.sep).some((seg) => SKIP_DIRS.has(seg));
}

function dropGitignored(root, files) {
  const r = spawnSync('git', ['check-ignore', '--stdin'], {
    cwd: root,
    input: files.join('\n'),
    encoding: 'utf8',
    timeout: CMD_TIMEOUT_MS,
  });
  // status 0 = some ignored, 1 = none ignored, anything else (no git, not a
  // repo) = can't tell, so keep everything.
  if (r.error || (r.status !== 0 && r.status !== 1)) return files;
  const ignored = new Set(
    (r.stdout || '')
      .split('\n')
      .map((s) => s.trim())
      .filter(Boolean)
      .map((s) => path.resolve(root, s))
  );
  return files.filter((f) => !ignored.has(f));
}

// --------------------------------------------------------------- project map

// Nearest ancestor directory containing package.json. No package.json anywhere
// above the file -> null, and the file is dropped: a repo without one is a repo
// this hook does not understand.
function findRoot(file) {
  let dir = path.dirname(file);
  for (;;) {
    if (fs.existsSync(path.join(dir, 'package.json'))) return dir;
    const up = path.dirname(dir);
    if (up === dir) return null;
    dir = up;
  }
}

function readPkg(root) {
  try {
    return JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
  } catch {
    return null;
  }
}

function hasDep(pkg, name) {
  if (!pkg) return false;
  for (const field of ['dependencies', 'devDependencies', 'peerDependencies']) {
    const deps = pkg[field];
    if (deps && typeof deps === 'object' && Object.hasOwn(deps, name)) return true;
  }
  return false;
}

function anyExists(root, names) {
  return names.some((n) => fs.existsSync(path.join(root, n)));
}

function localBin(root, name) {
  const p = path.join(root, 'node_modules', '.bin', name);
  return fs.existsSync(p) ? p : null;
}

// biome -> prettier -> none. Declared by config OR deps, AND installed locally.
function detectFormatter(root, pkg) {
  const declaredBiome =
    anyExists(root, ['biome.json', 'biome.jsonc']) || hasDep(pkg, '@biomejs/biome');
  if (declaredBiome) {
    const bin = localBin(root, 'biome');
    if (bin) return { name: 'biome', bin, args: ['format', '--write'] };
  }

  const declaredPrettier =
    anyExists(root, [
      '.prettierrc',
      '.prettierrc.json',
      '.prettierrc.json5',
      '.prettierrc.yaml',
      '.prettierrc.yml',
      '.prettierrc.js',
      '.prettierrc.cjs',
      '.prettierrc.mjs',
      '.prettierrc.toml',
      'prettier.config.js',
      'prettier.config.cjs',
      'prettier.config.mjs',
      'prettier.config.ts',
    ]) ||
    hasDep(pkg, 'prettier') ||
    (pkg && pkg.prettier !== undefined);
  if (declaredPrettier) {
    const bin = localBin(root, 'prettier');
    if (bin) return { name: 'prettier', bin, args: ['--write'] };
  }

  return null;
}

function run(bin, args, cwd) {
  return spawnSync(bin, args, {
    cwd,
    encoding: 'utf8',
    timeout: CMD_TIMEOUT_MS,
    killSignal: 'SIGKILL',
  });
}

function tail(text, n = 40) {
  return (text || '').split('\n').filter(Boolean).slice(-n).join('\n');
}

// ---------------------------------------------------------------------- main

function main() {
  let payload = {};
  try {
    const raw = fs.readFileSync(0, 'utf8');
    if (raw.trim()) payload = JSON.parse(raw);
  } catch {
    return;
  }
  if (!payload || typeof payload !== 'object') return;
  if (payload.stop_hook_active) return; // re-entrancy guard

  const transcript = payload.transcript_path || payload.transcriptPath;
  if (!transcript) return;

  const cwd = payload.cwd || process.cwd();
  let files = editedThisResponse(transcript)
    .map((f) => (path.isAbsolute(f) ? f : path.resolve(cwd, f)))
    .filter(isCodeFile)
    .filter((f) => !inSkippedDir(f))
    .filter((f) => fs.existsSync(f));

  files = [...new Set(files)].slice(0, MAX_FILES);
  if (files.length === 0) return;

  // Group by project root; files with no package.json above them are dropped.
  const byRoot = new Map();
  for (const f of files) {
    const root = findRoot(f);
    if (!root) continue;
    if (!byRoot.has(root)) byRoot.set(root, []);
    byRoot.get(root).push(f);
  }
  if (byRoot.size === 0) return;

  const warnings = [];

  for (const [root, rootFiles] of byRoot) {
    const kept = dropGitignored(root, rootFiles);
    if (kept.length === 0) continue;

    const pkg = readPkg(root);

    // 1. Format — one invocation for the whole batch.
    const fmt = detectFormatter(root, pkg);
    if (fmt) {
      const r = run(fmt.bin, [...fmt.args, ...kept], root);
      if (r.error && r.error.code === 'ETIMEDOUT') {
        warnings.push(`${fmt.name} timed out after ${CMD_TIMEOUT_MS / 1000}s in ${root}`);
      } else if (r.status !== 0) {
        warnings.push(
          `${fmt.name} exited ${r.status} in ${root}:\n${tail(r.stderr || r.stdout, 20)}`
        );
      }
    }

    // 2. Type-check — only if this root actually has a tsconfig.
    const tsconfig = path.join(root, 'tsconfig.json');
    if (!fs.existsSync(tsconfig)) continue;
    const tsc = localBin(root, 'tsc');
    if (!tsc) continue; // declared TS but not installed -> not our business

    const r = run(tsc, ['--noEmit', '-p', tsconfig], root);
    if (r.error && r.error.code === 'ETIMEDOUT') {
      warnings.push(`tsc timed out after ${CMD_TIMEOUT_MS / 1000}s in ${root}`);
    } else if (r.status !== 0) {
      warnings.push(`tsc --noEmit found type errors in ${root}:\n${tail(r.stdout || r.stderr)}`);
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
  // Never let a post-reply convenience hook surface as a session error.
}
process.exit(0);
