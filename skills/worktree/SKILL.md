---
name: worktree
description: Use this skill when the user types /worktree, says "start a worktree", "work in a worktree", "do this in a worktree", "spin up a worktree", or "branch this off in a worktree". Creates a git worktree AND arms a hard PreToolUse hook (worktree-guard.js) that mechanically blocks any edit to the repo's main checkout until you land or cancel. `/worktree land` merges the branch into base, pushes, and removes the worktree; `/worktree off` cancels without merging.
user-invocable: true
argument-hint: "[name] | land | off (omit name and I'll derive one from the task)"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Agent
---

# worktree

The failure this prevents: a worktree gets created, but the work happens in the **main checkout** anyway (a subagent's cwd is pinned at launch, or an edit uses the old absolute path). A written reminder gets ignored — so this skill arms a **hard hook**: while a worktree is active, `hooks/worktree-guard.js` denies any `Edit`/`Write`/`NotebookEdit` whose target is inside the repo but outside the worktree. Not a prompt the model can talk past — a real deny, like `/lockstep`.

Mode from `$ARGUMENTS`: a name (or empty) → **create**; `land` → **merge + remove**; `off`/`cancel` → **cancel**.

Flags live in `$CLAUDE_CONFIG_DIR/.worktree-active/<name>.json` (falls back to `~/.claude`). One per active worktree; the hook reads them.

---

## CREATE  (`/worktree`, `/worktree <name>`, or a trigger phrase)

### 1. Make the worktree
```bash
REPO=$(git rev-parse --show-toplevel) || { echo "not in a git repo"; exit 1; }
NAME="<from $ARGUMENTS, else a short kebab-case name from the task>"
BASE=$(git -C "$REPO" symbolic-ref --short HEAD)   # branch you're forking from
WT="$REPO/.worktrees/$NAME"
git -C "$REPO" worktree add -b "$NAME" "$WT" 2>/dev/null || git -C "$REPO" worktree add "$WT" "$NAME"
```

### 2. Arm the guard (write the flag)
```bash
FLAGDIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.worktree-active"
mkdir -p "$FLAGDIR"
cat > "$FLAGDIR/$NAME.json" <<EOF
{ "repoRoot": "$REPO", "wtPath": "$WT", "name": "$NAME", "branch": "$NAME", "base": "$BASE" }
EOF
echo "guard armed: edits to $REPO outside $WT are now BLOCKED"
git -C "$WT" rev-parse --show-toplevel   # must print the worktree path
```

Tell the user: worktree `<name>` created at `$WT`; the guard is armed. From here **every edit path is under `$WT`**. Any subagent you dispatch is told explicitly: *"Your working directory is `$WT`; all reads and edits are under that path — the main checkout is hook-blocked."* Then do the work.

> If you ever see `WORKTREE GUARD — blocked edit to the MAIN checkout`, you targeted the wrong path — re-issue the same edit under `$WT`. Do not try to disable the hook to get past it.

---

## LAND  (`/worktree land`, "land it", "release this worktree")

Merge the worktree branch into its base, push, remove the worktree, disarm the guard. Repo-agnostic — does not need a SHIP.md.

```bash
FLAGDIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.worktree-active"
# pick the flag for the current repo (or the only one active)
REPO=$(git rev-parse --show-toplevel 2>/dev/null)
FLAG=$(grep -l "\"repoRoot\": \"$REPO\"" "$FLAGDIR"/*.json 2>/dev/null | head -1)
[ -z "$FLAG" ] && FLAG=$(ls "$FLAGDIR"/*.json 2>/dev/null | head -1)
[ -z "$FLAG" ] && { echo "no active worktree to land"; exit 1; }

read WT BR BASE REPO < <(python3 - "$FLAG" <<'PY'
import json,sys
f=json.load(open(sys.argv[1]))
print(f["wtPath"], f["branch"], f.get("base","main"), f["repoRoot"])
PY
)

# 1. commit anything still pending in the worktree
git -C "$WT" add -A
git -C "$WT" diff --cached --quiet || git -C "$WT" commit -m "worktree $BR: land"

# 2. merge into base from the main checkout, push if there's a remote
git -C "$REPO" checkout "$BASE"
git -C "$REPO" merge --no-ff "$BR" -m "Merge worktree $BR into $BASE"
git -C "$REPO" remote get-url origin >/dev/null 2>&1 && git -C "$REPO" push origin "$BASE"

# 3. remove the worktree + branch, disarm the guard
git -C "$REPO" worktree remove "$WT" --force
git -C "$REPO" branch -d "$BR" 2>/dev/null || git -C "$REPO" branch -D "$BR"
rm -f "$FLAG"
echo "landed $BR -> $BASE, worktree removed, guard disarmed"
```

If the merge conflicts, STOP and report the conflicting files — do not force. Leave the flag in place so the guard stays armed until it's resolved.

---

## OFF / CANCEL  (`/worktree off`, `/worktree cancel`)

Abandon the worktree without merging (disarms the guard):
```bash
FLAGDIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.worktree-active"
REPO=$(git rev-parse --show-toplevel 2>/dev/null)
FLAG=$(grep -l "\"repoRoot\": \"$REPO\"" "$FLAGDIR"/*.json 2>/dev/null | head -1)
[ -z "$FLAG" ] && { echo "no active worktree"; exit 0; }
WT=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['wtPath'])" "$FLAG")
rm -f "$FLAG"
echo "guard disarmed. worktree still on disk at $WT — remove with: git worktree remove \"$WT\" --force"
```
Only delete the checkout if the user says so — their uncommitted work may be in it.

## Notes
- The guard is a global `PreToolUse` hook (`worktree-guard.js`), so it protects **every** session touching that repo — including a different Orca card's agent that never loaded this skill. That's the point: the flag, not the skill, is what enforces.
- Editing a *different* repo while a worktree is active is fine — the guard only blocks the flagged repo's main checkout.
- One flag per worktree; multiple repos can each have an active worktree at once.
