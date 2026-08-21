#!/usr/bin/env bash
# Reports machine-writing tells in a file that was just written or edited.
# Wired in settings.json as a PostToolUse hook on Write and Edit.
# Exit 2 returns the message to Claude, which fixes the file before continuing.
#
# Only patterns a program can decide are here. Judgement rules live in docs/PROSE.md,
# where a person applies them.
set -uo pipefail

f="$(jq -r '.tool_input.file_path // ""' 2>/dev/null)"
[ -z "$f" ] || [ ! -f "$f" ] && exit 0

case "$f" in
  *.md|*.txt|*.mdx) ;;
  *) exit 0 ;;
esac

findings=""

# The em-dash. A specimen inside backticks is allowed; prose is not.
dash=$(grep -n '—' "$f" 2>/dev/null | grep -v '`—`' || true)
[ -n "$dash" ] && findings="${findings}Long dash in prose. Use a full stop, a comma, or a colon:
${dash}
"

# Vocabulary, counted. One is nothing; three on a page is the signal.
vocab=$(grep -onEi '\b(elevate|seamless|unleash|tapestry|testament|holistic|meticulous(ly)?|nuanced|myriad|embark|unlock|underscore|showcasing)\b' "$f" 2>/dev/null || true)
n=$(printf '%s' "$vocab" | grep -c . || true)
[ "${n:-0}" -ge 3 ] && findings="${findings}${n} machine-vocabulary words. Say the specific thing instead:
${vocab}
"

# Sign-offs that add no next step.
cta=$(grep -nEi 'feel free to (ask|reach)|let me know if you (need|have)|don.t hesitate to' "$f" 2>/dev/null || true)
[ -n "$cta" ] && findings="${findings}Closing line with no next action. Name the action, or end:
${cta}
"

if [ -n "$findings" ]; then
  printf 'Writing check on %s\n\n%s\nRules: docs/PROSE.md\n' "$f" "$findings" >&2
  exit 2
fi

exit 0
