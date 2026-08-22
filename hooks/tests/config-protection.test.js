// Contract for hooks/config-protection.js, run as a black box.
//   node --test 'hooks/tests/*.test.js'
//
// Rewritten from a blank page 2026-08-22 (machinery rebuild), AFTER the hook and
// judged against it.
//
// POSITIVE CONTROLS ARE NOT OPTIONAL HERE. This guard passes by staying quiet, so
// a denylist that silently stopped matching would satisfy every "nothing was
// blocked" assertion forever. That exact shape went unnoticed once already, in a
// leak scan whose rules were dead on one platform. Every guarded name below is
// therefore proved to still block, and every deliberately-unguarded one is proved
// to still pass.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const HOOK = path.join(__dirname, '..', 'config-protection.js');

const dir = () => fs.mkdtempSync(path.join(os.tmpdir(), 'config-protection-'));

function existing(where, name, body = '{}') {
  const p = path.join(where, name);
  fs.writeFileSync(p, body);
  return p;
}

function run(toolInput, { env = {}, raw, cwd } = {}) {
  const payload = { tool_name: 'Edit', tool_input: toolInput };
  if (cwd) payload.cwd = cwd;
  return spawnSync(process.execPath, [HOOK], {
    // Cleared explicitly: inheriting a real one from the developer's shell would
    // open the gate and turn every blocking assertion below green for the wrong
    // reason.
    env: { ...process.env, CLAUDE_ALLOW_CONFIG_EDIT: '', ...env },
    input: raw !== undefined ? raw : JSON.stringify(payload),
    encoding: 'utf8',
  });
}

// -------------------------------------------------- an existing config blocks

// One per denylist entry, so a broken glob-to-regex translation reddens this
// suite instead of quietly disarming the guard.
const GUARDED = [
  '.eslintrc', '.eslintrc.json', '.eslintrc.yml',
  'eslint.config.js', 'eslint.config.mjs',
  'prettier.config.js', '.prettierrc', '.prettierrc.json',
  'biome.json', 'biome.jsonc',
  '.ruff.toml', 'ruff.toml',
  'tsconfig.json', 'tsconfig.build.json',
  '.flake8',
];

for (const name of GUARDED) {
  test(`an existing ${name} is refused`, () => {
    const r = run({ file_path: existing(dir(), name) });
    assert.strictEqual(r.status, 2, `${name} should block, exited ${r.status}`);
  });
}

test('the refusal names the file and both ways forward', () => {
  const p = existing(dir(), 'biome.json');
  const r = run({ file_path: p });
  assert.strictEqual(r.status, 2);
  assert.match(r.stderr, /CONFIG PROTECTION/);
  assert.match(r.stderr, new RegExp(p.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
  assert.match(r.stderr, /Fix the code/i);
  assert.match(r.stderr, /let them decide/i);
  assert.match(r.stderr, /CLAUDE_ALLOW_CONFIG_EDIT=1/);
});

test('matching is on the basename, so a nested config is caught too', () => {
  const root = dir();
  const nested = path.join(root, 'packages', 'app');
  fs.mkdirSync(nested, { recursive: true });
  assert.strictEqual(run({ file_path: existing(nested, 'tsconfig.json') }).status, 2);
});

test('matching is case-insensitive', () => {
  assert.strictEqual(run({ file_path: existing(dir(), 'TSConfig.JSON') }).status, 2);
});

test('a relative path is resolved against the payload cwd', () => {
  const root = dir();
  existing(root, '.prettierrc');
  assert.strictEqual(run({ file_path: '.prettierrc' }, { cwd: root }).status, 2);
});

test('notebook_path and path are read as targets too', () => {
  for (const key of ['notebook_path', 'path']) {
    const r = run({ [key]: existing(dir(), 'biome.json') });
    assert.strictEqual(r.status, 2, `${key} should be seen`);
  }
});

// ------------------------------------------------------- what must NOT block

test('creating a config that does not exist yet is allowed', () => {
  const r = run({ file_path: path.join(dir(), '.eslintrc.json') });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('an ordinary source file is allowed', () => {
  const r = run({ file_path: existing(dir(), 'index.ts', 'export {}') });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

// Dual-purpose files that ordinary work edits constantly. A guard that fires on
// these gets its escape hatch exported permanently, which is worse than no guard.
// Asserted so that adding one back to the denylist forces the argument.
for (const name of ['pyproject.toml', 'setup.cfg', '.editorconfig']) {
  test(`${name} is deliberately NOT guarded`, () => {
    assert.strictEqual(run({ file_path: existing(dir(), name) }).status, 0);
  });
}

test('lookalike names are not over-matched', () => {
  const where = dir();
  for (const name of ['tsconfig.json.bak', 'my-biome.json', 'pyproject.toml.tmp', 'editorconfig']) {
    assert.strictEqual(run({ file_path: existing(where, name) }).status, 0, `${name} must pass`);
  }
});

// ------------------------------------------------------------- escape hatch

test('CLAUDE_ALLOW_CONFIG_EDIT=1 opens the gate silently', () => {
  const r = run({ file_path: existing(dir(), 'biome.json') }, { env: { CLAUDE_ALLOW_CONFIG_EDIT: '1' } });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

// Only the exact string opens it. A truthy-ish value must not, or "0" would read
// as permission and the hatch would be far wider than it is documented to be.
for (const value of ['0', 'true', 'yes', '']) {
  test(`CLAUDE_ALLOW_CONFIG_EDIT=${JSON.stringify(value)} does NOT open the gate`, () => {
    const r = run({ file_path: existing(dir(), 'biome.json') }, { env: { CLAUDE_ALLOW_CONFIG_EDIT: value } });
    assert.strictEqual(r.status, 2);
  });
}

// ---------------------------------------------------------------- fail open

for (const [name, raw] of [
  ['empty stdin', ''],
  ['garbage stdin', '{ not json at all'],
  ['no tool_input', JSON.stringify({ tool_name: 'Edit' })],
  ['tool_input of the wrong type', JSON.stringify({ tool_input: 'a string' })],
]) {
  test(`${name} -> exit 0, silent`, () => {
    const r = run(null, { raw });
    assert.strictEqual(r.status, 0);
    assert.strictEqual(r.stderr, '');
  });
}

test('a file_path of the wrong type -> exit 0', () => {
  assert.strictEqual(run({ file_path: 42 }).status, 0);
});

test('an empty file_path -> exit 0', () => {
  assert.strictEqual(run({ file_path: '   ' }).status, 0);
});
