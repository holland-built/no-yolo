#!/bin/bash
# Stop hook: block a reply that is too long OR too dense to read.
#
# Length alone was the wrong measure. A previous version of this passed a reply
# on word count while the reply named ten files and commits and was unreadable.
# So this counts two things: prose lines, and distinct named things (paths,
# commands, repos) outside code blocks.
#
# Fails open: any missing input, bad JSON, or absent jq lets the turn through.
# A guard that blocks on its own bug is worse than no guard.

in=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Never block twice on one turn: the rewrite must be allowed to land.
[ "$(printf '%s' "$in" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0

msg=$(printf '%s' "$in" | jq -r '.last_assistant_message // ""' 2>/dev/null)
[ -z "$msg" ] && exit 0

# Prose only: drop fenced code blocks and blank lines. Code is free.
prose=$(printf '%s\n' "$msg" | awk '/^[[:space:]]*```/{f=!f;next} !f')
lines=$(printf '%s\n' "$prose" | grep -c '[^[:space:]]')

# Density: distinct backticked things and bare paths in the prose.
named=$(printf '%s\n' "$prose" \
  | grep -oE '`[^`]+`|\b[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+\b' \
  | sort -u | grep -c . )

max_lines=${REPLY_MAX_LINES:-15}
max_named=${REPLY_MAX_NAMED:-6}

reason=""
[ "$lines" -gt "$max_lines" ] && reason="$lines prose lines (limit $max_lines)"
if [ "$named" -gt "$max_named" ]; then
  [ -n "$reason" ] && reason="$reason and "
  reason="${reason}$named distinct named things (limit $max_named)"
fi
[ -z "$reason" ] && exit 0

jq -n --arg r "Reply is $reason. Rewrite it: answer first, one table, cut the working. Put the extra named files in one place and name it once. Code blocks are free." \
  '{decision:"block", reason:$r}'
