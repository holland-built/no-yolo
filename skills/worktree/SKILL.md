---
name: worktree
description: Use this skill when the user types /worktree, says "start a worktree", "work in a worktree", "do this in a worktree", "spin up a worktree", "branch this off in a worktree", "release the worktree", or "done with the worktree". Creates a git worktree, arms the hard guard hook (worktree-guard.js), and does the requested work inside it. Saying "release"/"done" merges the branch into its base and removes the worktree automatically.
user-invocable: true
argument-hint: "<task description> (a worktree name is derived from it)"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Agent
---

# worktree

The failure this prevents: a worktree gets created, but the work happens in the **main checkout** anyway (a subagent's cwd is pinned at launch, or an edit uses the old absolute path). A written reminder gets ignored — so this skill arms a **hard hook**: while a worktree is active, `hooks/worktree-guard.js` denies any `Edit`/`Write`/`NotebookEdit` whose target is inside the repo but outside the worktree. Not a prompt the model can talk past — a real deny, like `/lockstep`.

There are no sub-commands. `/worktree <task>` creates the worktree and does the work — one flow, no modes. Releasing it back into base is reached by saying so in plain language ("release", "done", "land it"), never by memorizing a second command.

Flags live in `$CLAUDE_CONFIG_DIR/.worktree-active/<name>.json` (falls back to `~/.claude`). One per active worktree; the hook reads them. Multiple worktrees can be active for the same repo at once.

---

## CREATE  (`/worktree <task description>`, or a trigger phrase)

`$ARGUMENTS` is the TASK, not a name — always derive a short kebab-case `NAME` from it (e.g. "fix the login redirect bug" → `fix-login-redirect`).

### 1. Make the worktree
```bash
REPO=$(git rev-parse --show-toplevel) || { echo "not in a git repo"; exit 1; }
NAME="<short kebab-case name derived from the task in $ARGUMENTS>"
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

### 3. Do the task — same turn, same flow
Creating the worktree is not the deliverable; the task in `$ARGUMENTS` is. Immediately after arming the guard, do the requested work under `$WT` — do not stop and wait after step 2. Tell the user: worktree `<name>` created at `$WT`, the guard is armed, then proceed straight into the task. Any subagent you dispatch is told explicitly: *"Your working directory is `$WT`; all reads and edits are under that path — the main checkout is hook-blocked."*

> If you ever see `WORKTREE GUARD — blocked edit to the MAIN checkout`, you targeted the wrong path — re-issue the same edit under `$WT`. Do not try to disable the hook to get past it.

---

## RELEASING (natural language — not a sub-command)

Triggers: "release", "done", "land it", "remove the worktree(s)", or `/release` — spoken while at least one worktree flag is active for the current repo. No sub-command to remember.

Merge every active worktree branch for this repo into its recorded base, remove each worktree, delete each branch, disarm each guard. Repo-agnostic — does not need a SHIP.md. Loops because more than one worktree can be active for the same repo at once.

```bash
FLAGDIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.worktree-active"
REPO=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO" ] && { echo "not in a git repo"; exit 1; }

# every flag belonging to this repo (there may be several). Use a while-read
# over process substitution, NOT `for FLAG in $FLAGS` — plain word-splitting of
# a multi-line variable is a bash-ism that silently does the WRONG thing under
# zsh (no split, so $FLAG ends up empty/multi-path and every `git -C "$WT"`
# below falls through to the shell's cwd — i.e. the main checkout).
FOUND=0
while IFS= read -r FLAG; do
  [ -z "$FLAG" ] && continue
  FOUND=1
  read -r WT BR BASE < <(python3 - "$FLAG" <<'PY'
import json,sys
f=json.load(open(sys.argv[1]))
print(f["wtPath"], f["branch"], f.get("base","main"))
PY
  )
  [ -z "$WT" ] && { echo "skipping unreadable flag $FLAG"; continue; }

  # 1. commit anything still pending in the worktree
  git -C "$WT" add -A
  git -C "$WT" diff --cached --quiet || git -C "$WT" commit -m "worktree $BR: release"

  # 2. merge into base from the main checkout
  git -C "$REPO" checkout "$BASE"
  if ! git -C "$REPO" merge --no-ff "$BR" -m "Merge worktree $BR into $BASE"; then
    echo "MERGE CONFLICT in $BR — STOP, report the conflicting files, leave this flag armed."
    continue   # do not remove this worktree/branch/flag; move on to the rest
  fi

  # 3. push — only when this repo has no SHIP.md (release skill owns SHIP.md pushes)
  if [ ! -f "$REPO/SHIP.md" ]; then
    git -C "$REPO" remote get-url origin >/dev/null 2>&1 && git -C "$REPO" push origin "$BASE"
  else
    echo "push deferred to the SHIP.md playbook"
  fi

  # 4. remove the worktree + branch, disarm the guard
  git -C "$REPO" worktree remove "$WT" --force
  git -C "$REPO" branch -d "$BR" 2>/dev/null || git -C "$REPO" branch -D "$BR"
  rm -f "$FLAG"
  echo "released $BR -> $BASE, worktree removed, guard disarmed"
done < <(grep -l "\"repoRoot\": \"$REPO\"" "$FLAGDIR"/*.json 2>/dev/null)
[ "$FOUND" = 0 ] && echo "no active worktree for this repo"
```

If a merge conflicts, STOP and report the conflicting files for that worktree — do not force. Leave that flag in place so the guard stays armed until it's resolved; still process any other flags for this repo.

---

## Abandoning (not a command — only on explicit request)

If the user explicitly says something like "discard/throw away the worktree, don't merge": remove that worktree's flag (`rm -f "$FLAG"`) and tell them the checkout is still on disk — the guard is now disarmed but nothing was deleted. Only run `git worktree remove --force` (and delete the branch) if they separately confirm they want the checkout itself deleted; their uncommitted work may be in it.

## Notes
- The guard is a global `PreToolUse` hook (`worktree-guard.js`), so it protects **every** session touching that repo — including a different Orca card's agent that never loaded this skill. That's the point: the flag, not the skill, is what enforces.
- Editing a *different* repo while a worktree is active is fine — the guard only blocks the flagged repo's main checkout.
- One flag per worktree; multiple repos — and multiple worktrees within the same repo — can each be active at once.
