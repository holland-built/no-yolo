---
id: user-single-paste-prompts
tier: user
type: feedback
name: Single-paste prompts always
description: When the user needs to run something, give ONE consolidated copy-paste block, never a numbered list of separate prompts/commands.
status: active
captured: 2026-05-18
updated: 2026-05-30
confidence: 1.0
provenance:
  - session: cbcd48cc-f9b9-4a09-905a-cd57c34f9f2b
    date: 2026-05-18
supersedes: []
superseded-by: null
---

Always deliver ONE cut-and-paste prompt. Never split verification, setup, or workflow steps across multiple paste-able blocks.

**Why:** Single prompt = single paste. Multi-step paste sequences are friction.

**How to apply:**
- Verification/setup/diagnostic flows -> one prompt that does it all.
- Bash multi-step -> chain with `&&` or `;` into one block.
- If a task genuinely needs a human decision mid-way, say so explicitly — but default to single-paste.

Combine with [[user-output-format-bullets]].
