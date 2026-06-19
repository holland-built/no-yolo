---
id: user-kb-best-practices
tier: user
type: reference
name: KB-mined Claude Code best practices
description: High-signal Claude Code rules mined from the Obsidian KB (Karpathy/Cherny/Kochel) not yet in the global MD chain — apply when relevant.
status: active
captured: 2026-05-18
updated: 2026-05-30
confidence: 0.9
provenance:
  - session: 277c69aa-2440-439e-aa44-1c22802c2f12
    date: 2026-05-18
supersedes: []
superseded-by: null
---

Rules distilled from `~/AI/Knowledge Base/wiki/topics/ai/` (pattern-claude-md, tool-claude-code) — apply when relevant:

- **Learning-with-Claude (Kochel via Cherny):** when building something new, explain principles + system connections, not just the diff. Especially when user isn't a deep engineer in the touched stack.
- **`claude --chrome`** is Cherny's #1 CLI flag — suggest for browser-driven sessions.
- **`--effort extra-high`** forces Opus quality mode — use for hard correctness-critical problems.
- **Skill Creator "with vs without skill" side-by-side test** — recommend when authoring/modifying a skill.
- **ultrareview** — only confirmed, independently-reproduced bugs surface; worth it before auth/payment/DB merges (needs Claude account).
- **`/context`+`/compact` habit** — reported 2.4x longer sessions, -43% re-explaining.
- **"3 questions upfront = 0 wasted code"** — but note this is tempered by [[user-no-confirmation-questions]]: ask upfront only when a wrong default wastes significant effort.

**Sources:** KB `wiki/topics/ai/pattern-claude-md.md`, `tool-claude-code.md`.
