// Tests for hooks/worktree-guard.js — node:test, no npm deps.
// Run (from ~/.claude): node --test 'hooks/tests/*.test.js'
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('node:child_process');

const hookPath = path.join(__dirname, '..', 'worktree-guard.js');

function setup() {
  const cfg = fs.mkdtempSync(path.join(os.tmpdir(), 'wt-guard-cfg-'));
  const repo = fs.mkdtempSync(path.join(os.tmpdir(), 'wt-guard-repo-'));
  const wt = path.join(repo, '.worktrees', 'feature');
  fs.mkdirSync(wt, { recursive: true });
  return { cfg, repo, wt };
}

function writeFlag(cfg, repo, wt, name = 'feature') {
  const dir = path.join(cfg, '.worktree-active');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(
    path.join(dir, `${name}.json`),
    JSON.stringify({ repoRoot: repo, wtPath: wt, name, branch: name })
  );
}

function run(cfg, toolInput) {
  return spawnSync(process.execPath, [hookPath], {
    env: { ...process.env, CLAUDE_CONFIG_DIR: cfg },
    input: JSON.stringify({ tool_name: 'Edit', tool_input: toolInput }),
    encoding: 'utf8',
  });
}

test('no flags -> exit 0', () => {
  const { cfg, repo } = setup();
  const r = run(cfg, { file_path: path.join(repo, 'src', 'a.js') });
  assert.strictEqual(r.status, 0);
});

test('flag active + edit to MAIN checkout -> exit 2', () => {
  const { cfg, repo, wt } = setup();
  writeFlag(cfg, repo, wt);
  const r = run(cfg, { file_path: path.join(repo, 'src', 'a.js') });
  assert.strictEqual(r.status, 2);
  assert.match(r.stderr, /WORKTREE GUARD/);
});

test('flag active + edit UNDER worktree -> exit 0', () => {
  const { cfg, repo, wt } = setup();
  writeFlag(cfg, repo, wt);
  const r = run(cfg, { file_path: path.join(wt, 'src', 'a.js') });
  assert.strictEqual(r.status, 0);
});

test('flag active + edit in an UNRELATED repo -> exit 0', () => {
  const { cfg, repo, wt } = setup();
  writeFlag(cfg, repo, wt);
  const other = fs.mkdtempSync(path.join(os.tmpdir(), 'wt-guard-other-'));
  const r = run(cfg, { file_path: path.join(other, 'x.js') });
  assert.strictEqual(r.status, 0);
});

test('sibling dir with shared prefix is NOT treated as inside the repo', () => {
  const { cfg, repo, wt } = setup();
  writeFlag(cfg, repo, wt);
  const r = run(cfg, { file_path: `${repo}-sibling/x.js` });
  assert.strictEqual(r.status, 0);
});

test('flag active + NotebookEdit to main checkout -> exit 2', () => {
  const { cfg, repo, wt } = setup();
  writeFlag(cfg, repo, wt);
  const r = run(cfg, { notebook_path: path.join(repo, 'nb.ipynb') });
  assert.strictEqual(r.status, 2);
});

test('flag active + edit with no target path -> exit 2 (fail safe)', () => {
  const { cfg, repo, wt } = setup();
  writeFlag(cfg, repo, wt);
  const r = run(cfg, { some_other_field: 'x' });
  assert.strictEqual(r.status, 2);
});

test('corrupt flag file -> exit 2 (fail safe)', () => {
  const { cfg, repo, wt } = setup();
  const dir = path.join(cfg, '.worktree-active');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'bad.json'), '{ not valid json');
  const r = run(cfg, { file_path: path.join(wt, 'a.js') });
  assert.strictEqual(r.status, 2);
});
