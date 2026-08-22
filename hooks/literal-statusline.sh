#!/usr/bin/env bash
# Draws the [LITERAL] badge when literal mode is on, and nothing otherwise.
# hooks/statusline.sh runs this on every repaint and prepends whatever it prints.
#
# Rewritten from a blank page 2026-08-22 (machinery rebuild). The contract is
# hooks/tests/literal-statusline.test.sh, which predates this text.
#
# The mode's state is one thing only: a REGULAR FILE existing at the flag path.
# hooks/literal-mode-tracker.js creates and removes it; nothing ever reads its
# contents. That is why the test below is `-f` behind an explicit symlink
# refusal, not `-e`:
#   - a SYMLINK planted at the predictable path is rejected before anything
#     else. This script runs on every keystroke; one that followed the link
#     would render the target's bytes — escape sequences included — into the
#     terminal forever.
#   - a DIRECTORY at the path fails `-f` and prints nothing, rather than
#     erroring under the prompt on every repaint.
#
# CLAUDE_CONFIG_DIR wins over $HOME/.claude so a second profile reads its own
# mode, never the personal profile's.

FLAG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.literal-active"

if [ ! -L "$FLAG" ] && [ -f "$FLAG" ]; then
  printf '\033[38;5;44m[LITERAL]\033[0m'
fi
exit 0
