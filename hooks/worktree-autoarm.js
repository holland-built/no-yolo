#!/usr/bin/env node
// worktree-autoarm — SessionStart hook.
//
// Makes the worktree guard fire for worktrees created ANY way (Orca's sidebar,
// `git worktree add` by hand, or the /worktree skill) — not just ones the skill
// armed. Logic: when a session starts, if its cwd is inside a LINKED git
// worktree (not the repo's main checkout), write a guard flag for it. Then
// worktree-guard.js blocks edits to that repo's main checkout with zero words
// from the user.
//
// Also self-heals: prunes any flag whose worktree directory no longer exists
// (e.g. after `/release` removed it), so a stale flag can't keep blocking.
//
// Never arms when cwd is the main checkout — that would lock the whole repo.
// Fail-open: git missing / not a repo / any error -> do nothing (this is a
// convenience layer; the /worktree skill's explicit arming still works).

const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const { execFileSync } = require('child_process');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const flagDir = path.join(claudeDir, '.worktree-active');

function git(cwd, args) {
  return execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
}

// 1. Prune flags whose worktree no longer exists on disk.
function prune() {
  let files;
  try { files = fs.readdirSync(flagDir); } catch { return; }
  for (const f of files) {
    if (!f.endsWith('.json')) continue;
    const p = path.join(flagDir, f);
    try {
      const j = JSON.parse(fs.readFileSync(p, 'utf8'));
      if (j.wtPath && !fs.existsSync(j.wtPath)) fs.rmSync(p);
    } catch {
      // leave unparseable flags for worktree-guard.js to fail-safe on
    }
  }
}

function readCwd() {
  try {
    const raw = fs.readFileSync(0, 'utf8');
    if (raw.trim()) {
      const j = JSON.parse(raw);
      if (j && j.cwd) return j.cwd;
    }
  } catch { /* ignore */ }
  return process.cwd();
}

function main() {
  prune();

  const cwd = readCwd();
  let top;
  try {
    if (git(cwd, ['rev-parse', '--is-inside-work-tree']) !== 'true') return;
    top = git(cwd, ['rev-parse', '--show-toplevel']);
  } catch { return; } // not a git repo / no git

  // Parse `git worktree list --porcelain`: first block = main checkout.
  let mainPath, mainBranch = 'main';
  try {
    const porcelain = git(cwd, ['worktree', 'list', '--porcelain']);
    const blocks = porcelain.split('\n\n');
    const first = blocks[0].split('\n');
    for (const line of first) {
      if (line.startsWith('worktree ')) mainPath = line.slice('worktree '.length);
      if (line.startsWith('branch ')) mainBranch = line.slice('branch '.length).replace('refs/heads/', '');
    }
  } catch { return; }

  if (!mainPath) return;
  // In the main checkout -> do NOT arm (would lock the whole repo).
  if (path.resolve(top) === path.resolve(mainPath)) return;

  // We're in a linked worktree. Skip if a flag for this wtPath already exists.
  try {
    for (const f of fs.readdirSync(flagDir)) {
      if (!f.endsWith('.json')) continue;
      try {
        const j = JSON.parse(fs.readFileSync(path.join(flagDir, f), 'utf8'));
        if (j.wtPath && path.resolve(j.wtPath) === path.resolve(top)) return; // already armed
      } catch { /* ignore */ }
    }
  } catch { /* flagDir missing, fine */ }

  let branch;
  try { branch = git(cwd, ['symbolic-ref', '--short', 'HEAD']); }
  catch { branch = path.basename(top); } // detached HEAD

  const name = branch || path.basename(top);
  const hash = crypto.createHash('sha1').update(path.resolve(top)).digest('hex').slice(0, 8);

  fs.mkdirSync(flagDir, { recursive: true });
  fs.writeFileSync(
    path.join(flagDir, `${name}-${hash}.json`),
    JSON.stringify({ repoRoot: mainPath, wtPath: top, name, branch: name, base: mainBranch }, null, 0) + '\n'
  );
  // Surface it to the session (SessionStart stdout is shown as context).
  process.stdout.write(
    `worktree-guard armed automatically: this session is in worktree "${name}"; ` +
    `edits to the main checkout (${mainPath}) are blocked. Say "release" when done.`
  );
}

try { main(); } catch { /* never break session start */ }
process.exit(0);
