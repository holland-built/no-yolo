// Tests for hooks/caveman-activate.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
// process.exit() means this hook must be driven as a child process, not require()'d.
//
// Note: the temp CLAUDE_CONFIG_DIR has no settings.json, so every non-"off"
// run also appends a "STATUSLINE SETUP NEEDED" nudge — assert with
// .includes()/regex against the stable prefix, not exact stdout equality.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'caveman-activate.js');

function runActivate(tmpDir, mode) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_CONFIG_DIR: tmpDir, CAVEMAN_DEFAULT_MODE: mode },
    encoding: 'utf8',
  });
}

test('off mode -> stdout OK, exit 0, no flag file left', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'caveman-activate-test-'));
  const flagPath = path.join(tmpDir, '.caveman-active');
  fs.writeFileSync(flagPath, 'ultra'); // pre-existing flag must be removed

  const result = runActivate(tmpDir, 'off');

  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stdout, 'OK');
  assert.strictEqual(fs.existsSync(flagPath), false);
});

test('full mode (standalone fallback) -> stdout contains active-level banner', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'caveman-activate-test-'));

  const result = runActivate(tmpDir, 'full');

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /CAVEMAN MODE ACTIVE — level: full/);
});

test('independent mode "commit" -> stdout defers to /caveman-commit skill', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'caveman-activate-test-'));

  const result = runActivate(tmpDir, 'commit');

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /Behavior defined by \/caveman-commit skill/);
});
