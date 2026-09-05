#!/usr/bin/env bash
# Sends the plain-English rules in at the start of a session.
# A plugin cannot install a writing style file, so the rules go in as context.
# The rules and the check must say the same thing, or the check blocks replies
# the rules allowed. Change one, change the other.
set -uo pipefail

STYLE="${CLAUDE_PLUGIN_ROOT:-.}/output-styles/plain.md"
[ -f "$STYLE" ] || exit 0

# Drop the settings block at the top of the file. Keep the rules.
body=$(awk 'NR==1 && $0=="---" {inhead=1; next} inhead && $0=="---" {inhead=0; next} !inhead' "$STYLE")

# The reader's own word list wins. Ours is the fallback.
list="$HOME/.claude/CONTEXT.md"
[ -f "$list" ] || list="${CLAUDE_PLUGIN_ROOT:-.}/CONTEXT.md"
words=""
[ -f "$list" ] && words="

The word list below is live. The check reads it and blocks these words.

$(cat "$list")"

printf '%s' "$body$words" | jq -Rs '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: .
  }
}'
