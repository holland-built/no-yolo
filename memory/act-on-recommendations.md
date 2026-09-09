---
name: act-on-recommendations
description: Act on your own recommendation instead of asking to confirm each step
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b66c9480-1e8c-4582-bd5d-0f0e0222e4c6
  modified: 2026-09-09T10:24:16.768Z
---

When you've already given a recommendation and the user has signalled the overall direction, execute it — don't stop to confirm each step. Batch decisions into one message rather than serving them one at a time, unless the user explicitly asks to go one at a time.

**Why:** On 2026-09-09, while setting up the mattpocock-skills plugin, I asked four separate confirmation questions in a row after already stating my recommended answer for each. They pushed back: the asking read as stalling, not diligence.

**How to apply:** State the recommendation and act. Reserve a blocking question for choices that are genuinely irreversible or where being wrong would waste real work. A gated config change with a backup is not one of those.

Related: [[prefers-short-answers]]
