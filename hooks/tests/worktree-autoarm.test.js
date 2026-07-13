// Tests for hooks/worktree-autoarm.js — node:test, no npm deps. Needs `git`.
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync, execFileSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'worktree-autoarm.js');

function g(cwd, args) {
  execFileSync('git', args, { cwd, stdio: 'ignore' });
}

function makeRepoWithWorktree() {
  const cfg = fs.mkdtempSync(path.join(os.tmpdir(), 'aa-cfg-'));
  const repo = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'aa-repo-')));
  g(repo, ['init', '-q']);
  g(repo, ['config', 'user.email', 't@t']);
  g(repo, ['config', 'user.name', 't']);
  fs.writeFileSync(path.join(repo, 'f.txt'), 'base\n');
  g(repo, ['add', '-A']);
  g(repo, ['commit', '-qm', 'init']);
  const wt = path.join(repo, '.worktrees', 'feature');
  g(repo, ['worktree', 'add', '-q', '-b', 'feature', wt]);
  return { cfg, repo, wt };
}

function run(cfg, cwd) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_CONFIG_DIR: cfg },
    input: JSON.stringify({ cwd, hook_event_name: 'SessionStart' }),
    encoding: 'utf8',
  });
}

function flags(cfg) {
  try { return fs.readdirSync(path.join(cfg, '.worktree-active')).filter((f) => f.endsWith('.json')); }
  catch { return []; }
}

test('cwd in a linked worktree -> arms a flag with repoRoot=main, wtPath=worktree', () => {
  const { cfg, repo, wt } = makeRepoWithWorktree();
  const r = run(cfg, wt);
  assert.strictEqual(r.status, 0);
  const fl = flags(cfg);
  assert.strictEqual(fl.length, 1);
  const j = JSON.parse(fs.readFileSync(path.join(cfg, '.worktree-active', fl[0]), 'utf8'));
  assert.strictEqual(path.resolve(j.repoRoot), path.resolve(repo));
  assert.strictEqual(path.resolve(j.wtPath), path.resolve(wt));
  assert.strictEqual(j.branch, 'feature');
});

test('cwd in the MAIN checkout -> does NOT arm (would lock the whole repo)', () => {
  const { cfg, repo } = makeRepoWithWorktree();
  const r = run(cfg, repo);
  assert.strictEqual(r.status, 0);
  assert.strictEqual(flags(cfg).length, 0);
});

test('running twice in the same worktree -> still exactly one flag (idempotent)', () => {
  const { cfg, wt } = makeRepoWithWorktree();
  run(cfg, wt);
  run(cfg, wt);
  assert.strictEqual(flags(cfg).length, 1);
});

test('stale flag (worktree dir gone) is pruned on next run', () => {
  const { cfg, wt, repo } = makeRepoWithWorktree();
  run(cfg, wt);
  assert.strictEqual(flags(cfg).length, 1);
  // remove the worktree, then start a session in the main checkout
  execFileSync('git', ['worktree', 'remove', wt, '--force'], { cwd: repo, stdio: 'ignore' });
  run(cfg, repo);
  assert.strictEqual(flags(cfg).length, 0);
});

test('cwd not in a git repo -> no flag, exit 0', () => {
  const cfg = fs.mkdtempSync(path.join(os.tmpdir(), 'aa-cfg-'));
  const plain = fs.mkdtempSync(path.join(os.tmpdir(), 'aa-plain-'));
  const r = run(cfg, plain);
  assert.strictEqual(r.status, 0);
  assert.strictEqual(flags(cfg).length, 0);
});
