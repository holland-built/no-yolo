---
name: update
description: Use this skill when the user types /update, says 'check for updates', 'am I out of date', 'what's new', 'update my setup', or 'rollback'. Checks for, previews, and applies updates to ~/.claude setup — rollback and restore-removed-skill included.
user-invocable: false
---

# update

Check if your Claude Code setup is out of date, preview what would change, and update safely.

## Modes

| Command | What it does |
|---|---|
| `/update` | Check if you're behind — shows how many versions, what's new, what's removed |
| `/update preview` | Detailed plain-English changelog without changing anything |
| `/update full` | Pull all changes + re-run full setup |
| `/update rules` | Pull changes + rules only (no tool installs) |
| `/update rollback` | Undo the last update, go back to what you had |
| `/update restore <skill-name>` | Bring back a skill that was removed in an update |

## How to run

### Step 1 — fetch remote state (no changes made yet)

Run silently:
```bash
cd ~/.claude
git fetch origin main 2>/dev/null
```

### Step 2 — check how far behind

```bash
BEHIND=$(git rev-list HEAD..origin/main --count)
AHEAD=$(git rev-list origin/main..HEAD --count)
```

If BEHIND is 0: output "Your setup is up to date. Nothing to pull." and stop.

If BEHIND > 0: continue.

### Step 3 — translate commits into plain English

```bash
git log HEAD..origin/main --oneline
```

For each commit line, translate the prefix into plain language:
- `feat:` or `feat(` → "New:"
- `fix:` or `fix(` → "Fixed:"
- `docs:` or `docs(` → "Docs updated:"
- `chore:` or `refactor:` → "Cleanup (no action needed):"
- `remove` or `nuke` or `delete` in message → ⚠️ "Removed:"

Show as a numbered list, newest first. No git hashes. No jargon.

### Step 4 — detect what's new and what's removed

```bash
# New skills added remotely
git diff HEAD origin/main --name-status | grep "^A.*skills/.*/SKILL\.md"

# Skills removed remotely  
git diff HEAD origin/main --name-status | grep "^D.*skills/.*/SKILL\.md"

# Rule files changed
git diff HEAD origin/main --name-status | grep -E "^M.*(CLAUDE|CORE_RULES|PLANNING|TESTING|SUBAGENTS|CODE_REVIEW)\.md"
```

Format output:

```
📦 What you'd get:
  + /graphify skill (new)
  + /brief skill (new)
  ~ PLANNING.md updated (rules changed)

⚠️  What would be removed:
  - /debate skill (renamed to /brief — use /update restore debate to get it back)

ℹ️  You are 3 updates behind.
```

If nothing is removed: skip the ⚠️ section entirely.

### Step 4.5 — plugin status

Read installed plugins (read-only — never auto-update):

```bash
python3 - "$HOME/.claude/plugins/installed_plugins.json" <<'PYEOF'
import json, sys, os
p = sys.argv[1]
if not os.path.exists(p):
    print("No plugins installed."); raise SystemExit
try:
    plugins = json.load(open(p)).get("plugins", {})
except Exception:
    print("installed_plugins.json unreadable."); raise SystemExit
if not plugins:
    print("No plugins installed."); raise SystemExit
for name, entries in plugins.items():
    e = entries[0] if entries else {}
    print(f"{name}\t{e.get('version','?')}\t{e.get('scope','?')}")
PYEOF
```

Show as a table: **Plugin | Installed version | Scope**. Flag any row whose version is `unknown` or `?` as ⚠️ "may be stale — reinstall to pin a version".

Then output verbatim:
> To check for plugin updates, run `/plugin list` inside Claude Code, then `/plugin update <name>` for any that are outdated. Plugins can't be updated from outside the session.

### Step 5 — offer options (when run with no argument)

After showing the summary, output:

```
What do you want to do?
  /update preview   — see the full detailed changelog
  /update full      — apply everything (pulls + installs tools)
  /update rules     — apply rules only (no tool installs)
  /update rollback  — go back to what you had before
```

Then stop. Do not auto-pull.

### Step 6 — if argument is `preview`

Show the full git diff of changed markdown files in plain English. For each changed .md file:
- State what file changed and what section was affected
- Quote the before and after for changed lines (use simple "was: / now:" format)
- Highlight any lines that were deleted (user may want to keep them)

Do NOT show raw git diff output. Translate everything.

### Shared: sync-and-run

Used by Steps 7 and 8. Substitute `<SETUP_CMD>` with the caller's command.

**Dirty-check stash guard:**
```bash
cd ~/.claude && DIRTY=$(git status --porcelain)
```
If DIRTY non-empty: tell user "You have local changes I'm setting aside safely before updating." Run `git stash push -m "pre-update stash $(date +%Y-%m-%d)"`. After pull completes run `git stash pop`. If stash pop has conflicts: "Some of your local changes conflicted with the update. Your originals are in git stash — run `git stash pop` in your terminal to review."

**AHEAD/IS_FORK/SYNC_REF detection:**
```bash
cd ~/.claude
AHEAD=$(git rev-list origin/main..HEAD --count 2>/dev/null || echo 0)
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
IS_FORK=false; SYNC_REF=origin/main
if ! echo "$ORIGIN_URL" | grep -q "holland-built/no-yolo"; then
  IS_FORK=true
  EXISTING=$(git remote get-url upstream 2>/dev/null || echo "")
  [ -z "$EXISTING" ] && git remote add upstream https://github.com/holland-built/no-yolo.git \
    || git remote set-url upstream https://github.com/holland-built/no-yolo.git
  git fetch upstream main; SYNC_REF=upstream/main
fi
```

**If AHEAD = 0:** `git merge --ff-only "$SYNC_REF" && <SETUP_CMD>`

**If AHEAD > 0:** Tell user "You have [N] local commit(s). Rebasing on top of latest."
```bash
CONFLICTS=""
git rebase "$SYNC_REF"; REBASE_EXIT=$?
[ $REBASE_EXIT -ne 0 ] && CONFLICTS=$(git diff --name-only --diff-filter=U 2>/dev/null) && git rebase --abort
```
If rebase failed: tell user commits are untouched, list CONFLICTS, print `git fetch [upstream|origin] main && git rebase [SYNC_REF]` + `git rebase --continue`. STOP.
If rebase succeeded: run `<SETUP_CMD>`. If IS_FORK: tell user "force-push needed: `git push --force origin main`"

### Step 7 — if argument is `full`

Confirm: "Pulling all updates and re-running setup. This takes about 30 seconds. Continue? (y/n)"

Run the **Shared: sync-and-run** block above using `bash ~/.claude/setup.sh` as `<SETUP_CMD>`.

After success: show plain-English summary of what changed. Tell user: "Reopen Claude Code to pick up the changes."

### Step 8 — if argument is `rules`

Run the **Shared: sync-and-run** block above using `bash ~/.claude/setup.sh --md-only` as `<SETUP_CMD>`.

Tell user: "Rules updated. Tool installs skipped. Reopen Claude Code to pick up changes."

### Step 9 — if argument is `rollback`

**First: same dirty-check guard as Step 7.** If DIRTY non-empty: "You have unsaved local changes. Rolling back would delete them. Type `cancel` to stop." Wait for response.

**Create a restore point before touching anything:**
```bash
git tag claude-restore-$(date +%Y%m%d-%H%M%S)
```
Tell user: "Saved a restore point — if anything goes wrong you can always get back to right now."

Show last 5 states as a numbered list with plain-English dates:
```
Your recent setup history:
  1. Today (current) — added /brief skill, updated PLANNING.md
  2. 3 days ago — fixed README typos
  3. Last week — added graphify token-saving docs

Which one do you want to go back to? (type the number)
```

After user picks, use `git revert` (keeps history, safe) NOT `git reset --hard` (permanent, destructive):
```bash
git revert --no-commit <hash-range>
git commit -m "rollback: reverted to <chosen-date>"
```

Tell user: "Rolled back. Nothing permanently deleted — your history is preserved. Reopen Claude Code to pick up the changes."

### Step 10 — if argument is `restore <skill-name>`

```bash
git show origin/main:skills/<skill-name>/SKILL.md > ~/.claude/skills/<skill-name>/SKILL.md
```

If the skill doesn't exist on origin/main either, search recent history:
```bash
git log --all --oneline -- skills/<skill-name>/SKILL.md
```

Show the user what commits touched that skill and let them pick which version to restore.

After restoring: remind user to add the trigger back to CLAUDE.md if they want `/skill-name` to work.
