#!/bin/bash
# Stop hook — every N user turns, inject reminder to run /log
# Tracks turn count in ~/.claude/.learnings-turn-counter

set -euo pipefail

COUNTER_FILE="$HOME/.claude/.learnings-turn-counter"
THRESHOLD=15

# Read current count (default 0)
count=0
if [ -f "$COUNTER_FILE" ]; then
  count=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
fi

# Increment
count=$((count + 1))

if [ "$count" -ge "$THRESHOLD" ]; then
  # Reset counter
  echo 0 > "$COUNTER_FILE"

  # Inject reminder into Claude's context for next turn
  cat <<EOF
{
  "additionalContext": "Reminder from auto-log-learnings hook: $THRESHOLD turns have passed since last learnings flush. If the recent conversation contained corrections, run /log to append them to the relevant skill learnings.md files before continuing."
}
EOF
else
  # Save updated count
  echo "$count" > "$COUNTER_FILE"
  # No context injection
  echo "{}"
fi

exit 0
