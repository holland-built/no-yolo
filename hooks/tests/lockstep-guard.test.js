// Tests for hooks/lockstep-guard.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
// process.exit() means this hook must be driven as a child process, not require()'d.
//
// Positive AND negative controls are mandatory here, one positive per shipped
// pattern. A denylist that silently stops matching passes every "nothing was
// blocked" assertion forever (see verify.sh §8a — the \b-on-macOS incident,
// where a scan went green on the one machine where it was blind). The DENY table
// below is the proof each pattern can still fire; the ALLOW table is the proof
// the mode is still usable enough that nobody switches it off.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'lockstep-guard.js');

function tmp({ held }) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'lockstep-guard-test-'));
  if (held) fs.writeFileSync(path.join(dir, '.lockstep-active'), '');
  return dir;
}

function runGuard(tmpDir, { payload, raw } = {}) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_CONFIG_DIR: tmpDir },
    input: raw !== undefined ? raw : payload === undefined ? '' : JSON.stringify(payload),
    encoding: 'utf8',
  });
}

const bash = (command) => ({ tool_name: 'Bash', tool_input: { command } });

// ------------------------------------------------- FILE EDITS (existing behaviour)

test('flag file present -> exit 2, stderr warns LOCKSTEP ACTIVE', () => {
  const result = runGuard(tmp({ held: true }));

  assert.strictEqual(result.status, 2);
  assert.match(result.stderr, /LOCKSTEP ACTIVE/);
});

test('flag file absent -> exit 0, empty stderr', () => {
  const result = runGuard(tmp({ held: false }));

  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
});

for (const tool of ['Edit', 'Write', 'NotebookEdit']) {
  test(`flag present + ${tool} -> exit 2, message unchanged`, () => {
    const r = runGuard(tmp({ held: true }), {
      payload: { tool_name: tool, tool_input: { file_path: '/tmp/x.js' } },
    });
    assert.strictEqual(r.status, 2);
    assert.match(r.stderr, /LOCKSTEP ACTIVE — file edits are blocked until the user agrees/);
    assert.match(r.stderr, /Do not retry this tool call/);
  });

  test(`flag ABSENT + ${tool} -> exit 0`, () => {
    const r = runGuard(tmp({ held: false }), {
      payload: { tool_name: tool, tool_input: { file_path: '/tmp/x.js' } },
    });
    assert.strictEqual(r.status, 0);
    assert.strictEqual(r.stderr, '');
  });
}

// ------------------------------------------------------- DESTRUCTIVE BASH (deny)
// At least one entry per shipped pattern, plus the flag-clustering variants.

const DENY = [
  // rm, every flag spelling
  'rm -rf /tmp/x',
  'rm -fr /tmp/x',
  'rm -Rf /tmp/x',
  'rm -r /tmp/x',
  'rm -f /tmp/x',
  'rm -r -f /tmp/x',
  'rm --recursive --force /tmp/x',
  'rm /tmp/x -rf',
  'sudo rm -rf /var/lib/thing',
  // git push, force in every spelling the skill names
  'git push --force origin main',
  'git push -f origin main',
  'git push --force-with-lease',
  'git push origin +main:main',
  // the rest of the destructive set
  'git reset --hard HEAD~3',
  'git clean -fd',
  'git clean -xfd',
  'git clean --force',
  'git checkout -- src/index.ts',
  'git checkout .',
  'git checkout HEAD -- .',
  'git restore src/index.ts',
  'git restore --staged --worktree src/index.ts',
  'git filter-repo --path secrets --invert-paths',
  'git filter-branch --tree-filter true HEAD',
  'git branch -D feature/old',
  'git branch -D -r origin/gone',
  'dd if=/dev/zero of=/dev/disk2 bs=1m',
  'sudo mkfs.ext4 /dev/sda1',
  "psql -c 'DROP TABLE users'",
  'psql -c "drop database analytics"',
  'psql -c "TRUNCATE TABLE events"',
  'truncate -s 0 /var/log/app.log',
  // chained — the whole string is judged, not the first token
  'npm test && rm -rf dist',
  'npm test; rm -rf dist',
  'npm run build || git reset --hard',
  'echo start && git push --force',
  'ls $(rm -rf /tmp/x)',
  // quoted: deliberately DENIED. `sh -c "rm -rf /"` is a real delete, so a
  // quoted rm -rf is treated as one. See START in the hook.
  'echo rm -rf /tmp/x',
  'echo "rm -rf /tmp/x"',
  'sh -c "rm -rf /tmp/x"',
];

for (const command of DENY) {
  test(`flag present + \`${command}\` -> exit 2`, () => {
    const r = runGuard(tmp({ held: true }), { payload: bash(command) });
    assert.strictEqual(r.status, 2, `should be blocked but exited ${r.status}`);
    assert.match(r.stderr, /LOCKSTEP ACTIVE — blocked a destructive command/);
  });
}

test('deny message names the matched command and the release, and does not say retry', () => {
  const r = runGuard(tmp({ held: true }), { payload: bash('npm test && rm -rf dist') });
  assert.strictEqual(r.status, 2);
  assert.match(r.stderr, /rm -rf dist/); // the matched segment, named
  assert.match(r.stderr, /matched: rm with -r \/ -f/);
  assert.match(r.stderr, /"go"/);
  assert.match(r.stderr, /\/lockstep off/);
  assert.match(r.stderr, /Do not retry this tool call/);
  assert.doesNotMatch(r.stderr, /try again|retry the command/i);
});

// ---------------------------------------------------- NON-DESTRUCTIVE BASH (allow)
// If holding blocked these, the mode would be unusable and would get switched
// off for good. That makes every line here load-bearing.

const ALLOW = [
  'git status',
  'git status --porcelain',
  'git log --oneline -20',
  'git diff --stat',
  'git clean -n',
  'git clean --dry-run',
  'git checkout -b feature/new',
  'git checkout main',
  'git branch -d merged-branch',
  'git branch --list',
  'git push origin main',
  'git push -u origin feature/new',
  'git restore --staged src/index.ts',
  'git stash list',
  'ls -la',
  'ls -R src',
  'grep -rn "TODO" src',
  'npm test',
  'npm run build',
  'node --test hooks/tests/lockstep-guard.test.js',
  'cat README.md',
  'echo hello',
  'find . -name "*.dd"',
  // the /lockstep skill's own on/off commands must survive the guard
  'touch "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.lockstep-active"',
  'rm -f "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.lockstep-active"',
];

for (const command of ALLOW) {
  test(`flag present + \`${command}\` -> exit 0`, () => {
    const r = runGuard(tmp({ held: true }), { payload: bash(command) });
    assert.strictEqual(r.status, 0, `should pass but exited ${r.status}: ${r.stderr}`);
    assert.strictEqual(r.stderr, '');
  });
}

test('a laundered release does not exempt the rest of the line', () => {
  const r = runGuard(tmp({ held: true }), {
    payload: bash('rm -rf /tmp/x && rm -f ~/.claude/.lockstep-active'),
  });
  assert.strictEqual(r.status, 2);
});

// ------------------------------------------------------- THE HOLD IS NOT A GUARD
// Lockstep is a hold, not a permanent destructive-command blocker. Released
// means released.

for (const command of DENY) {
  test(`flag ABSENT + \`${command}\` -> exit 0`, () => {
    const r = runGuard(tmp({ held: false }), { payload: bash(command) });
    assert.strictEqual(r.status, 0, `no hold is active; nothing should be blocked`);
    assert.strictEqual(r.stderr, '');
  });
}

// ------------------------------------------------------------- MALFORMED INPUT
// Never throws. With no hold, always allows. With a hold, an unreadable payload
// DENIES — lockstep fails closed on purpose (see the header comment): a stop
// order that goes quiet when the payload shape changes is the worst outcome,
// and the cost of a wrong deny is the user typing "go".

test('flag absent + empty stdin -> exit 0, no throw', () => {
  const r = runGuard(tmp({ held: false }), { raw: '' });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('flag absent + garbage stdin -> exit 0, no throw', () => {
  const r = runGuard(tmp({ held: false }), { raw: '{ not json at all' });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('flag absent + non-object JSON stdin -> exit 0, no throw', () => {
  const r = runGuard(tmp({ held: false }), { raw: '"just a string"' });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('flag present + garbage stdin -> exit 2 (fails closed), no throw', () => {
  const r = runGuard(tmp({ held: true }), { raw: '{ not json at all' });
  assert.strictEqual(r.status, 2);
  assert.match(r.stderr, /LOCKSTEP ACTIVE/);
});

test('flag present + Bash payload with no command -> exit 2 (fails closed)', () => {
  const r = runGuard(tmp({ held: true }), { payload: { tool_name: 'Bash', tool_input: {} } });
  assert.strictEqual(r.status, 2);
});

test('flag present + Bash command of the wrong type -> exit 2 (fails closed)', () => {
  const r = runGuard(tmp({ held: true }), { payload: bash(42) });
  assert.strictEqual(r.status, 2);
});

test('flag present + unknown tool -> exit 2 (fails closed)', () => {
  const r = runGuard(tmp({ held: true }), { payload: { tool_name: 'SomeFutureTool', tool_input: {} } });
  assert.strictEqual(r.status, 2);
});

test('camelCase payload keys are understood too', () => {
  const r = runGuard(tmp({ held: true }), {
    payload: { toolName: 'Bash', toolInput: { command: 'git status' } },
  });
  assert.strictEqual(r.status, 0);
});
