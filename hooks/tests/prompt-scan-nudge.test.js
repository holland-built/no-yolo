// Tests for hooks/prompt-scan-nudge.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
// Hook writes to stdout and always exits 0 — run as a child process to keep
// its filesystem reads (learningsPath) isolated from the real ~/.claude.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'prompt-scan-nudge.js');

function runNudge(tmpDir) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_CONFIG_DIR: tmpDir },
    encoding: 'utf8',
  });
}

test('dated entry found -> reports date and model', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'prompt-scan-nudge-test-'));
  fs.writeFileSync(
    path.join(tmpDir, 'learnings.md'),
    '### 2026-07-04 — claude-opus-4-8\n\nsome learning\n'
  );

  const result = runNudge(tmpDir);

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /last \/prompt-scan was 2026-07-04, model "claude-opus-4-8"/);
});

test('file present but unparseable -> reports no dated scan entry', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'prompt-scan-nudge-test-'));
  fs.writeFileSync(path.join(tmpDir, 'learnings.md'), 'just some notes, no dated header\n');

  const result = runNudge(tmpDir);

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /has no dated scan entry/);
});

test('file missing -> reports no learnings.md found', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'prompt-scan-nudge-test-'));

  const result = runNudge(tmpDir);

  assert.strictEqual(result.status, 0);
  assert.match(result.stdout, /no learnings\.md found/);
});
