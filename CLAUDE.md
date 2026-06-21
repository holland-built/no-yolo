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

---

## HARD RULE — This file is a pointer only

No content except file paths, this pointer table, and skill triggers.
If you are about to add anything else — STOP. Find or create the right MD file and point to it instead.

## Workflow

- Planning → `~/.claude/PLANNING.md`
- Testing → `~/.claude/TESTING.md`
- UI/GUI changes → `~/.claude/UI_MOCKUPS.md`
- Subagents + Agent Teams → `~/.claude/SUBAGENTS.md`
- Context hygiene → `~/.claude/CONTEXT.md`
- Skills & plugins → `~/.claude/SKILLS.md`
- Code review discipline → `~/.claude/CODE_REVIEW.md`
- Skill improvement ideas → `~/.claude/SKILL_RECOMMENDATIONS.md`
- Memory system → `~/.claude/MEMORY.md`
- Hooks → `~/.claude/HOOKS.md`

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
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
# code-health
- **code-health** (`~/.claude/skills/code-health/SKILL.md`) - three-phase codebase health pass: Fallow (all commands) → Ponytail → Improve. All output as tables. Trigger: `/code-health`
When the user types `/code-health`, invoke the Skill tool with `skill: "code-health"` before doing anything else.
# my-skills
- **my-skills** - list all skills you authored + curated. Trigger: `/my-skills`
When the user types `/my-skills`, invoke the Skill tool with `skill: "my-skills"` before doing anything else.
# ui-wild
- **ui-wild** (`~/.claude/skills/ui-wild/SKILL.md`) - radical UI/UX redesign: 10 Opus personas, judge pass kills AI slop, mockup approval gate, surgical code safety, regression gate. Trigger: `/ui-wild`
When the user types `/ui-wild`, says "go wild on the UI", "redesign this", "ui bananas", or "fresh design", invoke the Skill tool with `skill: "ui-wild"` before doing anything else.
# code-review
- **code-review** (`~/.claude/skills/code-review/SKILL.md`) - diff review with Karpathy surgical + simplicity filters. Trigger: `/code-review`
When the user types `/code-review`, invoke the Skill tool with `skill: "code-review"` before doing anything else.
# ui-ux
- **ui-ux** - design intelligence: 50+ styles, 161 palettes, 57 font pairings, 99 UX guidelines, 25 chart types across 10 stacks. Use for: plan/design/review/fix UI before or without code. Upstream of impeccable. Trigger: `/ui-ux`
When the user types `/ui-ux`, says "design this", "plan the UI", "review the UX", or asks about styles/palettes/typography choices, invoke the Skill tool with `skill: "ui-ux"` before doing anything else.
# impeccable
- **impeccable** (`~/.claude/skills/impeccable/SKILL.md`) - editorial-poster design theme: warm cream + burnt orange aesthetic for UI generation. Use when applying a premium, magazine-style visual brand. Trigger: `/impeccable`
When the user types `/impeccable` or asks for "editorial poster style", "warm cream design", "burnt orange aesthetic", invoke the Skill tool with `skill: "impeccable"` before doing anything else.
# my-md
- **my-md** (`~/.claude/skills/my-md/SKILL.md`) - list all markdown files: global ~/.claude/ docs + current project artifacts. Trigger: `/my-md`
When the user types `/my-md`, says "list md files", or "show markdown files", invoke the Skill tool with `skill: "my-md"` before doing anything else.
# quick-design
- **quick-design** (`~/.claude/skills/quick-design/SKILL.md`) - fast 3-variant mockup generator using real design tokens. Trigger: `/quick-design`
When the user types `/quick-design`, says "show me options", "mockup this", or "design options", invoke the Skill tool with `skill: "quick-design"` before doing anything else.
# whats-next
- **whats-next** (`~/.claude/skills/whats-next/SKILL.md`) - context scanner: shows in-flight work or clean-slate menu. Trigger: `/whats-next`
When the user types `/whats-next`, says "what's next", "what should I do", or "now what", invoke the Skill tool with `skill: "whats-next"` before doing anything else.
# eli5
- **eli5** (`~/.claude/skills/eli5/SKILL.md`) - explain anything in plain English before you commit to it. Trigger: `/eli5`
When the user types `/eli5`, invoke the Skill tool with `skill: "eli5"` before doing anything else.
# brief
- **brief** (`~/.claude/skills/brief/SKILL.md`) - 5-expert perspective framework for any topic: UI choices, wording decisions, research questions. Practitioner + Academic + Skeptic + Economist + Historian → contradiction map → synthesis → peer review. Trigger: `/brief`
When the user types `/brief`, says "debate this", "5 perspectives on", "stress test this decision", or "research brief on", invoke the Skill tool with `skill: "brief"` before doing anything else.
# update
- **update** (`~/.claude/skills/update/SKILL.md`) - check for updates, preview what changed, apply full or rules-only update, rollback, or restore a removed skill. Trigger: `/update`
When the user types `/update`, says "check for updates", "am I out of date", "what's new", "update my setup", or "rollback", invoke the Skill tool with `skill: "update"` before doing anything else.
