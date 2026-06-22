# Memory System

Learned preferences live as small fact files and compile into one generated file that Claude reads at the start of every session — so it remembers your preferences even after a conversation ends.

## The loop

Think of it like a preference notepad: you write a note, run a compile step, and from then on Claude reads it automatically.

1. **Source of truth:** `memory/facts/<id>.md` — one fact per file.
2. **Compile:** run `/memory-compile` in Claude Code → regenerates `memory/CLAUDE.generated.md`.
3. **Load:** `CLAUDE.md` imports `@memory/CLAUDE.generated.md` — loads every session automatically.
4. **Never hand-edit** `CLAUDE.generated.md` — it is overwritten on every compile.
5. **Commit** both the fact file and the regenerated output after any change.

## Adding or changing a preference

1. Add or edit a file in `memory/facts/<id>.md`
2. Run `/memory-compile` in Claude Code
3. Commit both the fact file and `memory/CLAUDE.generated.md`

High-confidence cross-project instincts auto-promote into the fact store over time.

## Fact file format

```markdown
---
name: short-kebab-slug
description: one-line summary — what this preference is
metadata:
  type: user | feedback | project | reference
  # user     — who you are and how you work
  # feedback — things Claude did wrong or right that it should remember
  # project  — what's happening in a specific project (deadlines, goals, decisions)
  # reference — where to find things (Linear board, Slack channel, dashboard URL)
---

Body: the preference or rule. For feedback/project types, include **Why:** and **How to apply:** lines.
```

## What NOT to save

- Code patterns, architecture, file paths — derivable from the codebase
- Git history — use `git log` / `git blame`
- Debugging solutions — the fix is in the code
- Ephemeral task details or current conversation context
