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

@CORE_RULES.md

@SKILL_TRIGGERS.md

---

## HARD RULE — This file is a pointer only

No content except file imports and the workflow pointer table.
Skill triggers live in `SKILL_TRIGGERS.md` — add new ones there, not here.
If you are about to add anything else — STOP. Find or create the right MD file and point to it instead.

## Workflow

- Planning → `~/.claude/PLANNING.md`
- Testing → `~/.claude/TESTING.md`
- UI/GUI changes → `~/.claude/UI_MOCKUPS.md`
- Subagents + Agent Teams → `~/.claude/SUBAGENTS.md`
- Context hygiene → `~/.claude/CONTEXT.md`
- Skills & plugins → `~/.claude/SKILLS.md`
- Shared vocabulary → `~/.claude/CONTEXT_VOCAB.md`
- Code review discipline → `~/.claude/CODE_REVIEW.md`
- Skill improvement ideas → `~/.claude/SKILL_RECOMMENDATIONS.md`
- Memory system → `~/.claude/MEMORY.md`
- Hooks → `~/.claude/HOOKS.md`
- Skill authoring (no-yolo) → `~/.claude/NO_YOLO.md`

---

## Maintenance Rules (Boris Cherny)

- If a rule above stops working, **nuke it and rewrite**. Do not preserve broken guidance.
- Review this file weekly. Trim, don't add.
- Keep concise. Project specifics belong in project CLAUDE.md.

---

## Caveman Mode

`~/.claude/hooks/caveman-*` scripts implement an opt-in terse mode (cuts tokens ~75%).
Toggle: `/caveman lite|full|ultra` or say "stop caveman" to disable.
Skill: `caveman:caveman`. State: `.caveman-active`.
Keep these scripts unless caveman mode is no longer wanted.
