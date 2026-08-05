#!/usr/bin/env bash
# literal — statusline badge script for Claude Code
# Reads the literal mode flag file and outputs a colored badge.
#
# Usage in ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "bash /path/to/literal-statusline.sh" }
#
# Plugin users: Claude will offer to set this up on first session.
# Standalone users: install.sh wires this automatically.

FLAG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.literal-active"

# Refuse symlinks — a local attacker could point the flag at ~/.ssh/id_rsa and
# have the statusline render its bytes (including ANSI escape sequences) to
# the terminal every keystroke.
[ -L "$FLAG" ] && exit 0
[ ! -f "$FLAG" ] && exit 0

printf '\033[38;5;44m[LITERAL]\033[0m'
