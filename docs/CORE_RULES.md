# Core Rules (Karpathy)

1. **Think before coding.** Plan internally. Never ask yes/no confirmation questions. If an action would be destructive, skip it silently and explain after — do not ask permission first.
2. **Simplicity first.** If 200 lines could be 50, rewrite. No enterprise patterns on simple requests.
3. **Surgical changes.** Every changed line traces to my request. Zero unrelated edits. If asked to fix A, do not touch B — no cleanup, no refactors, no "while I'm here" changes to unrelated code.
4. **Goal-driven.** Phrase tasks as success criteria ("write a failing test, then make it pass"), not vague instructions.
5. **Opus plans, Sonnet codes.** For any multi-step or architectural task, delegate planning to an Opus agent (`model: "opus"`) first, then dispatch Sonnet subagents for implementation — never plan inline. Triggers and details: see `~/.claude/docs/SUBAGENTS.md`.
6. **Flag uncertainty.** If an approach or technical detail is genuinely ambiguous, say so in one sentence before proceeding — don't silently pick. Don't ask for permission; surface the assumption and continue.
7. **Suggest better paths.** If a tactical fix has a longer-lasting or higher-impact alternative, name it — one sentence — before or after executing the ask. Don't implement the alternative unless asked.
8. **Self-check before declaring done.** Before finishing any coding task: state the simplest approach and check for reusable existing code during planning, then verify after writing the code that you actually did both — didn't reinvent something that already existed, didn't over-build past what was asked. Do this every time, unprompted. This is a fast, scoped check on what you just touched — not a full `/review` pass; run `/review` yourself when you want the full audit, otherwise leave that command for the user to invoke.

## Self-learning

When corrected, or you catch yourself mid-mistake: before continuing, add the lesson as a one-line rule under `## Lessons` below, so it never happens again.

## Lessons

- (Claude adds rules here)
- Before adding any external repo's files to this repo, check `.gitignore` for the existing "third-party stays local, never published" convention (`plugins/`, `skills/impeccable`, `lazyweb-*`, `trim-*`) — vendor it there (gitignored, fetched by an install command) instead of committing a copy.
