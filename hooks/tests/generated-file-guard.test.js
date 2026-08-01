// Tests for hooks/generated-file-guard.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
const { test } = require('node:test');
const assert = require('node:assert');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'generated-file-guard.js');

function run(toolInput, env = {}, toolName = 'Edit') {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_ALLOW_GENERATED_EDIT: '', ...env },
    input: JSON.stringify({ tool_name: toolName, tool_input: toolInput }),
    encoding: 'utf8',
  });
}

// --- POSITIVE CONTROLS: prove the guard can still BLOCK. -------------------
// A suffix matcher that stops matching (a renamed file, a normalization bug)
// would let every generated edit through and this suite would stay green
// forever. These cases are what make a passing run mean anything.

test('POSITIVE CONTROL: absolute path to CLAUDE.generated.md -> exit 2', () => {
  const r = run({ file_path: '/tmp/fake-home/.claude/memory/CLAUDE.generated.md' });
  assert.strictEqual(r.status, 2);
  assert.match(r.stderr, /GENERATED FILE/);
  assert.match(r.stderr, /memory\/facts/);
  assert.match(r.stderr, /\/memory-compile/);
});

test('POSITIVE CONTROL: relative path to CLAUDE.generated.md -> exit 2', () => {
  const r = run({ file_path: 'memory/CLAUDE.generated.md' });
  assert.strictEqual(r.status, 2);
});

test('RENDERED.md -> exit 2 and names regen.py', () => {
  const r = run({ file_path: '/tmp/fake-home/.claude/skills/my-skills/RENDERED.md' });
  assert.strictEqual(r.status, 2);
  assert.match(r.stderr, /python3 skills\/my-skills\/regen\.py/);
});

test('RENDERED_FAST.md -> exit 2', () => {
  const r = run({ file_path: '/tmp/fake-home/.claude/skills/my-skills/RENDERED_FAST.md' });
  assert.strictEqual(r.status, 2);
});

test('docs/FLAGS.md (third regen.py target) -> exit 2', () => {
  const r = run({ file_path: '/tmp/fake-home/.claude/docs/FLAGS.md' });
  assert.strictEqual(r.status, 2);
});

test('MultiEdit against a generated file is blocked too', () => {
  const r = run({ file_path: '/tmp/fake-home/.claude/skills/my-skills/RENDERED.md' }, {}, 'MultiEdit');
  assert.strictEqual(r.status, 2);
});

// --- NEGATIVE CONTROLS: prove it does not block ordinary work. -------------

test('a normal source file -> exit 0, silent', () => {
  const r = run({ file_path: '/tmp/fake-home/.claude/skills/build/SKILL.md' });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('a source FACT file (the thing you are told to edit) -> exit 0', () => {
  const r = run({ file_path: '/tmp/fake-home/.claude/memory/facts/user-opus-for-all-coding.md' });
  assert.strictEqual(r.status, 0);
});

test('similarly-named but different file -> exit 0', () => {
  const r = run({ file_path: '/tmp/fake-home/.claude/memory/CLAUDE.generated.md.bak' });
  assert.strictEqual(r.status, 0);
});

test('partial suffix without the dir boundary -> exit 0', () => {
  // "my-RENDERED.md" must NOT match "skills/my-skills/RENDERED.md"
  const r = run({ file_path: '/tmp/fake-home/notskills/my-RENDERED.md' });
  assert.strictEqual(r.status, 0);
});

test('escape hatch CLAUDE_ALLOW_GENERATED_EDIT=1 -> exit 0, silent', () => {
  const r = run({ file_path: 'memory/CLAUDE.generated.md' }, { CLAUDE_ALLOW_GENERATED_EDIT: '1' });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

// --- ROBUSTNESS: never crash a session. ------------------------------------

test('empty stdin -> exit 0', () => {
  const r = spawnSync(process.execPath, [hookPath], { input: '', encoding: 'utf8' });
  assert.strictEqual(r.status, 0);
});

test('garbage stdin -> exit 0', () => {
  const r = spawnSync(process.execPath, [hookPath], { input: '{ not json at all', encoding: 'utf8' });
  assert.strictEqual(r.status, 0);
});

test('payload with no tool_input -> exit 0', () => {
  const r = spawnSync(process.execPath, [hookPath], {
    input: JSON.stringify({ tool_name: 'Edit' }),
    encoding: 'utf8',
  });
  assert.strictEqual(r.status, 0);
});
