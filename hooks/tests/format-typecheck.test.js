// Tests for hooks/format-typecheck.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
//
// The formatter and tsc are FAKE binaries planted in node_modules/.bin that
// append their argv to a log file. That gives real positive controls without
// installing biome/prettier/typescript: the log proves the hook detected the
// tool, batched the files into ONE call, and passed the right paths. Asserting
// only "exit 0, no crash" would go green just as happily on a hook that had
// stopped doing anything at all (verify.sh §8a).
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'format-typecheck.js');

function tmp(tag = 'fmt-tc-') {
  return fs.mkdtempSync(path.join(os.tmpdir(), tag));
}

// A project root with package.json + whatever config/bins the test needs.
function project({ pkg = {}, configs = [], bins = {} } = {}) {
  const root = tmp('fmt-tc-proj-');
  const logDir = tmp('fmt-tc-log-');
  fs.writeFileSync(path.join(root, 'package.json'), JSON.stringify({ name: 'p', ...pkg }));
  for (const c of configs) fs.writeFileSync(path.join(root, c), '{}');

  const binDir = path.join(root, 'node_modules', '.bin');
  const logs = {};
  for (const [name, exitCode] of Object.entries(bins)) {
    fs.mkdirSync(binDir, { recursive: true });
    const log = path.join(logDir, `${name}.log`);
    logs[name] = log;
    fs.writeFileSync(
      path.join(binDir, name),
      `#!/bin/sh\nprintf '%s\\n' "$*" >> ${JSON.stringify(log)}\necho "fake ${name} output"\nexit ${exitCode}\n`,
      { mode: 0o755 }
    );
  }
  return { root, logs };
}

function writeFile(root, rel, body = 'export const a = 1\n') {
  const p = path.join(root, rel);
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, body);
  return p;
}

// Build a transcript where `files` were edited in the CURRENT response, and
// `priorFiles` were edited in an earlier response (before the last user turn).
function transcript({ files = [], priorFiles = [], tool = 'Edit' } = {}) {
  const p = path.join(tmp('fmt-tc-tr-'), 'transcript.jsonl');
  const edit = (f) => ({
    type: 'assistant',
    message: {
      role: 'assistant',
      content: [{ type: 'tool_use', name: tool, input: { file_path: f } }],
    },
  });
  const userTurn = { type: 'user', message: { role: 'user', content: 'do the thing' } };
  const toolResult = {
    type: 'user',
    message: { role: 'user', content: [{ type: 'tool_result', content: 'ok' }] },
  };

  const lines = [userTurn];
  for (const f of priorFiles) lines.push(edit(f), toolResult);
  lines.push(userTurn);
  for (const f of files) lines.push(edit(f), toolResult);

  fs.writeFileSync(p, lines.map((l) => JSON.stringify(l)).join('\n') + '\n');
  return p;
}

function run(payload, env = {}) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, ...env },
    input: typeof payload === 'string' ? payload : JSON.stringify(payload),
    encoding: 'utf8',
  });
}

function logLines(logPath) {
  if (!fs.existsSync(logPath)) return [];
  return fs.readFileSync(logPath, 'utf8').split('\n').filter(Boolean);
}

// ---------------------------------------------------------------- POSITIVE

test('prettier declared in devDependencies + installed -> invoked ONCE with all files', () => {
  const { root, logs } = project({
    pkg: { devDependencies: { prettier: '^3.0.0' } },
    bins: { prettier: 0 },
  });
  const a = writeFile(root, 'src/a.ts');
  const b = writeFile(root, 'src/b.tsx');

  const r = run({ transcript_path: transcript({ files: [a, b] }), cwd: root });

  assert.strictEqual(r.status, 0);
  const calls = logLines(logs.prettier);
  assert.strictEqual(calls.length, 1, 'must batch into ONE formatter invocation');
  assert.match(calls[0], /--write/);
  assert.ok(calls[0].includes(a) && calls[0].includes(b), `both files in argv: ${calls[0]}`);
});

test('prettier declared by config file alone (no dep entry) is still detected', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const a = writeFile(root, 'a.js');
  run({ transcript_path: transcript({ files: [a] }), cwd: root });
  assert.strictEqual(logLines(logs.prettier).length, 1);
});

test('biome wins over prettier when the project declares both', () => {
  const { root, logs } = project({
    pkg: { devDependencies: { prettier: '^3', '@biomejs/biome': '^1' } },
    configs: ['biome.json', '.prettierrc'],
    bins: { biome: 0, prettier: 0 },
  });
  const a = writeFile(root, 'a.ts');
  run({ transcript_path: transcript({ files: [a] }), cwd: root });
  assert.strictEqual(logLines(logs.biome).length, 1, 'biome should run');
  assert.strictEqual(logLines(logs.prettier).length, 0, 'prettier must NOT also run');
});

test('tsconfig.json present -> tsc --noEmit runs ONCE, exit 0 even when it fails', () => {
  const { root, logs } = project({
    pkg: { devDependencies: { typescript: '^5' } },
    configs: ['tsconfig.json'],
    bins: { tsc: 1 }, // type errors
  });
  const a = writeFile(root, 'a.ts');

  const r = run({ transcript_path: transcript({ files: [a] }), cwd: root });

  assert.strictEqual(r.status, 0, 'a type error must NEVER block');
  const calls = logLines(logs.tsc);
  assert.strictEqual(calls.length, 1);
  assert.match(calls[0], /--noEmit/);
  assert.match(r.stderr, /FORMAT\/TYPECHECK/);
  assert.match(r.stderr, /type errors/i);
});

test('MultiEdit and Write tool calls are picked up too', () => {
  for (const tool of ['Write', 'MultiEdit']) {
    const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
    const a = writeFile(root, 'a.ts');
    run({ transcript_path: transcript({ files: [a], tool }), cwd: root });
    assert.strictEqual(logLines(logs.prettier).length, 1, `${tool} should be collected`);
  }
});

test('a hanging formatter is killed at the timeout and reported, not hung', () => {
  const { root } = project({ configs: ['.prettierrc'] });
  const binDir = path.join(root, 'node_modules', '.bin');
  fs.mkdirSync(binDir, { recursive: true });
  fs.writeFileSync(path.join(binDir, 'prettier'), '#!/bin/sh\nsleep 30\n', { mode: 0o755 });
  const a = writeFile(root, 'a.ts');

  const started = Date.now();
  const r = run({ transcript_path: transcript({ files: [a] }), cwd: root }, {
    CLAUDE_FMT_TIMEOUT_MS: '1500',
  });

  assert.strictEqual(r.status, 0);
  assert.ok(Date.now() - started < 15000, 'must not wait for the hung command');
  assert.match(r.stderr, /timed out/i);
});

// ---------------------------------------------------------------- NEGATIVE

test('no formatter declared -> nothing runs, silent', () => {
  const { root, logs } = project({ bins: { prettier: 0 } }); // installed but NOT declared
  const a = writeFile(root, 'a.ts');
  const r = run({ transcript_path: transcript({ files: [a] }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
  assert.strictEqual(logLines(logs.prettier).length, 0);
});

test('formatter declared but NOT installed -> silent no-op, never npx-installs', () => {
  const { root } = project({ pkg: { devDependencies: { prettier: '^3' } } });
  const a = writeFile(root, 'a.ts');
  const r = run({ transcript_path: transcript({ files: [a] }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('no package.json anywhere above the file -> silent no-op', () => {
  const bare = tmp('fmt-tc-bare-');
  const a = writeFile(bare, 'a.ts');
  const r = run({ transcript_path: transcript({ files: [a] }), cwd: bare });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('no tsconfig.json -> tsc is not run even though it is installed', () => {
  const { root, logs } = project({
    pkg: { devDependencies: { typescript: '^5' } },
    bins: { tsc: 1 },
  });
  const a = writeFile(root, 'a.ts');
  const r = run({ transcript_path: transcript({ files: [a] }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(logLines(logs.tsc).length, 0);
  assert.strictEqual(r.stderr, '');
});

test('non-JS/TS edits (.md, .py, .json) are ignored', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const files = ['README.md', 'x.py', 'data.json'].map((f) => writeFile(root, f, 'x'));
  const r = run({ transcript_path: transcript({ files }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(logLines(logs.prettier).length, 0);
});

test('node_modules / dist / build / .next paths are skipped', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const files = [
    writeFile(root, 'node_modules/pkg/i.js'),
    writeFile(root, 'dist/out.js'),
    writeFile(root, 'build/out.js'),
    writeFile(root, '.next/page.js'),
  ];
  run({ transcript_path: transcript({ files }), cwd: root });
  assert.strictEqual(logLines(logs.prettier).length, 0);
});

test('files edited in an EARLIER response are not re-formatted', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const old = writeFile(root, 'old.ts');
  const fresh = writeFile(root, 'fresh.ts');

  run({ transcript_path: transcript({ files: [fresh], priorFiles: [old] }), cwd: root });

  const calls = logLines(logs.prettier);
  assert.strictEqual(calls.length, 1);
  assert.ok(calls[0].includes(fresh), 'current-response file must be formatted');
  assert.ok(!calls[0].includes(old), 'previous-response file must NOT be formatted');
});

test('a deleted file is not passed to the formatter', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const gone = path.join(root, 'gone.ts');
  const r = run({ transcript_path: transcript({ files: [gone] }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(logLines(logs.prettier).length, 0);
});

test('response with no edits at all -> silent no-op', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const r = run({ transcript_path: transcript({ files: [] }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
  assert.strictEqual(logLines(logs.prettier).length, 0);
});

test('stop_hook_active -> exits immediately (no re-entrancy loop)', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const a = writeFile(root, 'a.ts');
  const r = run({
    transcript_path: transcript({ files: [a] }),
    cwd: root,
    stop_hook_active: true,
  });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(logLines(logs.prettier).length, 0);
});

// ------------------------------------------------------------- FAIL OPEN

test('empty stdin -> exit 0, no throw', () => {
  const r = run('');
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('garbage stdin -> exit 0, no throw', () => {
  const r = run('{ not json at all');
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('missing transcript_path -> exit 0', () => {
  const r = run({ cwd: os.tmpdir() });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('transcript_path points at a nonexistent file -> exit 0', () => {
  const r = run({ transcript_path: path.join(tmp(), 'nope.jsonl'), cwd: os.tmpdir() });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('transcript with torn / non-JSON lines -> exit 0, still processes valid ones', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const a = writeFile(root, 'a.ts');
  const tp = transcript({ files: [a] });
  fs.appendFileSync(tp, '{"type":"assistant","message":{"role":"assist');

  const r = run({ transcript_path: tp, cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(logLines(logs.prettier).length, 1);
});
