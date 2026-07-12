// Tests for hooks/caveman-config.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
// caveman-config exports plain functions (no process.exit), so it's tested
// via direct require() rather than as a child process.
const { test, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { getDefaultMode, VALID_MODES, safeWriteFlag } = require('../caveman-config');

const savedEnv = {};

beforeEach(() => {
  savedEnv.CAVEMAN_DEFAULT_MODE = process.env.CAVEMAN_DEFAULT_MODE;
  savedEnv.XDG_CONFIG_HOME = process.env.XDG_CONFIG_HOME;
  // Isolate from any host ~/.config/caveman/config.json — point at an empty
  // temp dir so getConfigPath() resolves to a nonexistent file.
  process.env.XDG_CONFIG_HOME = fs.mkdtempSync(path.join(os.tmpdir(), 'caveman-config-test-xdg-'));
});

afterEach(() => {
  if (savedEnv.CAVEMAN_DEFAULT_MODE === undefined) delete process.env.CAVEMAN_DEFAULT_MODE;
  else process.env.CAVEMAN_DEFAULT_MODE = savedEnv.CAVEMAN_DEFAULT_MODE;
  if (savedEnv.XDG_CONFIG_HOME === undefined) delete process.env.XDG_CONFIG_HOME;
  else process.env.XDG_CONFIG_HOME = savedEnv.XDG_CONFIG_HOME;
});

test('getDefaultMode() honors CAVEMAN_DEFAULT_MODE env var', () => {
  process.env.CAVEMAN_DEFAULT_MODE = 'ultra';
  assert.strictEqual(getDefaultMode(), 'ultra');
});

test('getDefaultMode() falls through to "full" on invalid env value with no config file', () => {
  process.env.CAVEMAN_DEFAULT_MODE = 'bogus';
  assert.strictEqual(getDefaultMode(), 'full');
});

test('getDefaultMode() falls through to "full" when env is unset and no config file', () => {
  delete process.env.CAVEMAN_DEFAULT_MODE;
  assert.strictEqual(getDefaultMode(), 'full');
});

test('VALID_MODES includes the documented mode set', () => {
  for (const mode of [
    'off', 'lite', 'full', 'ultra',
    'wenyan-lite', 'wenyan', 'wenyan-full', 'wenyan-ultra',
    'commit', 'review', 'compress',
  ]) {
    assert.ok(VALID_MODES.includes(mode), `missing mode: ${mode}`);
  }
});

test('safeWriteFlag refuses to write through an existing symlink', () => {
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'caveman-config-test-symlink-'));
  const realTarget = path.join(tmpDir, 'real-target');
  const flagPath = path.join(tmpDir, '.caveman-active');
  fs.writeFileSync(realTarget, 'untouched');
  fs.symlinkSync(realTarget, flagPath);

  safeWriteFlag(flagPath, 'ultra');

  assert.strictEqual(fs.readFileSync(realTarget, 'utf8'), 'untouched');
});
