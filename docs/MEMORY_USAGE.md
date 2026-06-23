# Memory System — Teammate Onboarding

## 1. What the memory system does

It lets Claude remember facts about how you work across sessions, so you don't repeat the same guidance. Without it, every new session starts with zero context.

## 2. Where it lives

| File | Role |
|------|------|
| `memory/MEMORY.md` | Index — one line per memory, links to the fact file |
| `memory/facts/*.md` | Source of truth — one file per fact (gitignored for privacy) |
| `memory/CLAUDE.generated.md` | Compiled result — loaded by CLAUDE.md every session |

`facts/` is gitignored. `MEMORY.md` and `CLAUDE.generated.md` are tracked.

## 3. The 4 memory types

| Type | What it stores | Example |
|------|----------------|---------|
| `user` | Your role, skills, preferences | "senior Go engineer, new to React" |
| `feedback` | How Claude should behave | "no confirmation questions, act and continue" |
| `project` | Current work, deadlines, decisions | "freeze non-critical merges after 2026-06-26" |
| `reference` | Where to find things in external systems | "bugs tracked in Linear project INGEST" |

## 4. Fact file format

```markdown
---
name: short-kebab-slug
description: one-line summary used to decide relevance
metadata:
  type: user | feedback | project | reference
---

Memory body. For feedback/project: lead with the rule/fact, then **Why:** and **How to apply:** lines.
```

## 5. Everyday workflow — 3 ways to add memories

1. **Claude auto-saves** — during a session, Claude writes facts to `memory/facts/` automatically when it learns something worth keeping.
2. **`/remember-that`** — explicit control: add, delete, audit, or compile memories by hand.
3. **`/memory-compile`** — rebuilds `CLAUDE.generated.md` from all fact files. Run after any manual edit.

## 6. What NOT to save

- Code patterns, file paths, architecture — read the code instead
- Git history — use `git log` / `git blame`
- Debugging solutions — the fix is in the code; the commit message has context
- Anything already in a `CLAUDE.md` file
- In-progress work or temporary session state

## 7. Committing to git

`facts/` is gitignored (contains personal/private content). Only `MEMORY.md` and `CLAUDE.generated.md` are committed. Never force-add `facts/`.
