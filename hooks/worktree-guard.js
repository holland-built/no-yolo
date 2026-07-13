#!/usr/bin/env node
// worktree-guard — PreToolUse guard for Edit/Write/NotebookEdit.
//
// Purpose: once /worktree marks a worktree active for a repo, make it
// MECHANICALLY impossible to edit that repo's main checkout. Any edit whose
// target is inside the repo but NOT inside the active worktree is denied.
// This is the hard version of the /worktree skill's Gate A — a hook the model
// cannot talk itself past, the same posture as lockstep-guard.js.
//
// Flags live in $CLAUDE_CONFIG_DIR/.worktree-active/*.json, one per active
// worktree, written by the /worktree skill:
//   { "repoRoot": "/abs/repo", "wtPath": "/abs/repo/.worktrees/name",
//     "name": "name", "branch": "name" }
//
// Design choices:
// - No flags -> exit 0 immediately (zero cost when the feature is unused).
// - Edit target outside every flagged repo -> allowed (e.g. editing ~/.claude
//   while an <a-client-repo> worktree is active is fine — different repo).
// - Edit target inside a flagged repo but outside its worktree -> DENIED.
// - Flags present but the target path can't be determined -> DENIED (safe side:
//   if a worktree is active we would rather block an unclassifiable edit than
//   let a main-checkout leak through).

const fs = require('fs');
const path = require('path');
const os = require('os');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const flagDir = path.join(claudeDir, '.worktree-active');

function readFlags() {
  let entries;
  try {
    entries = fs.readdirSync(flagDir);
  } catch {
    return []; // dir missing = feature unused
  }
  const flags = [];
  for (const f of entries) {
    if (!f.endsWith('.json')) continue;
    try {
      const raw = fs.readFileSync(path.join(flagDir, f), 'utf8');
      const j = JSON.parse(raw);
      if (j && j.repoRoot && j.wtPath) {
        flags.push({
          repoRoot: path.resolve(j.repoRoot),
          wtPath: path.resolve(j.wtPath),
          name: j.name || f.replace(/\.json$/, ''),
        });
      }
    } catch {
      // A corrupt flag file is treated as a live guard, not ignored: fall
      // through with a sentinel so we fail safe rather than open.
      flags.push({ corrupt: true, file: f });
    }
  }
  return flags;
}

// true if `child` is `parent` or nested under it (path-segment aware, so
// /a/repo does NOT match /a/repo-2).
function isUnder(child, parent) {
  const rel = path.relative(parent, child);
  return rel === '' || (!rel.startsWith('..') && !path.isAbsolute(rel));
}

function targetPath(input) {
  if (!input || typeof input !== 'object') return null;
  return input.file_path || input.notebook_path || input.path || null;
}

function deny(msg) {
  process.stderr.write(msg);
  process.exit(2);
}

const flags = readFlags();
if (flags.length === 0) process.exit(0); // fast path: nothing active

// Read the PreToolUse payload from stdin.
let payload = {};
try {
  const raw = fs.readFileSync(0, 'utf8');
  if (raw.trim()) payload = JSON.parse(raw);
} catch {
  payload = {};
}

const corrupt = flags.find((f) => f.corrupt);
if (corrupt) {
  deny(
    `WORKTREE GUARD — a worktree flag file (${corrupt.file}) is unreadable, so edits are blocked to stay safe. ` +
      `Fix or remove ${path.join(flagDir, corrupt.file)} (or run /worktree off), then retry.`
  );
}

let target = targetPath(payload.tool_input || payload.toolInput);
if (!target) {
  // A worktree is active but we can't see the edit target — block rather than
  // risk a main-checkout leak.
  deny(
    'WORKTREE GUARD — a worktree is active but this edit has no readable target path, so it is blocked. ' +
      'Run /worktree off if you meant to work outside the worktree.'
  );
}

target = path.resolve(payload.cwd ? path.resolve(payload.cwd, target) : target);

for (const flag of flags) {
  if (flag.corrupt) continue;
  if (isUnder(target, flag.repoRoot) && !isUnder(target, flag.wtPath)) {
    deny(
      `WORKTREE GUARD — blocked edit to the MAIN checkout of "${flag.name}".\n` +
        `  target : ${target}\n` +
        `  worktree: ${flag.wtPath}\n` +
        `All work for this worktree must go under the worktree path above, not the main checkout. ` +
        `Re-issue the edit against the ${flag.wtPath} copy of this file. ` +
        `When the work is done, run "/worktree land" to merge it into the base branch and remove the worktree.`
    );
  }
}

process.exit(0);
