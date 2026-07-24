<!-- GENERATED FROM ~/.claude/memory/facts/ — DO NOT EDIT. Run /memory-compile. -->
<!-- compiled 2026-07-24 -->
# Learned Preferences (compiled from curated memory)

Compiled from the fact store. Each line links its source fact.

## Working Preferences
- **Act like AI — don't parrot the ask or pad with fake/static filler** — The user's #1 recurring complaint across MCP + Wayfinder — AI myopically repeats the literal ask and adds made-up/static values to appease, instead of thinking. The fix is a proven 5-move recipe. ([feedback-act-like-ai-not-parrot](memory/facts/feedback-act-like-ai-not-parrot.md))
- **Challenge-by-default posture — propose-and-wait on substantive asks** — Reconciles rules 1/3/6/7/10 into one posture — on a substantive ask (change, complaint, direction, decision) AI proposes an alternative and WAITS instead of acting or asking bare permission; suppressed by /literal mode or an inline safeword. ([feedback-challenge-by-default](memory/facts/feedback-challenge-by-default.md))
- **eli5 output — plain, short, no jargon; chart only for status/options, one sentence for a simple ask** — Completion summaries, next actions, and questions to the user must be plain + short + zero jargon. Use a small chart/table only when showing what's done / what's left / options; use one plain sentence for a simple ask or reminder. Drop the mandatory "why" column. ([feedback-eli5-plain-short](memory/facts/feedback-eli5-plain-short.md))
- **Ship UI redesigns surface-by-surface into the real app, screenshot each** — For large UI redesigns, build one surface at a time straight into the running app and verify each in the browser before the next — don't iterate on abstract mockups/plans. ([feedback-realapp-incremental-ui](memory/facts/feedback-realapp-incremental-ui.md))
- **Delegate ≥5-lookup scans to a subagent** — When answering one question needs ≥5 read-only tool calls (Grep/Glob/Read/read-only Bash), dispatch cavecrew-investigator (or Explore) instead of running them inline — quiet screen, slower context growth ([pattern-delegate-scans-to-subagents](memory/facts/pattern-delegate-scans-to-subagents.md))
- **Auto-commit on push commands** — When the user says 'push to <branch>', auto-commit all local changes first (add, generate message, commit, push) without asking. ([user-auto-commit-on-push](memory/facts/user-auto-commit-on-push.md))
- **Bulleted/table output, never prose** — Default output is a bulleted list or markdown table; no long prose paragraphs. Code/commands in fenced blocks. ([user-output-format-bullets](memory/facts/user-output-format-bullets.md))
- **Single-paste prompts always** — When the user needs to run something, give ONE consolidated copy-paste block, never a numbered list of separate prompts/commands. ([user-single-paste-prompts](memory/facts/user-single-paste-prompts.md))
- **Always subagent-driven plan execution** — After writing any plan, immediately dispatch subagent-driven development; never ask 'inline or subagent', never offer inline. ([user-subagent-execution](memory/facts/user-subagent-execution.md))

## Patterns
- **Read target + imports before dispatching a file-modifying agent** — Before dispatching any agent that edits an existing file, the coordinator reads that file and its direct imports and writes an explicit 'already exists — do NOT recreate' section; cap agent output ~300 words. ([pattern-agent-read-before-dispatch](memory/facts/pattern-agent-read-before-dispatch.md))
- **Verify prompt/persona changes with a live test, not just desk review** — To confirm a prompt/persona/skill-behavior change actually works, dispatch the real agents and observe their output (live test) — static desk review finds structural issues but cannot prove behavior. Run desk review as a cheap pre-filter, then a live test to verify. ([pattern-live-test-over-desk-review](memory/facts/pattern-live-test-over-desk-review.md))
- **New skill creation checklist — 4 required steps** — Creating a skill requires 4 updates: SKILL.md with user-invocable true AND its triggers in that same description, catalog rows in my-skills, relock the catalog, delete any commands/ version if migrating ([pattern-new-skill-checklist](memory/facts/pattern-new-skill-checklist.md))

## Reference
- **Orca global Settings — what it actually contains** — What Orca (com.stablyai.orca) global Settings actually contains — don't invent toggles ([reference-orca-settings-surface](memory/facts/reference-orca-settings-surface.md))
- **KB-mined Claude Code best practices** — High-signal Claude Code rules mined from the Obsidian KB (Karpathy/Cherny/Kochel) not yet in the global MD chain — apply when relevant. ([user-kb-best-practices](memory/facts/user-kb-best-practices.md))

