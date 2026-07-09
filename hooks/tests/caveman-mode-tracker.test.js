// Tests for hooks/caveman-mode-tracker.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
// Note: this Node 24 build does not expand a bare directory arg to --test.
const { test, beforeEach } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

// Point the tracker at a throwaway dir BEFORE requiring it — never touch the
// real ~/.claude/.caveman-active. Pin the default mode so config files on the
// host machine can't change test outcomes.
const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'caveman-tracker-test-'));
process.env.CLAUDE_CONFIG_DIR = tmpDir;
process.env.CAVEMAN_DEFAULT_MODE = 'full';

const tracker = require('../caveman-mode-tracker');
const { readFlag } = require('../caveman-config');
const { flagPath } = tracker;

function rawFlag() {
  try { return fs.readFileSync(flagPath, 'utf8'); } catch (e) { return null; }
}
function clearFlag() {
  try { fs.unlinkSync(flagPath); } catch (e) {}
}
function captureStdout(fn) {
  const orig = process.stdout.write;
  let out = '';
  process.stdout.write = (chunk) => { out += chunk; return true; };
  try { fn(); } finally { process.stdout.write = orig; }
  return out;
}

beforeEach(clearFlag);

test('flagPath lives under the temp dir, not the real ~/.claude', () => {
  assert.ok(flagPath.startsWith(tmpDir));
});

test('/caveman <mode> writes each valid mode transition', () => {
  for (const mode of ['lite', 'full', 'ultra']) {
    tracker.parseSlashCommand(`/caveman ${mode}`);
    assert.strictEqual(rawFlag(), mode, `mode ${mode}`);
  }
});

test('/caveman with no arg falls back to default mode', () => {
  tracker.parseSlashCommand('/caveman');
  assert.strictEqual(rawFlag(), 'full');
});

test('/caveman wenyan-full is aliased to wenyan', () => {
  tracker.parseSlashCommand('/caveman wenyan-full');
  assert.strictEqual(rawFlag(), 'wenyan');
});

test('/caveman off|stop|disable removes the flag', () => {
  for (const arg of ['off', 'stop', 'disable']) {
    tracker.parseSlashCommand('/caveman ultra');
    tracker.parseSlashCommand(`/caveman ${arg}`);
    assert.strictEqual(rawFlag(), null, `arg ${arg}`);
  }
});

test('independent modes are not selectable via /caveman <arg>', () => {
  tracker.parseSlashCommand('/caveman lite');
  for (const arg of ['commit', 'review', 'compress']) {
    tracker.parseSlashCommand(`/caveman ${arg}`);
    assert.strictEqual(rawFlag(), 'lite', `arg ${arg} must not overwrite`);
  }
});

test('invalid mode arg and non-caveman prompts write nothing', () => {
  tracker.parseSlashCommand('/caveman bogus');
  assert.strictEqual(rawFlag(), null);
  tracker.parseSlashCommand('hello world');
  assert.strictEqual(rawFlag(), null);
});

test('natural-language activation phrases write the default mode', () => {
  for (const prompt of ['talk like caveman', 'enable caveman', 'caveman mode']) {
    clearFlag();
    tracker.detectNLActivation(prompt);
    assert.strictEqual(rawFlag(), 'full', `prompt "${prompt}"`);
  }
});

test('deactivation wording never triggers NL activation', () => {
  for (const prompt of ['stop caveman mode', 'turn off caveman mode']) {
    tracker.detectNLActivation(prompt);
    assert.strictEqual(rawFlag(), null, `prompt "${prompt}"`);
  }
});

test('"stop caveman" and "normal mode" phrases deactivate', () => {
  for (const prompt of ['stop caveman', 'disable caveman please', 'back to normal mode']) {
    tracker.parseSlashCommand('/caveman ultra');
    tracker.detectNLDeactivation(prompt);
    assert.strictEqual(rawFlag(), null, `prompt "${prompt}"`);
  }
});

test('unrelated prompts do not deactivate', () => {
  tracker.parseSlashCommand('/caveman lite');
  tracker.detectNLDeactivation('please stop the dev server');
  assert.strictEqual(rawFlag(), 'lite');
});

test('flag round-trip: safeWriteFlag output survives readFlag validation', () => {
  tracker.parseSlashCommand('/caveman ultra');
  assert.strictEqual(readFlag(flagPath), 'ultra');
  fs.writeFileSync(flagPath, 'not-a-real-mode');
  assert.strictEqual(readFlag(flagPath), null, 'garbage content must be rejected');
});

test('emitReinforcement announces the active mode', () => {
  tracker.parseSlashCommand('/caveman ultra');
  const out = captureStdout(() => tracker.emitReinforcement());
  const parsed = JSON.parse(out);
  assert.match(parsed.hookSpecificOutput.additionalContext, /CAVEMAN MODE ACTIVE \(ultra\)/);
  assert.strictEqual(parsed.hookSpecificOutput.hookEventName, 'UserPromptSubmit');
});

test('emitReinforcement is silent when flag is absent or independent-mode', () => {
  assert.strictEqual(captureStdout(() => tracker.emitReinforcement()), '');
  fs.writeFileSync(flagPath, 'commit');
  assert.strictEqual(captureStdout(() => tracker.emitReinforcement()), '');
});
