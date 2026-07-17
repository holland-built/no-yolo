# Subagent Orchestration

## Model Split (Opus plans, Sonnet codes)

Always split by phase — Opus (the bigger, slower Claude model) plans better; Sonnet (the faster one) is fast/cheap for execution.

Use model `opus` for planning agents, `sonnet` for coding agents.

**Invocation triggers (auto-fire Opus planner):**
- User says "plan X" or "opusplan X"
- Non-trivial task (multi-file, new feature, architecture decision)
- Any time you'd otherwise plan inline

## Before Dispatch (Rule: think before coding)

In every dispatch prompt:
- State assumptions explicitly — don't let the agent infer them silently.
- If the request has multiple valid interpretations, surface them and pick one out loud; never resolve ambiguity silently inside the agent.
- Push back in the plan if a simpler approach exists than the one requested.
- Name any confusion before delegating, not after the agent returns.

## Scope per Dispatch (Rule: only touch what you were asked to)

Every dispatch prompt must bound how much other code the change could break:
- Name the exact files the agent may touch; forbid edits outside them.
- Tell it to match existing style even where it would do otherwise.
- It may flag unrelated dead code but must not delete it; it must clean up only orphans (imports/vars) its own change made unused.
- Every changed line must trace to the request.

## When to delegate

- **Independent searches** across 2+ areas of the codebase → parallel `Explore` agents (max 3).
- **Tasks that bloat main context** with tool output → delegate (subagent returns a summary, not raw output).
- **Multi-perspective design decisions** → 2–3 `Plan` agents in parallel (model: "opus").
- **Implementation of approved plans** → Sonnet subagents.

## When NOT to delegate

- Single known file edit → use Read/Edit directly.
- Trivial questions → answer from working memory.
- Tasks where you already have full context.

## Daily-Driver Agents (in `~/.claude/agents/`)

Pre-built specialist agent definitions — each knows a specific domain.

> The `agents/` roster is a curated cut of the community subagents pack (VoltAgent-style definitions). Three are hard-wired into skills — `/build` dispatches `code-reviewer`, `security-auditor`, and `accessibility-tester` — the rest are an optional dispatch menu for the role tables below. Unused ones cost nothing at runtime; prune freely in your fork.

**Cross-cutting (use most days):**
- `debugger` — bug hunts (Karpathy "write a failing test")
- `code-reviewer` — PR gate
- `test-automator` — TDD scaffolding
- `refactoring-specialist` — dedup + cleanup
- `architect-reviewer` — high-level design review
- `security-auditor` — auth/payment/PII touches
- `prompt-engineer` — improve CLAUDE.md + skill prompts
- `qa-expert` — test strategy / quality audits

**<YOUR_STACK> (fill in your framework + language + database):**
- `react-specialist` / `typescript-pro`
- `python-pro` / `fastapi-developer` / `backend-developer`

**UI / quality:**
- `accessibility-tester` — a11y audits
- `performance-engineer` — perf hot spots
- `api-designer` — REST/GraphQL design
- `docker-expert` — containers

## Skill Alignment

- `build` — full feature pipeline (plan → Opus plan → TDD → build → prove)
- `review` — PR/diff review gate before merge
- `diagnose` — systematic bug diagnosis
- `tdd` — vertical-slice red-green-refactor

## Agent Teams (expert dispatch)

Agents that work well together. Dispatch the matching team in parallel. Build → review pairs: builder writes, reviewer verifies.

| Team | Build | Review / Verify | Use for | Model |
|---|---|---|---|---|
| **Frontend** | `react-specialist`, `typescript-pro` | `typescript-pro`, `accessibility-tester` | UI components, pages, mockup→dev | Sonnet |
| **Backend** | `backend-developer`, `typescript-pro` | `backend-developer`, `typescript-pro` | API routes, ORM, database | Sonnet |
| **Quality** | — | `code-reviewer`, `architect-reviewer`, `security-auditor` | pre-merge review, auth/secrets, system design | Opus |
| **Debug** | `debugger`, `performance-engineer` | `qa-expert` | bugs, regressions, perf bottlenecks | Sonnet |
| **Test** | `test-automator` | `qa-expert` | new test suites, coverage, CI gates | Haiku |

Rules: read target file + imports before dispatching a file-editing agent (cap output ~300 words). For 2+ independent tasks, run in parallel — never serialize independent work.
