// Contract for hooks/format-typecheck.js, the Stop hook that formats and
// type-checks whatever the finished reply touched.
//   node --test 'hooks/tests/*.test.js'
//
// Rewritten from a blank page 2026-08-22 (machinery rebuild), AFTER the hook and
// judged against it.
//
// THE FORMATTER AND tsc ARE FAKES. Each is a shell script planted in the
// project's node_modules/.bin that appends its argv to a log and exits with a
// chosen code. That gives real positive controls without installing biome,
// prettier or typescript, and the log is what proves the hook DETECTED the tool,
// BATCHED the files into one call, and passed the right paths. Asserting only
// "exit 0, no crash" would go green just as happily against a hook that had
// stopped doing anything at all, which is the exact blindness this repo keeps
// finding in its own checks.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const HOOK = path.join(__dirname, '..', 'format-typecheck.js');
const tmp = (tag = 'fmt-') => fs.mkdtempSync(path.join(os.tmpdir(), tag));

// A project root: package.json, whatever config files it declares, and fake
// binaries keyed by the exit code they should return.
function project({ pkg = {}, configs = [], bins = {} } = {}) {
  const root = tmp('fmt-proj-');
  const logDir = tmp('fmt-log-');
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
      `#!/bin/sh\nprintf '%s\\n' "$*" >> ${JSON.stringify(log)}\necho "fake ${name}"\nexit ${exitCode}\n`,
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

// A transcript in which `files` were edited in the CURRENT reply and `earlier`
// in a previous one. The hook walks backwards and stops at the last real user
// turn, so everything after that point is the current reply.
function transcript({ files = [], earlier = [], tool = 'Edit' } = {}) {
  const p = path.join(tmp('fmt-tr-'), 'transcript.jsonl');
  const edit = (f) => ({
    type: 'assistant',
    message: { role: 'assistant', content: [{ type: 'tool_use', name: tool, input: { file_path: f } }] },
  });
  const userTurn = { type: 'user', message: { role: 'user', content: 'do the thing' } };
  const toolResult = {
    type: 'user',
    message: { role: 'user', content: [{ type: 'tool_result', content: 'ok' }] },
  };
  const lines = [userTurn];
  for (const f of earlier) lines.push(edit(f), toolResult);
  lines.push(userTurn);
  for (const f of files) lines.push(edit(f), toolResult);
  fs.writeFileSync(p, lines.map((l) => JSON.stringify(l)).join('\n') + '\n');
  return p;
}

function run(payload, env = {}) {
  return spawnSync(process.execPath, [HOOK], {
    env: { ...process.env, ...env },
    input: typeof payload === 'string' ? payload : JSON.stringify(payload),
    encoding: 'utf8',
  });
}

const calls = (log) =>
  fs.existsSync(log) ? fs.readFileSync(log, 'utf8').split('\n').filter(Boolean) : [];

// ------------------------------------------------------- it actually runs

test('prettier declared as a dependency runs ONCE with every file', () => {
  const { root, logs } = project({
    pkg: { devDependencies: { prettier: '^3.0.0' } },
    bins: { prettier: 0 },
  });
  const a = writeFile(root, 'src/a.ts');
  const b = writeFile(root, 'src/b.tsx');

  const r = run({ transcript_path: transcript({ files: [a, b] }), cwd: root });

  assert.strictEqual(r.status, 0);
  const invocations = calls(logs.prettier);
  assert.strictEqual(invocations.length, 1, 'must batch into ONE invocation, not one per file');
  assert.match(invocations[0], /--write/);
  assert.ok(invocations[0].includes(a) && invocations[0].includes(b), 'both files in argv');
});

test('a config file alone declares prettier, with no dependency entry', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  run({ transcript_path: transcript({ files: [writeFile(root, 'a.js')] }), cwd: root });
  assert.strictEqual(calls(logs.prettier).length, 1);
});

test('biome wins when a project declares both, and prettier does not also run', () => {
  const { root, logs } = project({
    pkg: { devDependencies: { prettier: '^3', '@biomejs/biome': '^1' } },
    configs: ['biome.json', '.prettierrc'],
    bins: { biome: 0, prettier: 0 },
  });
  run({ transcript_path: transcript({ files: [writeFile(root, 'a.ts')] }), cwd: root });
  assert.strictEqual(calls(logs.biome).length, 1, 'biome should run');
  assert.strictEqual(calls(logs.prettier).length, 0, 'prettier must NOT also run');
});

test('Write and MultiEdit are collected as well as Edit', () => {
  for (const tool of ['Write', 'MultiEdit']) {
    const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
    run({ transcript_path: transcript({ files: [writeFile(root, 'a.ts')], tool }), cwd: root });
    assert.strictEqual(calls(logs.prettier).length, 1, `${tool} should be collected`);
  }
});

test('tsc runs once and a type error still exits 0', () => {
  const { root, logs } = project({
    pkg: { devDependencies: { typescript: '^5' } },
    configs: ['tsconfig.json'],
    bins: { tsc: 1 },
  });
  const r = run({ transcript_path: transcript({ files: [writeFile(root, 'a.ts')] }), cwd: root });

  // The reply is already written when this hook runs. Blocking here would strand
  // the session with no way forward, so a type error is a warning and never more.
  assert.strictEqual(r.status, 0, 'a type error must NEVER block');
  assert.strictEqual(calls(logs.tsc).length, 1);
  assert.match(calls(logs.tsc)[0], /--noEmit/);
  assert.match(r.stderr, /FORMAT\/TYPECHECK/);
  assert.match(r.stderr, /type errors/i);
});

test('a formatter exiting nonzero is reported, not swallowed, and still exits 0', () => {
  const { root } = project({ configs: ['.prettierrc'], bins: { prettier: 2 } });
  const r = run({ transcript_path: transcript({ files: [writeFile(root, 'a.ts')] }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.match(r.stderr, /prettier exited 2/);
});

test('a hanging command is killed at the timeout and reported', () => {
  const { root } = project({ configs: ['.prettierrc'] });
  const binDir = path.join(root, 'node_modules', '.bin');
  fs.mkdirSync(binDir, { recursive: true });
  fs.writeFileSync(path.join(binDir, 'prettier'), '#!/bin/sh\nsleep 30\n', { mode: 0o755 });

  const started = Date.now();
  const r = run({ transcript_path: transcript({ files: [writeFile(root, 'a.ts')] }), cwd: root },
    { CLAUDE_FMT_TIMEOUT_MS: '1500' });

  assert.strictEqual(r.status, 0);
  assert.ok(Date.now() - started < 15000, 'must not wait for the hung command');
  assert.match(r.stderr, /timed out/i);
});

// --------------------------------------------- it stays out of the way

test('a formatter installed but NOT declared is never run', () => {
  const { root, logs } = project({ bins: { prettier: 0 } });
  const r = run({ transcript_path: transcript({ files: [writeFile(root, 'a.ts')] }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
  assert.strictEqual(calls(logs.prettier).length, 0, 'the project did not choose it');
});

test('a formatter declared but NOT installed is never fetched', () => {
  const { root } = project({ pkg: { devDependencies: { prettier: '^3' } } });
  const r = run({ transcript_path: transcript({ files: [writeFile(root, 'a.ts')] }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '', 'must never npx-install anything');
});

test('a file with no package.json above it is left alone', () => {
  const bare = tmp('fmt-bare-');
  const r = run({ transcript_path: transcript({ files: [writeFile(bare, 'a.ts')] }), cwd: bare });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('no tsconfig means tsc does not run, even though it is installed', () => {
  const { root, logs } = project({ pkg: { devDependencies: { typescript: '^5' } }, bins: { tsc: 1 } });
  const r = run({ transcript_path: transcript({ files: [writeFile(root, 'a.ts')] }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(calls(logs.tsc).length, 0);
  assert.strictEqual(r.stderr, '');
});

test('non-code edits are ignored', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const files = ['README.md', 'x.py', 'data.json', 'style.css'].map((f) => writeFile(root, f, 'x'));
  run({ transcript_path: transcript({ files }), cwd: root });
  assert.strictEqual(calls(logs.prettier).length, 0);
});

test('generated directories are skipped', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const files = ['node_modules/pkg/i.js', 'dist/out.js', 'build/out.js', '.next/page.js']
    .map((f) => writeFile(root, f));
  run({ transcript_path: transcript({ files }), cwd: root });
  assert.strictEqual(calls(logs.prettier).length, 0);
});

test('files from an EARLIER reply are not re-formatted', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const old = writeFile(root, 'old.ts');
  const fresh = writeFile(root, 'fresh.ts');

  run({ transcript_path: transcript({ files: [fresh], earlier: [old] }), cwd: root });

  const argv = calls(logs.prettier);
  assert.strictEqual(argv.length, 1);
  assert.ok(argv[0].includes(fresh), 'this reply\'s file must be formatted');
  assert.ok(!argv[0].includes(old), 'the earlier reply\'s file must NOT be');
});

test('a file edited and then deleted is not passed to the formatter', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const gone = path.join(root, 'gone.ts');
  const r = run({ transcript_path: transcript({ files: [gone] }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(calls(logs.prettier).length, 0);
});

test('a reply that edited nothing does nothing', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const r = run({ transcript_path: transcript({ files: [] }), cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
  assert.strictEqual(calls(logs.prettier).length, 0);
});

test('stop_hook_active exits immediately, so this cannot loop on itself', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const r = run({
    transcript_path: transcript({ files: [writeFile(root, 'a.ts')] }),
    cwd: root,
    stop_hook_active: true,
  });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(calls(logs.prettier).length, 0);
});

// ------------------------------------------------------------- fail quiet

for (const [name, payload] of [
  ['empty stdin', ''],
  ['garbage stdin', '{ not json at all'],
  ['no transcript_path', { cwd: os.tmpdir() }],
]) {
  test(`${name} -> exit 0, silent`, () => {
    const r = run(payload);
    assert.strictEqual(r.status, 0);
    assert.strictEqual(r.stderr, '');
  });
}

test('a transcript_path that does not exist -> exit 0, silent', () => {
  const r = run({ transcript_path: path.join(tmp(), 'nope.jsonl'), cwd: os.tmpdir() });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('a torn final line is normal and does not stop the valid ones', () => {
  const { root, logs } = project({ configs: ['.prettierrc'], bins: { prettier: 0 } });
  const tp = transcript({ files: [writeFile(root, 'a.ts')] });
  // The transcript is appended to while the session runs, so the last line is
  // routinely half-written when this hook reads it.
  fs.appendFileSync(tp, '{"type":"assistant","message":{"role":"assist');

  const r = run({ transcript_path: tp, cwd: root });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(calls(logs.prettier).length, 1);
});
