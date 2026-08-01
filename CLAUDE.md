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

Deliberately unloaded 2026-07-29 — see `~/.claude/docs/EXPERIMENT_CORE_RULES.md`
for what was done, why, and the exact steps to restore. The rules themselves are
kept at `docs/CORE_RULES.md.off`. Scheduled to finish 2026-08-28.

@docs/SKILL_TRIGGERS.md

---

## HARD RULE — This file is a pointer only

No content except file imports and the one-line, trigger-conditioned pointers below.
A skill's own `description` frontmatter already carries its triggers — never repeat them
here or in `docs/SKILL_TRIGGERS.md`, which is a routing rule and nothing else.

Each Workflow line names the condition that makes a doc relevant, then the doc. That shape
is deliberate: a bare `topic → file` arrow reads as a menu, and an 18-trial test on this
harness found it made sessions open all thirteen sibling docs at once, while the conditioned
form opened almost none. See `docs/EXPERIMENT_CORE_RULES.md`.

If you are about to add anything else — STOP. Find or create the right MD file and point to it.

## Workflow

- Before any multi-file change, new feature, or architecture decision, read `~/.claude/docs/PLANNING.md` and follow it.
- Before writing code for a bug fix or feature, read `~/.claude/docs/TESTING.md` and follow it.
- Before writing any UI/GUI code, read `~/.claude/docs/UI_MOCKUPS.md` and follow it.
- Before dispatching a subagent or building a multi-step plan, read `~/.claude/docs/SUBAGENTS.md` and follow it.
- When a session runs long, or one question needs 5+ read-only lookups, read `~/.claude/docs/CONTEXT.md` and follow it.
- Before finishing a `/health` pass or any diff review, read `~/.claude/docs/CODE_REVIEW.md` and follow it.
- When you learn a preference or fact worth keeping, read `~/.claude/docs/MEMORY.md` and save it the way it describes.
- If a hook fires unexpectedly, or you are asked about hook behaviour or output modes, read `~/.claude/docs/HOOKS.md` and follow it.
- When creating or editing a skill, read `~/.claude/docs/NO_YOLO.md` and follow it.
- When asked what is installed, or about plugins and third-party skills, read `~/.claude/docs/SKILLS.md`.
- If an MCP-dependent skill degrades or errors, or before installing an MCP server, read `~/.claude/docs/MCP_SERVICES.md` and follow it.
- Before explaining a concept this setup has already named, check `~/.claude/docs/CONTEXT_VOCAB.md` and use the existing name.
- When asked what to build next for the skill library itself, read `~/.claude/docs/SKILL_RECOMMENDATIONS.md`.

---

## Maintenance Rules (Boris Cherny)

- Keep concise. Project specifics belong in project CLAUDE.md.
- If a rule above stops working, nuke it and rewrite. Do not preserve broken guidance.
