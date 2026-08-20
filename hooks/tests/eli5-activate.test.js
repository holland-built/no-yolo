// Tests for hooks/eli5-activate.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
//
// This hook shapes every reply in every session, so the things worth asserting
// are: the right text for the right event, the off switch actually switching
// off, and a broken config dir never taking a session down with it.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'eli5-activate.js');
const FLAG = '.eli5-active';

function tmp() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'eli5-test-'));
}

function run(tmpDir, args = [], extraEnv = {}) {
  const env = { ...process.env, CLAUDE_CONFIG_DIR: tmpDir, ...extraEnv };
  delete env.ELI5_MODE;
  Object.assign(env, extraEnv);
  return spawnSync(process.execPath, [hookPath, ...args], { env, encoding: 'utf8' });
}

test('no argument -> full ruleset (SessionStart is the default)', () => {
  const result = run(tmp());

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /ELI5 MODE ACTIVE/);
  assert.match(result.stdout, /## Word choice/);
  assert.match(result.stdout, /## Shape\. TABLE FIRST/);
  assert.strictEqual(result.stderr, '');
});

test('SessionStart -> full ruleset, including the exceptions section', () => {
  const result = run(tmp(), ['SessionStart']);

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /## Exceptions/);
  assert.match(result.stdout, /stop eli5/);
});

test('UserPromptSubmit -> short reminder, NOT the full ruleset', () => {
  const result = run(tmp(), ['UserPromptSubmit']);

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /ELI5 MODE ACTIVE/);
  assert.doesNotMatch(result.stdout, /## Word choice/);
  assert.doesNotMatch(result.stdout, /## Shape/);
});

test('the per-turn reminder is materially shorter than the ruleset', () => {
  const full = run(tmp(), ['SessionStart']).stdout;
  const short = run(tmp(), ['UserPromptSubmit']).stdout;

  // A reminder that has grown to ruleset size stops being a reminder.
  assert.ok(short.length < full.length / 2,
    `reminder is ${short.length} chars vs ruleset ${full.length} — no longer a reminder`);
});

test('reminder carries the rules that actually get broken', () => {
  const short = run(tmp(), ['UserPromptSubmit']).stdout;

  // These are the load-bearing rules. If one is dropped from the reminder
  // it stops being enforced per-turn, which is the whole point of the hook.
  assert.match(short, /TABLE FIRST/);
  assert.match(short, /HARD CAPS/);        // one table, five rows, three columns
  assert.match(short, /five rows/i);       // table row ceiling
  assert.match(short, /three columns/i);   // column ceiling
  assert.match(short, /cap at five/i);     // actions/options ceiling
  assert.match(short, /no jargon/i);

  // The caps only work if there is somewhere for a longer answer to GO. Without
  // the escape hatch the caps just teach it to drop facts, which is worse than
  // an over-long reply. Ruled 2026-08-20.
  assert.match(short, /Artifact/);
});

test('event argument is trimmed before dispatch', () => {
  const result = run(tmp(), [' UserPromptSubmit ']);

  assert.strictEqual(result.status, 0);
  assert.doesNotMatch(result.stdout, /## Word choice/);
});

test('unknown event -> falls back to the full ruleset, never empty output', () => {
  const result = run(tmp(), ['SomeFutureEvent']);

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /## Word choice/);
});

test('a run creates the .eli5-active flag in CLAUDE_CONFIG_DIR', () => {
  const dir = tmp();

  run(dir, ['SessionStart']);

  assert.strictEqual(fs.existsSync(path.join(dir, FLAG)), true);
});

test('ELI5_MODE=off -> prints only OK, emits no ruleset, clears the flag', () => {
  const dir = tmp();
  fs.writeFileSync(path.join(dir, FLAG), 'on');

  const result = run(dir, ['SessionStart'], { ELI5_MODE: 'off' });

  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stdout, 'OK');
  assert.doesNotMatch(result.stdout, /ELI5 MODE ACTIVE/);
  assert.strictEqual(fs.existsSync(path.join(dir, FLAG)), false);
});

test('ELI5_MODE=OFF (any case) also switches it off', () => {
  const result = run(tmp(), ['UserPromptSubmit'], { ELI5_MODE: 'OFF' });

  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stdout, 'OK');
});

test('ELI5_MODE=off with no flag on disk -> still exits 0, does not throw', () => {
  const result = run(tmp(), ['SessionStart'], { ELI5_MODE: 'off' });

  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stdout, 'OK');
  assert.strictEqual(result.stderr, '');
});

test('unwritable config dir -> still exits 0 and still emits the ruleset', () => {
  // The flag file is cosmetic. A session must never die because it could not
  // be written, so point CLAUDE_CONFIG_DIR at a path that cannot be created.
  const dir = tmp();
  const blocker = path.join(dir, 'not-a-dir');
  fs.writeFileSync(blocker, 'i am a file');

  const result = run(path.join(blocker, 'nested'), ['SessionStart']);

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /ELI5 MODE ACTIVE/);
  assert.strictEqual(result.stderr, '');
});
