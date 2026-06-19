# Curated Memory — Schema Contract

This directory is the **source of truth** for what Claude knows about how you work.
The compiled views (`CLAUDE.generated.md`, project `MEMORY.md`) are REGENERATED from these
facts by `/memory-compile` — never hand-edit a generated file.

## Layout

```
~/.claude/memory/
  facts/*.md                              tier:user   — global, cross-project source of truth
  CLAUDE.generated.md                     GENERATED view (loaded at SessionStart, line-capped)
  compile-manifest.json                   GENERATED — last compile time + per-fact hashes
  SCHEMA.md                               this file

~/.claude/projects/<slug>/memory/
  facts/*.md                              tier:project — project-scoped source of truth
  MEMORY.md                               GENERATED index for that project
```

## Fact file format (`facts/*.md`)

```yaml
---
id: user-no-confirmation-questions     # stable slug == filename; targeted by supersedes/links
tier: user | project                   # user = global/cross-project; project = one repo only
type: user | feedback | project | reference | pattern
name: Short human title
description: One line — this is the text the compiler lifts verbatim into the view
status: active | superseded | needs-review
captured: 2026-05-30                    # absolute date; relative phrases resolved at capture
updated: 2026-05-30
confidence: 1.0                         # 1.0 = hand-confirmed; <1.0 = carried from an instinct
provenance:                             # where this belief came from (list)
  - session: <uuid>
    date: 2026-05-30
    note: optional origin note
supersedes: []                          # ids this fact replaces
superseded-by: null                     # id of the fact that replaced this one
---

Body: the full statement. For feedback/pattern facts, follow with:
**Why:** the reason.
**How to apply:** concrete behavior.
Link related facts with [[id]].
```

## Rules (from the hybrid memory architecture — see KB topic memory-context-architecture)

1. **Truth vs view.** `facts/*.md` are truth. `CLAUDE.generated.md` + `MEMORY.md` are views,
   rebuilt from truth. Fix a fact and recompile — never patch a view.
2. **Supersede, don't merge.** When a belief changes, flip the old fact's `status` to
   `superseded` + set `superseded-by`; create a NEW fact with `supersedes: [old-id]`. The old
   file stays on disk so the history/contradiction is traceable. Never overwrite in place.
3. **Provenance always.** Every fact carries `captured` (absolute date) + `provenance`.
4. **Tiering.** A fact is `tier:user` if it stays true regardless of which repo is open
   (identity, cross-project preferences, transferable lessons). It is `tier:project` if it
   names a path/repo/branch/product/schema. Promote project->user when the same preference
   appears in >=2 projects OR contains no project-bound noun OR is stated as universal.
5. **needs-review.** Auto-promoted instincts that conflict with an active fact land as
   `status: needs-review` (never auto-overwrite); surfaced at SessionStart for confirmation.
6. Only `status: active` facts render into the compiled views.
