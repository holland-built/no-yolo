---
id: user-subagent-execution
tier: user
type: feedback
name: Always subagent-driven plan execution
description: After writing any plan, immediately dispatch subagent-driven development; never ask 'inline or subagent', never offer inline.
status: active
captured: 2026-05-18
updated: 2026-05-30
confidence: 1.0
provenance:
  - session: 61d58425-a2ff-42e1-a456-30446b0ec30b
    date: 2026-05-18
supersedes: []
superseded-by: null
---

Always use subagent-driven development when executing plans. Never ask "which approach?", never offer inline execution.

**Why:** User said "always choose subagent, don't ask."

**How to apply:** After writing any plan, immediately invoke subagent-driven execution without presenting options. See also [[pattern-agent-read-before-dispatch]].
