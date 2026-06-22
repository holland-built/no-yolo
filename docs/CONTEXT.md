# Context Hygiene

## Token Budget Awareness

Claude has a context window — think of it like working memory. When it fills up, earlier messages get dropped. Managing tokens keeps your session sharp.

Global skills + hooks use ~30–40k tokens (chunks of text) before you type your first message. Be intentional about what loads.

Prefer **per-project** skill installs over global. Global skills bloat every session's prompt.

## Habits

- `/context` every ~20 minutes during long sessions.
- At 60% context full → `/compact focus on <module>` to trim history.
- `/statusline` to monitor context %, 5h limit %, 7d limit %.

## When context is fragile

- Prefer `Explore` subagent over inline file reads when output is large.
- Delegate research to subagents — they return digests, not raw output.
- For UI work, use text-based checks before screenshots — they're faster.

## Long-running work

*(These commands are harness/build-specific — not present in every Claude Code install. Skip silently if the command is unknown.)*

- `/branch` to fork the conversation when trying an experimental direction. *(if available in your harness)*
- `/teleport` to move cloud → local session. *(if available in your harness)*
- `/loop <interval> <cmd>` for repeated checks (cache TTL is 5 min — pick 60–270s or 1200s+, not 300s). *(if available in your harness)*

## Cache discipline

Anthropic saves (caches) your conversation for 5 minutes to speed up responses. If you pause longer than that, the cache clears and the next response is slower.

Anthropic prompt cache TTL = 5 min. Long sleeps past 300s lose cache. When polling, either stay under 270s or commit to 1200s+ between checks.
