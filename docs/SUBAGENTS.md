# Subagent Orchestration

## Model Split (Fable plans, Opus codes)

Always split by phase. A planning model writes the plan, separate agents build it. Never the same breath.

As of 2026-07-31 that split is Fable planning, Opus implementing. It used to read "Opus plans, Sonnet codes". The cheaper coding tier was dropped because the savings were not worth the rework.

Use model `fable` for planning agents, `opus` for every agent that writes code.

**Invocation triggers (auto-fire the planner):**
- User says "plan X" or "opusplan X"
- Any task meeting the "When to Plan" trigger in `~/.claude/docs/PLANNING.md`
- Any time you'd otherwise plan inline

## Before Dispatch

State assumptions and surface ambiguity in the dispatch prompt itself, never silently inside the agent.

## Scope per Dispatch

Every dispatch prompt must bound how much other code the change could break.
- Name the exact files the agent may touch; forbid edits outside them.
- Tell it to match existing style even where it would do otherwise.
- It may flag unrelated dead code but must not delete it; it must clean up only orphans (imports/vars) its own change made unused.

## When to delegate

- **Independent searches** across 2+ areas of the codebase → parallel `Explore` agents (max 3).
- **Tasks that bloat main context** with tool output → delegate (subagent returns a summary, not raw output).
- **Multi-perspective design decisions** → 2-3 `Plan` agents in parallel (model: `fable`). This line said `opus` until 2026-08-19, contradicting the split stated at the top of this file. Planning is Fable; only agents that write code are Opus.
- **Implementation of approved plans** → Opus subagents.

## When NOT to delegate

- Single known file edit → use Read/Edit directly.
- Trivial questions → answer from working memory.
- Tasks where you already have full context.

## The agents that actually exist

`~/.claude/agents/` holds **two** files, and that is the whole roster:

| Agent | Wired into | Dispatch it for |
|---|---|---|
| `accessibility-tester` | `/build`, at `skills/build/SKILL.md:547`, only when the change touches UI | WCAG audits, keyboard paths, screen-reader behaviour |
| `react-specialist` | nothing; you dispatch it by hand | React components built to a design that is already decided |

Everything else is a built-in: `Explore` for read-only fan-out searches, `Plan` for
implementation plans, `general-purpose` for the rest. Those need no file here.

> This section listed fifteen more agents until 2026-08-20: `debugger`, `code-reviewer`,
> `security-auditor`, `test-automator`, `typescript-pro` and the rest, a curated cut of the
> community subagents pack. **None of those files were ever in this repo.** The list was
> aspirational and read as inventory, so a session that followed it would dispatch a name
> that does not resolve. The same sentence also claimed `/build` dispatches `code-reviewer`
> and `security-auditor`; it dispatches neither, and never did. Checked by `ls agents/` and
> by grepping every skill for each name.
>
> **An agent is not free even when unused.** Every `description` in `agents/` is injected
> into the system prompt each session whether it is dispatched or not. Two files is a rounding
> error; a roster of seventeen was not. Add one only when a real dispatch wants it.

Rules: read target file + imports before dispatching a file-editing agent (cap output ~300 words). For 2+ independent tasks, run in parallel. Never serialize independent work.
