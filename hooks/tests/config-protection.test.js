// Tests for hooks/config-protection.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
//
// Positive AND negative controls are mandatory here. A guard whose denylist
// silently stops matching passes every "nothing was blocked" assertion forever
// (see verify.sh §8a — the \b-on-macOS incident). The "existing config ->
// exit 2" cases below are the proof that the matcher can still fire.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'config-protection.js');

function tmp() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'config-protection-test-'));
}

function run(toolInput, { env = {}, raw } = {}) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_ALLOW_CONFIG_EDIT: '', ...env },
    input: raw !== undefined ? raw : JSON.stringify({ tool_name: 'Edit', tool_input: toolInput }),
    encoding: 'utf8',
  });
}

function existingFile(dir, name, body = '{}') {
  const p = path.join(dir, name);
  fs.writeFileSync(p, body);
  return p;
}

// ---------------------------------------------------------------- POSITIVE

test('existing .eslintrc.json -> exit 2 with a CONFIG PROTECTION message', () => {
  const d = tmp();
  const r = run({ file_path: existingFile(d, '.eslintrc.json') });
  assert.strictEqual(r.status, 2);
  assert.match(r.stderr, /CONFIG PROTECTION/);
});

test('block message names the file and both legitimate ways forward', () => {
  const d = tmp();
  const p = existingFile(d, 'biome.json');
  const r = run({ file_path: p });
  assert.strictEqual(r.status, 2);
  assert.match(r.stderr, new RegExp(p.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
  assert.match(r.stderr, /Fix the code/i);
  assert.match(r.stderr, /let them decide/i);
  assert.match(r.stderr, /CLAUDE_ALLOW_CONFIG_EDIT=1/);
});

// Every entry in the denylist must be provably matchable. If someone breaks the
// glob->regex translation, this test goes red instead of the guard going quiet.
const GUARDED_SAMPLES = [
  '.eslintrc',
  '.eslintrc.json',
  '.eslintrc.yml',
  'eslint.config.js',
  'eslint.config.mjs',
  'prettier.config.js',
  '.prettierrc',
  '.prettierrc.json',
  'biome.json',
  'biome.jsonc',
  '.ruff.toml',
  'ruff.toml',
  'tsconfig.json',
  'tsconfig.build.json',
  '.flake8',
];

// Deliberately NOT guarded — dual-purpose files that ordinary work edits.
// These assertions exist so the exclusion stays a decision, not an accident:
// if someone adds them back to GUARDED, these go red and force the argument.
const DELIBERATELY_UNGUARDED = ['setup.cfg', 'pyproject.toml', '.editorconfig'];

for (const name of GUARDED_SAMPLES) {
  test(`existing ${name} is guarded -> exit 2`, () => {
    const d = tmp();
    const r = run({ file_path: existingFile(d, name) });
    assert.strictEqual(r.status, 2, `${name} should be blocked but exited ${r.status}`);
  });
}

for (const name of DELIBERATELY_UNGUARDED) {
  test(`existing ${name} is deliberately NOT guarded -> exit 0`, () => {
    const d = tmp();
    const r = run({ file_path: existingFile(d, name) });
    assert.strictEqual(r.status, 0, `${name} is dual-purpose and must not block`);
  });
}

test('basename match is case-insensitive', () => {
  const d = tmp();
  const r = run({ file_path: existingFile(d, 'TSConfig.JSON') });
  assert.strictEqual(r.status, 2);
});

test('guarded config in a nested dir is still caught (basename, not path)', () => {
  const d = tmp();
  fs.mkdirSync(path.join(d, 'packages', 'app'), { recursive: true });
  const r = run({ file_path: existingFile(path.join(d, 'packages', 'app'), 'tsconfig.json') });
  assert.strictEqual(r.status, 2);
});

test('relative path is resolved against payload cwd, then blocked', () => {
  const d = tmp();
  existingFile(d, '.prettierrc');
  const r = spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_ALLOW_CONFIG_EDIT: '' },
    input: JSON.stringify({ tool_name: 'Edit', cwd: d, tool_input: { file_path: '.prettierrc' } }),
    encoding: 'utf8',
  });
  assert.strictEqual(r.status, 2);
});

// ---------------------------------------------------------------- NEGATIVE

test('brand-new config (file does not exist yet) -> exit 0, allowed', () => {
  const d = tmp();
  const r = run({ file_path: path.join(d, '.eslintrc.json') });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('ordinary source file -> exit 0', () => {
  const d = tmp();
  const r = run({ file_path: existingFile(d, 'index.ts', 'export {}') });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('lookalike names are NOT over-matched', () => {
  const d = tmp();
  for (const name of ['tsconfig.json.bak', 'my-biome.json', 'pyproject.toml.tmp', 'editorconfig']) {
    const r = run({ file_path: existingFile(d, name) });
    assert.strictEqual(r.status, 0, `${name} should NOT be blocked`);
  }
});

test('CLAUDE_ALLOW_CONFIG_EDIT=1 -> exit 0 silently, even on an existing config', () => {
  const d = tmp();
  const r = run({ file_path: existingFile(d, 'biome.json') }, { env: { CLAUDE_ALLOW_CONFIG_EDIT: '1' } });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('CLAUDE_ALLOW_CONFIG_EDIT=0 does NOT open the gate', () => {
  const d = tmp();
  const r = run({ file_path: existingFile(d, 'biome.json') }, { env: { CLAUDE_ALLOW_CONFIG_EDIT: '0' } });
  assert.strictEqual(r.status, 2);
});

// ------------------------------------------------------------- FAIL OPEN

test('empty stdin -> exit 0, no throw', () => {
  const r = run(null, { raw: '' });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('garbage stdin -> exit 0, no throw', () => {
  const r = run(null, { raw: '{ not json at all' });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('payload with no tool_input -> exit 0', () => {
  const r = run(null, { raw: JSON.stringify({ tool_name: 'Edit' }) });
  assert.strictEqual(r.status, 0);
});

test('payload whose file_path is the wrong type -> exit 0', () => {
  const r = run({ file_path: 42 });
  assert.strictEqual(r.status, 0);
});
