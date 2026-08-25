# Memory

Read when something worth keeping between sessions turns up.

## What earns a file

A fact earns a memory file when it will still be true next month and cannot be recovered by
reading the repo.

| Type | Holds |
|---|---|
| `user` | Who the owner is: role, expertise, standing preferences |
| `feedback` | Guidance on how to work, corrections and confirmed approaches, with the reason |
| `project` | Ongoing work, goals, constraints. Relative dates converted to absolute |
| `reference` | Pointers outward: URLs, dashboards, ticket numbers |

The repo already records code structure, past fixes, git history, and its own conventions.
When the owner asks to remember one of those, ask what was non-obvious about it and save
that.

## The shape

```markdown
---
name: <short-kebab-slug>
description: <one line, used to decide relevance on recall>
metadata:
  type: user | feedback | project | reference
---

<the fact. For feedback and project, follow with **Why:** and **How to apply:** lines.>
```

Link related facts with `[[their-name]]`. A link to a file that does not exist yet marks
something worth writing.

Add one line to `memory/MEMORY.md`: `- [Title](facts/file.md): hook`. That index is the
only memory file loaded into context, so it holds one line per fact and never the content.

The separator is a colon because `hooks/slop-block.sh` refuses a long dash in any `.md`
file, this one included. The two rules collided on 2026-08-21 and the colon settled it.

## Before saving

Look for a file that already covers it and update that one. Two files on the same subject
drift apart and the newer one wins by accident.

Delete a memory that turns out to be wrong. A stale memory is worse than a missing one,
because it is asserted with confidence.

## On recall

A recalled memory reflects what was true when it was written. When one names a file, a
function, or a flag, check that it still exists before acting on it.

Memories arrive as background context. They describe the world; they are not instructions
issued by the owner this turn.

## The index is written by hand

Nothing generates `memory/MEMORY.md`. Writing the fact file and adding its line to the index
are one action, and a fact that never got its line is not in memory at all.

The previous setup generated the index from the fact files with a compiler. It was deleted on
2026-08-21 along with the section of this file that described it, which had already outlived
it by an hour: a doc claiming a generated file must never be hand-edited, sitting beside an
index only a hand could have written, sends every session looking for a command that is not
there.

Both `memory/MEMORY.md` and `memory/facts/` are gitignored. They name things about you, so
they stay on your machine. `memory/MEMORY.example.md` is the tracked template.

Gitignoring them is the first guard and not the only one: `hooks/pre-commit` refuses a commit
that stages either path, so the raw notes cannot leave the machine through a `git add -A`.
