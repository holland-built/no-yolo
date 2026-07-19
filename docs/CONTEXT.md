# Context Hygiene

## Token Budget Awareness

Claude's context window is its working memory: when it fills up, earlier messages get dropped. Managing tokens keeps your session sharp.

Global skills + hooks use ~30–40k tokens (chunks of text) before you type your first message. Be intentional about what loads.

Prefer **per-project** skill installs over global. Global skills bloat every session's prompt.

## Habits

- `/context` every ~20 minutes during long sessions.
- At 60% context full → `/compact focus on <module>` to trim history.
- `/statusline` to monitor context %, 5h limit %, 7d limit %.

## Scan delegation (hard rule, not advice)

- **≥5 read-only tool calls for one question → MUST delegate** to `caveman:cavecrew-investigator` (fallback `Explore`); report findings only. Under 5 → inline fine.
- Exceptions: user asks to watch live; sequential lookups (each depends on the last); skills that already dispatch their own agents.
- Why it's hard: soft "prefer subagents" advice sat here for weeks and changed nothing — inline grep waterfalls kept filling screens and context.
- For UI work, use text-based checks before screenshots — they're faster.

## Long-running work

*(These commands are harness/build-specific — not present in every Claude Code install. Skip silently if the command is unknown.)*

- `/branch` to fork the conversation when trying an experimental direction. *(if available in your harness)*
- `/teleport` to move cloud → local session. *(if available in your harness)*
- `/loop <interval> <cmd>` for repeated checks (cache TTL is 5 min — pick 60–270s or 1200s+, not 300s). *(if available in your harness)*

## Cache discipline

Anthropic caches your conversation for 5 minutes (prompt cache TTL = 5 min) to speed up responses; pause longer and the cache clears, so the next response is slower. When polling, either stay under 270s between checks or commit to 1200s+ — sleeps just past 300s pay the cache cost for nothing.
