---
id: pattern-agent-read-before-dispatch
tier: user
type: pattern
name: Read target + imports before dispatching a file-modifying agent
description: Before dispatching any agent that edits an existing file, the coordinator reads that file and its direct imports and writes an explicit 'already exists — do NOT recreate' section; cap agent output ~300 words.
status: active
captured: 2026-05-22
updated: 2026-05-30
confidence: 0.9
provenance:
  - session: 24707073-c931-4762-a514-9afe96644ce0
    date: 2026-05-22
supersedes: []
superseded-by: null
---

Before dispatching an agent that modifies an existing file: read that file AND its direct imports first, and put an explicit "Already exists — do NOT recreate" section in the agent prompt. Coordinator reads; agents implement only. Cap agent output ~300 words; delegate file reads to agents and get summaries back rather than reading large files in the main thread.

**Why (origin):** A migration wave in the primary project added a duplicate Resources section because the agent wasn't told ResourcesMenu already had What's New/Roadmap stubs — cost an extra fix wave. Lesson is transferable to any project.

Pairs with [[user-subagent-execution]].
