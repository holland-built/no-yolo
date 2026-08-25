#!/bin/bash
# Contract for hooks/reply-shape.sh, the Stop gate on reply length.
# Run: bash hooks/tests/reply-shape.test.sh
#
# THE CASES THAT MATTER ARE THE FALSE POSITIVES. A gate that fires on every turn and blocks a
# legitimate long answer is worse than no gate, because the owner cannot get past it and it
# gets switched off within a day. So the escapes get more cases than the block does: a long
# table, a long code block, the explicit marker, and every shape of unusable input.
#
# EXIT CODES. 0 lets the turn end. 2 blocks it and prints the reason on stderr. There is no
# third code: anything the hook cannot read is a 0, deliberately.
#
# BASH-3.2 CLEAN (stock macOS).
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO/hooks/reply-shape.sh"

fail=0
results=""
check() {  # $1 description, $2 expected, $3 actual
  if [ "$2" = "$3" ]; then
    results="$results
PASS|$1"
  else
    results="$results
FAIL|$1 (expected $2, got $3)"
    fail=1
  fi
}

# Build a JSON payload holding a reply of $1 words, with $2 appended verbatim.
make_payload() {  # $1 word count, $2 suffix
  n="$1"; suffix="${2:-}"
  body=""
  i=0
  while [ "$i" -lt "$n" ]; do
    body="$body word"
    i=$((i + 1))
  done
  printf '{"last_assistant_message":"%s%s"}' "$body" "$suffix"
}

run() {  # stdin payload -> exit code
  printf '%s' "$1" | bash "$HOOK" >/dev/null 2>&1
  printf '%s' "$?"
}

# --- blocks ---
check "200 plain words blocks"            2 "$(run "$(make_payload 200)")"
check "601 words with a table blocks"     2 "$(run "$(make_payload 601 ' |---|')")"

# --- passes, under the cap ---
check "20 plain words passes"             0 "$(run "$(make_payload 20)")"
check "exactly 150 words passes"          0 "$(run "$(make_payload 150)")"

# --- passes, escapes. These are the false-positive guards. ---
check "300 words with a table passes"     0 "$(run "$(make_payload 300 ' |---|')")"
FENCE="$(printf '%s' '```')"
check "300 words with a code fence passes" 0 "$(run "$(make_payload 300 " ${FENCE}sh")")"
check "300 words with <!-- long --> passes" 0 "$(run "$(make_payload 300 ' <!-- long -->')")"

# --- fails open on anything unreadable ---
check "empty stdin passes"                0 "$(run '')"
check "malformed json passes"             0 "$(run 'not json at all')"
check "json without the key passes"       0 "$(run '{"other":"value"}')"
check "empty reply passes"                0 "$(run '{"last_assistant_message":""}')"

# --- the JSON-newline undercount, found by Codex at the review gate ---
# A reply arrives JSON-encoded, so a line break is the two characters backslash and n. Left
# undecoded they glue words together: 200 words on 200 lines counted as ONE and sailed past a
# 150-word cap. Every real multi-line reply was effectively unchecked.
nl_body=""
i=0
while [ "$i" -lt 200 ]; do nl_body="${nl_body}word\\n"; i=$((i + 1)); done
check "200 words split over 200 lines blocks" 2 \
  "$(run "$(printf '{"last_assistant_message":"%s"}' "$nl_body")")"
check "10 words over 4 lines still passes" 0 \
  "$(run '{"last_assistant_message":"one\ntwo\nthree\nfour five six seven eight nine ten"}')"

# --- a hostile cap must not wave a reply through ---
check "non-numeric REPLY_SOFT_CAP falls back and still blocks" 2 \
  "$(printf '%s' "$(make_payload 200)" | REPLY_SOFT_CAP=abc bash "$HOOK" >/dev/null 2>&1; printf '%s' "$?")"

# --- reads the alternate key names the harness has used ---
check "assistant_response key is read"    2 "$(run "$(printf '{"assistant_response":"%s"}' "$(make_payload 200 | sed 's/.*message":"//; s/"}$//')")")"

printf '%s\n' "$results" | grep -v '^$'
if [ "$fail" -eq 0 ]; then
  printf '\nreply-shape: all cases pass\n'
else
  printf '\nreply-shape: FAILURES above\n'
fi
exit "$fail"
