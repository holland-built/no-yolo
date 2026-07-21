// Tests for hooks/literal-mode-tracker.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'literal-mode-tracker.js');

function runTracker(tmpDir, prompt) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_CONFIG_DIR: tmpDir },
    input: JSON.stringify({ prompt }),
    encoding: 'utf8',
  });
}

test('flag present, plain prompt -> stdout contains LITERAL MODE ACTIVE', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'literal-mode-test-'));
  fs.writeFileSync(path.join(tmpDir, '.literal-active'), '1');

  const result = runTracker(tmpDir, 'fix the header');

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /LITERAL MODE ACTIVE/);
});

test('flag absent, plain prompt -> no suppression emitted', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'literal-mode-test-'));

  const result = runTracker(tmpDir, 'make the header blue');

  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stdout.trim(), '');
});

test('flag absent, inline "just do it" -> suppression emitted, flag still absent after', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'literal-mode-test-'));

  const result = runTracker(tmpDir, 'just do it, no more debate');

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /LITERAL MODE ACTIVE/);
  assert.strictEqual(fs.existsSync(path.join(tmpDir, '.literal-active')), false);
});

test('prompt "/literal" -> flag file exists afterward', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'literal-mode-test-'));

  const result = runTracker(tmpDir, '/literal');

  assert.strictEqual(result.status, 0);
  assert.strictEqual(fs.existsSync(path.join(tmpDir, '.literal-active')), true);
});

test('prompt "/literal off" with flag pre-created -> flag removed', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'literal-mode-test-'));
  fs.writeFileSync(path.join(tmpDir, '.literal-active'), '1');

  const result = runTracker(tmpDir, '/literal off');

  assert.strictEqual(result.status, 0);
  assert.strictEqual(fs.existsSync(path.join(tmpDir, '.literal-active')), false);
});

test('false-positive guard: flag absent, "fix the literal string in the parser" -> no suppression', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'literal-mode-test-'));

  const result = runTracker(tmpDir, 'fix the literal string in the parser');

  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stdout.trim(), '');
  assert.strictEqual(fs.existsSync(path.join(tmpDir, '.literal-active')), false);
});
