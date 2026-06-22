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
# debate
- **debate** (`~/.claude/skills/debate/SKILL.md`) - 6-persona product-team debate: Senior Dev, Junior Dev, Sales Engineer, DevOps, Sales Leader, Eng Leader → contradiction map → synthesis → peer review. Works on architecture, UI/UX, or feature-priority calls. Trigger: `/debate`
When the user types `/debate`, says "debate this", "stress test this decision", "get the team on this", or "should we build this", invoke the Skill tool with `skill: "debate"` before doing anything else.
# update
- **update** (`~/.claude/skills/update/SKILL.md`) - check for updates, preview what changed, apply full or rules-only update, rollback, or restore a removed skill. Trigger: `/update`
When the user types `/update`, says "check for updates", "am I out of date", "what's new", "update my setup", or "rollback", invoke the Skill tool with `skill: "update"` before doing anything else.
# ship
- **ship** (`~/.claude/skills/ship/SKILL.md`) - quality gates (md-check + antislop + eli5, warn-only) → dated changelog → leak-guarded commit + push to no-yolo. Trigger: `/ship`
When the user types `/ship`, says "push skills", "publish to no-yolo", or "ship my work", invoke the Skill tool with `skill: "ship"` before doing anything else.
# skill-discovery
When the user says "find skill for X", "what skill handles X", "which skill does X", or "what should I use for X", read `~/.claude/skills/my-skills/TAGLINES.md`, match X against the taglines, and return the single best-matching skill plus its trigger command. This is a routing rule, not a skill — do not invoke the Skill tool.
# plan-feature
- **plan-feature** (`~/.claude/skills/plan-feature/SKILL.md`) - evidence → grill-me → Opus plan → approval gate; stops before any code. The no-code gate. Trigger: `/plan-feature`
When the user types `/plan-feature` or says "plan this feature", invoke the Skill tool with `skill: "plan-feature"` before doing anything else.
# build-feature
- **build-feature** (`~/.claude/skills/build-feature/SKILL.md`) - reads approved plan → mockup gate → TDD → build → regression → prove. Trigger: `/build-feature`
When the user types `/build-feature` or says "build the plan", invoke the Skill tool with `skill: "build-feature"` before doing anything else.
# debug-debate
- **debug-debate** (`~/.claude/skills/debug-debate/SKILL.md`) - 6 repo-aware Opus personas argue bug root causes → contradiction map → diagnosis + next diagnostic step. No fix — diagnosis only. Trigger: `/debug-debate`
When the user types `/debug-debate`, says "argue about this bug", "what's breaking and why", or "debate the bug", invoke the Skill tool with `skill: "debug-debate"` before doing anything else.
# last-30
- **last-30** (`~/.claude/skills/last-30/SKILL.md`) - pulls trending content from GitHub/HN/YouTube/X filtered to last 30 days only. Trigger: `/last-30`
When the user types `/last-30`, says "what's trending in", "last 30 days", or "what's hot right now", invoke the Skill tool with `skill: "last-30"` before doing anything else.
# md-check
- **md-check** (`~/.claude/skills/md-check/SKILL.md`) - MD hygiene: line counts, topic-overlap, duplicate-rule detection; on-demand audit or pre-creation gate. Trigger: `/md-check`
When the user types `/md-check`, says "check md files" or "md hygiene", invoke the Skill tool with `skill: "md-check"` before doing anything else.
# prompt-scan
- **prompt-scan** (`~/.claude/skills/prompt-scan/SKILL.md`) - reads all system prompt files + fetches current model release notes → appends dated section to ~/.claude/learnings.md. Feeds /better_prompt. Trigger: `/prompt-scan`
When the user types `/prompt-scan`, says "scan my prompts", or "refresh learnings", invoke the Skill tool with `skill: "prompt-scan"` before doing anything else.
# better_prompt
- **better_prompt** (`~/.claude/skills/better-prompt/SKILL.md`) - reads learnings.md, diagnoses a rough prompt, rewrites it with concrete target + scope + success criterion + correct skill route. Trigger: `/better_prompt`
When the user types `/better_prompt`, says "sharpen this prompt", or "improve my prompt", invoke the Skill tool with `skill: "better_prompt"` before doing anything else.
# antislop
- **antislop** (`~/.claude/skills/antislop/SKILL.md`) - diagnose AI writing/GUI slop tells against ANTISLOP.md; violations table + verdict, no rewrite. Trigger: `/antislop`
When the user types `/antislop`, says "check for slop", or "is this AI slop", invoke the Skill tool with `skill: "antislop"` before doing anything else.
