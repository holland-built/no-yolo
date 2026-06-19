---
name: whats-next
description: Context scanner — reads in-flight work (brainstorms, git status, changelog) and either surfaces what's unfinished OR offers a menu of next actions when the slate is clean. Never prescribes audit over active work. Activate on "/whats-next", "what's next", "what should I do", "now what".
user-invocable: true
argument-hint: ""
allowed-tools:
  - Bash
  - Read
---

# whats-next

**Rule: observe, list, never decide.** If work is in-flight, show it and stop. Audit/review options only appear when nothing is in progress.

---

## Step 1 — Scan for in-flight work

Run these silently:

```bash
# Recent brainstorm files (forge/grill-me sessions)
find . -path "*/brainstorms/*.md" \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  2>/dev/null | sort -r | head -10

# Uncommitted changes
git status --short 2>/dev/null | head -30

# Last 3 changelog entries
grep -m3 "^## " DAILY_CHANGELOG.md 2>/dev/null
```

---

## Step 2 — Interpret results

### IF any in-flight signals found (brainstorms files OR uncommitted git changes):

Show a table of what's unfinished:

| Signal | Detail | Suggested next step |
|---|---|---|
| brainstorms file | filename + last heading found | which forge/grill-me phase it stopped at |
| uncommitted changes | files listed | commit, or continue editing |

**Stop here. Do not offer audit/review options.**
The user has active work — don't redirect them.

### IF nothing in-flight (no brainstorms, clean git):

Print: `> Slate is clean. What do you want to do next?`

Then offer the menu:

| Option | Skill | When to pick |
|---|---|---|
| Audit codebase | `/code-health` | Dead code, YAGNI, over-engineering |
| Review recent changes | `/code-review` | Before merging a diff |
| Design options | `/quick-design [describe it]` | Want to see mockups before building |
| Plan a feature | `/grill-me` | Have an idea, need to think it through |
| Build a feature | `/forge [describe it]` | Ready to go, full pipeline |
| Orient in project | `/my-md` | New to a codebase, want to see what docs exist |

Do NOT auto-run any of these. Present the table, wait for the user to pick.

---

## Step 3 — Read brainstorm files (skip if none found in Step 1)

For each brainstorm file found in Step 1, read the last 20 lines to find where it stopped:
- Last `**Q:**` line = grill-me in progress
- Last forge phase heading (`## 0`, `## 1`, etc.) = which phase it stopped at

Report: `[filename] — stopped at: [phase or last decision]`
