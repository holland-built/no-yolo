# Global Claude Code Instructions

This file loads for **every** Claude Code session, across every project.
Project-specific rules belong in that project's `CLAUDE.md`
(e.g. `/path/to/your/project/CLAUDE.md`).

---

## Learned Preferences (auto-compiled — do not edit here)

@memory/CLAUDE.generated.md

> Compiled from `~/.claude/memory/facts/` (the source of truth) by `/memory-compile`.
> To change a preference, edit the fact file and recompile — never edit the import above.
> High-confidence cross-project instincts auto-promote into the fact store.

---

## Core Rules

@docs/CORE_RULES.md

@docs/SKILL_TRIGGERS.md

---

## HARD RULE — This file is a pointer only

No content except file imports and the workflow pointer table.
A skill's triggers live in its own `description` frontmatter, which the harness already injects.
Do not add trigger blocks here or to `docs/SKILL_TRIGGERS.md` — that file is a routing rule only.
If you are about to add anything else — STOP. Find or create the right MD file and point to it instead.

## Workflow

- Planning → `~/.claude/docs/PLANNING.md`
- Testing → `~/.claude/docs/TESTING.md`
- UI/GUI changes → `~/.claude/docs/UI_MOCKUPS.md`
- Subagents + Agent Teams → `~/.claude/docs/SUBAGENTS.md`
- Context hygiene → `~/.claude/docs/CONTEXT.md`
- Skills & plugins → `~/.claude/docs/SKILLS.md`
- Shared vocabulary → `~/.claude/docs/CONTEXT_VOCAB.md`
- Code review discipline → `~/.claude/docs/CODE_REVIEW.md`
- Skill improvement ideas → `~/.claude/docs/SKILL_RECOMMENDATIONS.md`
- Memory system → `~/.claude/docs/MEMORY.md`
- Hooks → `~/.claude/docs/HOOKS.md`
- Skill authoring (no-yolo) → `~/.claude/docs/NO_YOLO.md`
- MCP services & external deps (Firecrawl, fallback pattern) → `~/.claude/docs/MCP_SERVICES.md`

---

## Maintenance Rules (Boris Cherny)

- If a rule above stops working, **nuke it and rewrite**. Do not preserve broken guidance.
- Review this file weekly. Trim, don't add.
- Keep concise. Project specifics belong in project CLAUDE.md.

---

## Caveman Mode

Caveman terse mode (scripts, toggle, state) → `~/.claude/docs/HOOKS.md`.
