---
name: publish-skills
description: Safely commit and push skill changes to github.com/holland-built/no-yolo. Shows diff, guards against personal file leaks, commits, pushes. Activate on "/publish-skills", "push skills", "publish to no-yolo".
user-invocable: true
argument-hint: "[optional commit message]"
allowed-tools:
  - Bash
---

# publish-skills

Publish your skill changes to `github.com/holland-built/no-yolo`.

## Step 1 — Show what changed

```bash
git -C ~/.claude status --short
```

Print the list. If nothing changed, output: "Nothing to publish. Working tree clean." and stop.

## Step 2 — Personal file guard (HARD block)

Scan the changed file list for any of these paths. If ANY match → STOP immediately, do not commit:

- `memory/`
- `brainstorms/`
- `plans/`
- `proposals/`
- `projects/`
- `sessions/`
- `settings.json`
- `settings.local.json`
- `history.jsonl`
- `*.log`
- `cache/`
- `paste-cache/`

Output: "BLOCKED — personal files in diff: [list them]. Fix before publishing."

## Step 3 — Filter to safe files

Only stage files under:
- `skills/`
- Root `*.md` files (CLAUDE.md, CORE_RULES.md, UI_MOCKUPS.md, etc.)
- `hooks/` (scripts only — no credential files)
- `setup.sh`
- `settings.example.json`

Skip anything else silently (it stays unstaged).

## Step 4 — Commit message

If `$ARGUMENTS` provided, use it as the commit message.

Otherwise auto-generate from changed files:
- List changed skill names: e.g. `update forge, quick-design: slop fingerprint + path fixes`
- Format: `[verb] [skill-names]: [one-line description of change]`

## Step 5 — Stage, commit, push

```bash
# Stage only safe files (add individually to avoid globbing personal dirs)
git -C ~/.claude add skills/ CLAUDE.md CORE_RULES.md UI_MOCKUPS.md PLANNING.md TESTING.md SUBAGENTS.md CONTEXT.md SKILLS.md CODE_REVIEW.md HOOKS.md MEMORY.md NO_YOLO.md setup.sh settings.example.json hooks/ README.md 2>/dev/null

# Commit
git -C ~/.claude commit -m "<generated or provided message>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

# Push
git -C ~/.claude push origin main
```

## Step 6 — Confirm

Output:
```
Pushed to github.com/holland-built/no-yolo
Files: [list of committed files]
```
