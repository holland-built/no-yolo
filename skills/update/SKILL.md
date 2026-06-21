---
name: update
description: Check for, preview, and apply updates to your ~/.claude setup. See what's new, what's removed, and what changed — before or after pulling. Also handles rollback and restoring deleted skills.
user-invocable: true
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

### Step 7 — if argument is `full`

Confirm first:
```
Pulling all updates and re-running setup. This takes about 30 seconds. Continue? (y/n)
```

Wait for confirmation, then run:
```bash
cd ~/.claude && git pull origin main && bash ~/.claude/setup.sh
```

After: show plain-English summary of what changed (same format as Step 4).

### Step 8 — if argument is `rules`

Same as full but:
```bash
cd ~/.claude && git pull origin main && bash ~/.claude/setup.sh --md-only
```

Tell user: "Rules updated. Tool installs skipped. Reopen Claude Code to pick up changes."

### Step 9 — if argument is `rollback`

```bash
git log --oneline -5
```

Show last 5 states as a numbered list with plain-English dates ("3 days ago", "last week"):

```
Your recent setup history:
  1. Today (current) — added /brief skill, updated PLANNING.md
  2. 3 days ago — fixed README typos  
  3. Last week — added graphify token-saving docs
  
Which one do you want to go back to? (type the number)
```

After user picks:
```bash
git reset --hard <chosen-hash>
```

Warn: "This cannot be undone without re-pulling. Your local changes (if any) will be lost."

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
