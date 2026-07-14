# Hooks

Hook scripts in `~/.claude/hooks/` run automatically at harness events — things like session start, session end, or before a tool runs — configured in `settings.json`.

## Active hooks

- **caveman-activate.js** — activates caveman terse mode when toggled on.
- **caveman-config.js** — reads and applies caveman mode configuration.
- **caveman-mode-tracker.js** — tracks caveman mode state across messages.
- **caveman-stats.js** — reports token savings from caveman mode.
- **caveman-statusline.sh / .ps1** — shows caveman state in the status bar (cross-platform).
- **prompt-scan-nudge.js** — SessionStart; surfaces the model recorded in the last `/prompt-scan` so Claude can offer a re-scan if the current model differs.
- **lockstep-guard.js** — PreToolUse (Edit/Write/NotebookEdit); denies file mutation while `.lockstep-active` exists. Toggle: `/lockstep`.
- **statusline.sh** — displays context usage, your 5-hour usage limit, and your 7-day usage limit in the Claude Code status bar.

## Caveman mode

`caveman-*` scripts implement an opt-in terse output mode (cuts tokens ~75%).
Toggle: `/caveman lite|full|ultra` or say "stop caveman" to disable.
Skill: `caveman:caveman`. State: `.caveman-active`.

## Setup

```bash
# Make hooks executable after clone (also done by setup.sh)
chmod +x ~/.claude/hooks/*.sh
```

Hooks are wired in `settings.json` under the `hooks` key. Machine-specific — see `settings.example.json` for the template.
