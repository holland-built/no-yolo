---
name: worktree
description: Use this skill when the user types /worktree, says "start a worktree", "work in a worktree", "do this in a worktree", "spin up a worktree", or "branch this off in a worktree". Creates a git worktree AND guarantees all work — every edit, every subagent, the commit, the push — lands inside it, never the main checkout. Proves it with show-toplevel before the first edit and a branch+diff gate at the end.
user-invocable: true
argument-hint: "[worktree-name] (omit and I'll name it from the task)"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Agent
---

# worktree

The failure this prevents: a worktree gets created, but the work happens in the **main checkout** anyway. Two ways that goes wrong:

1. **Subagent cwd is pinned at launch.** If a build/edit subagent is handed an absolute path into the main repo, it edits the main repo — worktree untouched.
2. **Edits by old absolute path.** Referencing `<home>/proj/index.html` (the main checkout) instead of the worktree path writes to main even though the session "moved."

A written reminder is not enough — that's exactly what gets ignored mid-conversation. This skill makes it a **checked protocol**: no edit happens until the worktree root is echoed and confirmed, and nothing is called done until a diff proves the work is on the worktree branch.

Requested worktree name: $ARGUMENTS

## Protocol — run in order, do not skip a gate

### 1. Create the worktree
Pick a branch/worktree name (from `$ARGUMENTS`, else derive a short kebab-case name from the task). Then:

```bash
REPO=$(git rev-parse --show-toplevel)
NAME="<chosen-name>"
WT="$REPO/.worktrees/$NAME"     # or the repo's existing worktree dir convention
git worktree add -b "$NAME" "$WT" 2>/dev/null || git worktree add "$WT" "$NAME"
cd "$WT" && git rev-parse --show-toplevel
```

Prefer the `EnterWorktree` tool if available — it moves the session cwd for you. Either way, the next step is mandatory.

### 2. GATE A — prove the root before ANY edit
Before the first `Edit`/`Write`, run and show the user:

```bash
git rev-parse --show-toplevel
```

The output **must contain `/.worktrees/`** (or your chosen worktree dir). If it still points at the main checkout, STOP — cd into the worktree and re-check. Do not edit until this passes. Store the absolute worktree path; call it `WT`.

### 3. Do the work inside `WT`
- Every file path you edit is under `$WT/...`. Never an absolute path into the main checkout.
- **Every subagent you dispatch** gets told explicitly: "Your working directory is `$WT`. All reads and edits happen under that path. Do not touch the main checkout at `$REPO`." Pass `$WT` in the prompt — a subagent cannot inherit the session cwd move.
- Commits and pushes run from `$WT` (or `git -C "$WT" ...`).

### 4. GATE B — prove the work landed on the branch
Before declaring done, run and show:

```bash
git -C "$WT" branch --show-current
git -C "$WT" diff --stat HEAD    # staged+unstaged; use log --stat if already committed
git -C "$REPO" status --short    # main checkout should be CLEAN of this work
```

The diff must be on the worktree branch, and the main checkout must show none of these changes. If the changes show up in `$REPO` instead — the protocol failed; report it, don't paper over it.

## Notes
- This is procedural, not hook-enforced — the teeth are Gate A and Gate B, which are visible commands the user can see pass or fail. If you want a *mechanical* block (a hook that denies any Edit whose target isn't under an active worktree, same style as `lockstep`), that's a separate follow-up worth building.
- `.worktrees/` is the assumed dir; honor whatever convention the repo already uses (`git worktree list` shows existing ones).
- Cleanup when merged: `git worktree remove "$WT"` then `git branch -d "$NAME"`.
