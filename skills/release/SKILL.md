---
name: release
description: Use this skill when the user types /release, says 'release', 'push this', 'commit and push', or 'get this to github'. ONE context-aware publish command for ANY repo — reads the repo-root SHIP.md playbook and runs it, environment-aware (dev/staging/prod). If no SHIP.md exists, it STOPS (lockstep) and guides you to build one before anything is committed or pushed.
user-invocable: true
argument-hint: "[env: dev|staging|prod] [optional commit message] [--auto]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
---

# release

One verb to publish any repo to GitHub. The repo-specific recipe lives in `<repo-root>/SHIP.md`; this skill detects the repo, reads its `SHIP.md`, and runs it for the target environment. Same command everywhere — `~/.claude`, Wayfinder, MCP, any git repo.

## Step 0 — Locate repo + playbook

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && { echo "Not inside a git repo — nothing to release."; exit 0; }
SHIP="$REPO_ROOT/SHIP.md"
echo "Repo: $REPO_ROOT"; [ -f "$SHIP" ] && echo "Playbook: found" || echo "Playbook: MISSING"
```

## Step 0.5 — Active worktree teardown

A worktree is "active" for this repo if a guard flag names it (flags are written by the `worktree-autoarm.js` SessionStart hook whenever a session runs inside a linked worktree — Orca sidebar, `git worktree add`, etc.). Tear every one of them down: merge each branch into its recorded base, remove each worktree, delete each branch, delete each flag. Self-push only when this repo has **no** `SHIP.md` (with a SHIP.md the playbook below owns the push).

```bash
FLAGDIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.worktree-active"
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
  git -C "$REPO_ROOT" checkout "$BASE"
  if ! git -C "$REPO_ROOT" merge --no-ff "$BR" -m "Merge worktree $BR into $BASE"; then
    echo "MERGE CONFLICT in $BR — STOP, report the conflicting files, leave this flag armed."; continue
  fi
  # 3. push only when this repo has NO SHIP.md (else the playbook pushes)
  if [ ! -f "$REPO_ROOT/SHIP.md" ]; then
    git -C "$REPO_ROOT" remote get-url origin >/dev/null 2>&1 && git -C "$REPO_ROOT" push origin "$BASE"
  else
    echo "push deferred to the SHIP.md playbook"
  fi
  # 4. remove worktree + branch, disarm the guard
  git -C "$REPO_ROOT" worktree remove "$WT" --force
  git -C "$REPO_ROOT" branch -d "$BR" 2>/dev/null || git -C "$REPO_ROOT" branch -D "$BR"
  rm -f "$FLAG"
  echo "released $BR -> $BASE, worktree removed, guard disarmed"
done < <(grep -l "\"repoRoot\": \"$REPO_ROOT\"" "$FLAGDIR"/*.json 2>/dev/null)
[ "$FOUND" = 0 ] && echo "no active worktree for this repo"
```

If `$FOUND` was 1 (at least one worktree torn down):
- **`SHIP.md` exists**: the teardown deliberately did not push. Continue to Step 2 on the now-current base branch — the rest of this skill pushes it via the playbook.
- **`SHIP.md` missing**: the teardown already merged, pushed (if a remote exists), and released the work — there is nothing left for `/release` to do. Report what was released and finish here; do NOT hard-stop into Step 1. Optionally offer to author a `SHIP.md` for next time, but that offer is optional, not a gate.

If a merge conflict occurred during teardown, it already stopped and left that flag armed — report it and finish; do not continue into Step 1/2.

## Step 1 — Missing playbook → LOCKSTEP (never push blind)

If `SHIP.md` does NOT exist at the repo root AND no worktree teardown just released the work:
- **STOP. Do not commit, do not push, do not stage.** Announce: *"No SHIP.md in this repo — I won't push blind. Let's build the playbook first."*
- This is lockstep posture: nothing ships until the playbook is authored AND you approve it. (Adopt the posture — do not toggle the lockstep hook, which would block writing the file.)
- Interview one question at a time (use AskUserQuestion). Collect:
  1. GitHub remote (confirm `git remote -v`)
  2. Environments and their branches — e.g. dev→`dev`, staging→`staging`, prod→`prod`/`main`. Which is the default?
  3. Per-environment pre-steps — version bump? changelog file + path? "What's New" entry? menu/asset regen?
  4. Hard guards — path patterns that must NEVER be committed here (secrets, personal dirs)
  5. Post-push — GitHub release/tag? none?
- Draft `SHIP.md` from the answers using the template at the bottom. Show it. On explicit approval, Write it to `<repo-root>/SHIP.md`.
- Then continue to Step 2. Never invent a playbook and push in the same breath.

## Step 2 — Parse the playbook

Read `SHIP.md`. Extract:
- **`## Environments`** — table `env | branch | notes`. Target env = the env in `$ARGUMENTS` if given, else the row marked default (`*`).
- **`## Steps`** — ordered pre-commit actions to run (changelog, version bump, regen, etc.).
- **`## Guards`** — hard-block path/content patterns.
- **`## Release`** — optional post-push tag/release recipe.

Echo the resolved target: `env=<x> → branch=<y>`.

## Step 3 — Hard gates (block on hit)

- **Personal-file guard:** if any staged/changed path matches a `## Guards` pattern → STOP, list them.
- **Leak scan:**
  ```bash
  git -C "$REPO_ROOT" diff HEAD | grep -E "^\+" | grep -vE "^\+\+\+" | grep -E \
    "/Users/[a-zA-Z0-9_-]+|password\s*[:=]|secret\s*[:=]|api[_-]?key\s*[:=]|AKIA[0-9A-Z]{16}"
  ```
  Any match → STOP: `BLOCKED — secret/personal data in diff`.

## Step 3.5 — Sync check (never push blind against a moved remote)

```bash
git -C "$REPO_ROOT" fetch origin "<target-branch>" 2>/dev/null
BEHIND=$(git -C "$REPO_ROOT" rev-list HEAD.."origin/<target-branch>" --count 2>/dev/null || echo 0)
```

If `BEHIND > 0`: **STOP.** GitHub has commits this machine doesn't — pushing now risks a
rejected push or overwriting work. Tell user: "GitHub has N commit(s) you don't have locally.
Run `/update` to see what changed, then pull/rebase before I push." Do not merge or rebase
here — that's `/update`'s job, not `/release`'s. This is a narrower check than full `/update`
(just "is it safe to push"), not a substitute for it.

If `BEHIND = 0`: continue.

## Step 4 — Run the playbook

Execute each `## Steps` action in order for the target env. Then:
- Stage per SHIP.md (`git add -A` by default, or the file's stated scope).
- Commit — message from `$ARGUMENTS` or auto-generated; footer `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Push: `git -C "$REPO_ROOT" push origin <target-branch>`.
- If `## Release` defined and the user's intent includes publishing (not just pushing), run it; otherwise report it as skipped/optional.

Skip the approval gate only if `$ARGUMENTS` contains `--auto`.

## Step 5 — Confirm

Print: repo, target env → branch, commit hash, push result, and any tag/release (or "release skipped — optional").

---

## SHIP.md template (authored when missing)

```markdown
# SHIP.md — release playbook for <repo name>

## Environments
| Env | Branch | Default | Notes |
|-----|--------|---------|-------|
| dev | dev | * | day-to-day pushes |
| staging | staging | | pre-prod sync |
| prod | prod | | production |

## Steps
1. <e.g. bump version in package.json>
2. <e.g. append entry to CHANGELOG.md / What's New>
3. <e.g. regenerate menus/assets>

## Guards
- .env
- secrets/
- <any path that must never be committed>

## Release
- <post-push tag/release recipe, or "none">
```
