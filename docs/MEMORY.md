# Memory System

Learned preferences live as small fact files and compile into one generated file that Claude reads at the start of every session — so it remembers your preferences even after a conversation ends.

## The loop

Think of it like a preference notepad: you write a note, run a compile step, and from then on Claude reads it automatically.

1. **Source of truth:** `memory/facts/<id>.md` — one fact per file.
2. **Compile:** run `/memory-compile` in Claude Code → regenerates `memory/CLAUDE.generated.md`.
3. **Load:** `CLAUDE.md` imports `@memory/CLAUDE.generated.md` — loads every session automatically.
4. **Never hand-edit** `CLAUDE.generated.md` — it is overwritten on every compile.
5. **Commit** both the fact file and the regenerated output after any change.

## The 5 memory types

| Type | What it stores | Example |
|------|----------------|---------|
| `user` | Your role, skills, preferences | "senior Go engineer, new to React" |
| `feedback` | How Claude should behave | "no confirmation questions, act and continue" |
| `project` | Current work, deadlines, decisions | "freeze non-critical merges after 2026-06-26" |
| `reference` | Where to find things in external systems | "bugs tracked in Linear project INGEST" |
| `pattern` | A reusable working pattern (how to structure a task), promoted from repeated feedback | "read target + imports before dispatching a file-editing agent" |

## Everyday workflow — 3 ways to add memories

1. **Claude auto-saves** — during a session, Claude writes facts to `memory/facts/` automatically when it learns something worth keeping.
2. **`/remember-that`** — explicit control: add, delete, audit, or compile memories by hand.
3. **`/memory-compile`** — rebuilds `CLAUDE.generated.md` from all fact files. Run after any manual edit.

## Fact file format

```markdown
---
name: short-kebab-slug
description: one-line summary — what this preference is
metadata:
  type: user | feedback | project | reference | pattern
  # user     — who you are and how you work
  # feedback — things Claude did wrong or right that it should remember
  # project  — what's happening in a specific project (deadlines, goals, decisions)
  # reference — where to find things (Linear board, Slack channel, dashboard URL)
  # pattern  — a reusable working pattern (how to structure a task), promoted from repeated feedback
---

Body: the preference or rule. For feedback/project types, include **Why:** and **How to apply:** lines.
```

## What NOT to save

- Code patterns, architecture, file paths — derivable from the codebase
- Git history — use `git log` / `git blame`
- Debugging solutions — the fix is in the code; the commit message has context
- Anything already in a `CLAUDE.md` file
- Ephemeral task details or current conversation context

## Committing to git

`facts/` is gitignored (contains personal/private content). Only `MEMORY.md` and `CLAUDE.generated.md` are committed. Never force-add `facts/`.
