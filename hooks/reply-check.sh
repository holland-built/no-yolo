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

# Rationalization check (idea from ECC's delivery-gate).
# These phrases are how work gets declared done without being done. The list is
# deliberately narrow: ECC warns rather than blocks here because loose regex
# false-positives. A phrase only counts when the reply offers no command as proof.
rat=$(printf '%s\n' "$prose" | grep -ioE "skip(ping)? (the )?tests? for now|pre-existing (bug|issue|failure)|should (work|be fine)|good enough for now|out of scope for this|will fix (that )?later|leaving that as is|assuming (this|that|it) works" | sort -u | head -3)
if [ -n "$rat" ] && ! printf '%s\n' "$msg" | grep -qE '^\s*(\$|>|`)?\s*(git|npm|node|python3|bash|jq|pytest|curl|ls|grep) '; then
  jq -n --arg p "$(printf '%s' "$rat" | tr '\n' ';')" \
    '{decision:"block", reason:("This reply excuses something without proving it: \"" + $p + "\". Either run the command that settles it and show the output, or say plainly that you did not check. Do not ship the excuse.")}'
  exit 0
fi

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
