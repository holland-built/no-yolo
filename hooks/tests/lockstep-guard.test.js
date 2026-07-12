// Tests for hooks/lockstep-guard.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
// process.exit() means this hook must be driven as a child process, not require()'d.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'lockstep-guard.js');

function runGuard(tmpDir) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_CONFIG_DIR: tmpDir },
    encoding: 'utf8',
  });
}

test('flag file present -> exit 2, stderr warns LOCKSTEP ACTIVE', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'lockstep-guard-test-'));
  fs.writeFileSync(path.join(tmpDir, '.lockstep-active'), '');

  const result = runGuard(tmpDir);

  assert.strictEqual(result.status, 2);
  assert.match(result.stderr, /LOCKSTEP ACTIVE/);
});

test('flag file absent -> exit 0, empty stderr', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'lockstep-guard-test-'));

  const result = runGuard(tmpDir);

  assert.strictEqual(result.status, 0);
  assert.strictEqual(result.stderr, '');
});
