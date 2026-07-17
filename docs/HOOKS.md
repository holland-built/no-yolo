# Hooks

Hook scripts in `~/.claude/hooks/` run automatically at harness events (session start, session end, before a tool runs). They are wired in `settings.json` under the `hooks` key — machine-specific; see `settings.example.json` for the template.

## Active hooks

- **caveman-activate.js** — activates caveman terse mode when toggled on.
- **caveman-mode-tracker.js** — tracks caveman mode state across messages.
- **caveman-statusline.sh / .ps1** — shows caveman state in the status bar (cross-platform).
- **prompt-scan-nudge.js** — SessionStart; surfaces the model recorded in the last `/prompt-scan` so Claude can offer a re-scan if the current model differs.
- **lockstep-guard.js** — PreToolUse (Edit/Write/NotebookEdit); denies file mutation while `.lockstep-active` exists. Toggle: `/lockstep`.
- **worktree-autoarm.js** — SessionStart; arms the worktree guard when a session opens inside a linked git worktree, and prunes stale flags for deleted worktrees.
- **worktree-guard.js** — PreToolUse (Edit/Write/NotebookEdit); once a worktree is armed for a repo, denies edits to that repo's main checkout outside the active worktree.
- **statusline.sh** — displays context usage, your 5-hour usage limit, and your 7-day usage limit in the Claude Code status bar.

Helpers (not event-wired): caveman-config.js, caveman-stats.js — invoked by the caveman scripts/skills.

## Caveman mode

`caveman-*` scripts implement an opt-in terse output mode (cuts tokens ~75%).
Toggle: `/caveman lite|full|ultra` or say "stop caveman" to disable.
Skill: `caveman:caveman`. State: `.caveman-active`.

## Setup

```bash
# Make hooks executable after clone (also done by setup.sh)
chmod +x ~/.claude/hooks/*.sh
```

Deeper module reference → [HOOKS_INTERNALS.md](HOOKS_INTERNALS.md).
