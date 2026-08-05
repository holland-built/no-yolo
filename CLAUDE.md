# Global Claude Code Instructions

Loads for every session, every project. Project-specific rules belong in that
project's own `CLAUDE.md`.

## Always loaded

@memory/CLAUDE.generated.md
@docs/CORE_RULES.md
@docs/ANTISLOP.md

> Three imports and no more. Learned preferences, the 8 rules that survived the
> 2026-07-29 experiment, and the slop list. Anti-slop is imported rather than pointed
> at because a pointer gets read after the writing has already started.

## Read these when the condition fires

- Before any multi-file change, new feature, or architecture decision → `docs/PLANNING.md`
- Before writing code for a bug fix or feature → `docs/TESTING.md`
- Before writing any UI or GUI code → `docs/UI_MOCKUPS.md`
- Before dispatching a subagent or building a multi-step plan → `docs/SUBAGENTS.md`
- When a session runs long, or one question needs 5+ read-only lookups → `docs/CONTEXT.md`
- Before finishing a `/health` pass or any diff review → `docs/CODE_REVIEW.md`
- When you learn a preference or fact worth keeping → `docs/MEMORY.md`
- If an outside service degrades, or before installing one → `docs/MCP_SERVICES.md`

The condition comes first, the file second. That shape is deliberate: a bare
`topic → file` arrow reads as a menu, and an 18-trial test on this harness found it
made sessions open every sibling doc at once, while this form opened almost none.

## Hard rules for this file

- Pointers and imports only, never rule text. If you are about to add a rule here,
  find the doc it belongs in and point at that instead.
- A skill's own `description` already carries its triggers. Never repeat them here.
- When the user types a skill's command, or says something matching its description,
  invoke that skill before doing anything else.
- If a rule above stops working, delete it and rewrite it. Do not preserve broken
  guidance, and do not keep a pointer to a doc nothing reads.
