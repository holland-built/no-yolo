# Context Hygiene

## Token Budget Awareness

Global skills + hooks burn ~30–40k tokens before the first message. Be intentional about what loads.

Prefer **per-project** skill installs over global. Global skills bloat every session's prompt.

## Habits

- `/context` every ~20 minutes during long sessions.
- At 60% context full → `/compact focus on <module>` to trim history.
- `/statusline` to monitor context %, 5h limit %, 7d limit %.

## When context is fragile

- Prefer `Explore` subagent over inline file reads when output is large.
- Delegate research to subagents — they return digests, not raw output.
- For UI work, prefer `preview_snapshot` (text) over `preview_screenshot` (heavier).

## Long-running work

*(These commands are harness/build-specific — not present in every Claude Code install. Skip silently if the command is unknown.)*

- `/branch` to fork the conversation when trying an experimental direction. *(if available in your harness)*
- `/teleport` to move cloud → local session. *(if available in your harness)*
- `/loop <interval> <cmd>` for repeated checks (cache TTL is 5 min — pick 60–270s or 1200s+, not 300s). *(if available in your harness)*

## Cache discipline

Anthropic prompt cache TTL = 5 min. Long sleeps past 300s lose cache. When polling, either stay under 270s or commit to 1200s+ between checks.
