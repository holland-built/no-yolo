// Tests for hooks/relock-guard.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
//
// Each test builds a throwaway git repo shaped like ~/.claude and points the hook
// at it with CLAUDE_CONFIG_DIR.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync, execFileSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'relock-guard.js');
const RELOCK = 'python3 skills/my-skills/catalog_lock.py --relock';
const CHECK = 'python3 skills/my-skills/catalog_lock.py --check';

function git(cwd, args) {
  execFileSync('git', args, { cwd, stdio: 'ignore' });
}

// repo with one COMMITTED skill, so "clean" is a real state, not an empty repo.
function makeRepo() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'relock-guard-'));
  git(dir, ['init', '-q']);
  git(dir, ['config', 'user.email', 't@t.t']);
  git(dir, ['config', 'user.name', 't']);
  addSkill(dir, 'existing');
  git(dir, ['add', '-A']);
  git(dir, ['commit', '-qm', 'init']);
  return dir;
}

function addSkill(dir, name, body = '---\nname: x\n---\nbody\n') {
  const d = path.join(dir, 'skills', name);
  fs.mkdirSync(d, { recursive: true });
  fs.writeFileSync(path.join(d, 'SKILL.md'), body);
}

function run(cfg, command) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_CONFIG_DIR: cfg, CLAUDE_ALLOW_RELOCK: '' },
    input: JSON.stringify({ tool_name: 'Bash', tool_input: { command } }),
    encoding: 'utf8',
  });
}

// --- POSITIVE CONTROLS: prove the guard can still BLOCK. -------------------
// This guard's whole job is to notice one specific invisible state. If the
// porcelain parsing or the `-uall` flag regresses, it reports "clean" forever and
// the negative tests below still pass — which is how the original bug shipped.

test('POSITIVE CONTROL: untracked SKILL.md + --relock -> exit 2, names the path', () => {
  const cfg = makeRepo();
  addSkill(cfg, 'brand-new'); // never git added
  const r = run(cfg, RELOCK);
  assert.strictEqual(r.status, 2);
  assert.match(r.stderr, /RELOCK BLOCKED/);
  assert.match(r.stderr, /skills\/brand-new\/SKILL\.md/);
  assert.match(r.stderr, /git add/);
});

test('POSITIVE CONTROL: -uall is required — a wholly untracked skill DIR is still caught', () => {
  // `git status --porcelain` without -uall collapses this to `?? skills/brand-new/`
  // and the SKILL.md never appears. That collapse is the exact blind spot.
  const cfg = makeRepo();
  addSkill(cfg, 'brand-new');
  const plain = execFileSync('git', ['-C', cfg, 'status', '--porcelain'], { encoding: 'utf8' });
  assert.ok(!plain.includes('SKILL.md'), 'precondition: plain porcelain hides the file');
  assert.strictEqual(run(cfg, RELOCK).status, 2);
});

test('several untracked SKILL.md files are all listed', () => {
  const cfg = makeRepo();
  addSkill(cfg, 'new-a');
  addSkill(cfg, 'new-b');
  const r = run(cfg, RELOCK);
  assert.strictEqual(r.status, 2);
  assert.match(r.stderr, /new-a/);
  assert.match(r.stderr, /new-b/);
});

test('relock via a different invocation string still blocks', () => {
  const cfg = makeRepo();
  addSkill(cfg, 'brand-new');
  const r = run(cfg, `cd ~/.claude && python3 ./skills/my-skills/catalog_lock.py --relock && echo ok`);
  assert.strictEqual(r.status, 2);
});

// --- NEGATIVE CONTROLS ------------------------------------------------------

test('--check is NEVER blocked, even with an untracked SKILL.md', () => {
  const cfg = makeRepo();
  addSkill(cfg, 'brand-new');
  const r = run(cfg, CHECK);
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('bare catalog_lock.py (no flag = --check) is not blocked', () => {
  const cfg = makeRepo();
  addSkill(cfg, 'brand-new');
  assert.strictEqual(run(cfg, 'python3 skills/my-skills/catalog_lock.py').status, 0);
});

test('MODIFIED-but-tracked SKILL.md does NOT block a relock', () => {
  const cfg = makeRepo();
  fs.writeFileSync(path.join(cfg, 'skills', 'existing', 'SKILL.md'), '---\nname: x\n---\nEDITED\n');
  const r = run(cfg, RELOCK);
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('untracked file that is NOT a SKILL.md does not block', () => {
  const cfg = makeRepo();
  fs.writeFileSync(path.join(cfg, 'skills', 'existing', 'NOTES.md'), 'x');
  fs.writeFileSync(path.join(cfg, 'scratch.md'), 'x');
  assert.strictEqual(run(cfg, RELOCK).status, 0);
});

test('clean tree + --relock -> exit 0', () => {
  const cfg = makeRepo();
  assert.strictEqual(run(cfg, RELOCK).status, 0);
});

test('unrelated bash command -> exit 0 (no git call needed)', () => {
  const cfg = makeRepo();
  addSkill(cfg, 'brand-new');
  assert.strictEqual(run(cfg, 'ls -la && git status').status, 0);
});

test('--relock without catalog_lock.py -> exit 0', () => {
  const cfg = makeRepo();
  addSkill(cfg, 'brand-new');
  assert.strictEqual(run(cfg, 'some-other-tool --relock').status, 0);
});

test('escape hatch CLAUDE_ALLOW_RELOCK=1 -> exit 0', () => {
  const cfg = makeRepo();
  addSkill(cfg, 'brand-new');
  const r = spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_CONFIG_DIR: cfg, CLAUDE_ALLOW_RELOCK: '1' },
    input: JSON.stringify({ tool_name: 'Bash', tool_input: { command: RELOCK } }),
    encoding: 'utf8',
  });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

// --- FAIL OPEN --------------------------------------------------------------

test('not a git repo -> exit 0 (fail open, silent)', () => {
  const cfg = fs.mkdtempSync(path.join(os.tmpdir(), 'relock-guard-nogit-'));
  addSkill(cfg, 'brand-new');
  const r = run(cfg, RELOCK);
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stderr, '');
});

test('config dir does not exist -> exit 0', () => {
  const r = run(path.join(os.tmpdir(), 'relock-guard-missing-' + Date.now()), RELOCK);
  assert.strictEqual(r.status, 0);
});

test('empty stdin -> exit 0', () => {
  const r = spawnSync(process.execPath, [hookPath], { input: '', encoding: 'utf8' });
  assert.strictEqual(r.status, 0);
});

test('garbage stdin -> exit 0', () => {
  const r = spawnSync(process.execPath, [hookPath], { input: 'not json {{{', encoding: 'utf8' });
  assert.strictEqual(r.status, 0);
});
