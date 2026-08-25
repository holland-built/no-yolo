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

# ── gate two: how many things the reader has to hold ────────────────────────
# Added 2026-08-25, after a session of replies that every one of them PASSED the word count
# and drew "I still cant understand a damn thing". The cap is three, measured against five real
# replies from that session: the unreadable one named ten, the two readable ones named none and
# one, and a reply whose commands sat in a fenced block named none.
#
# THE FALSE POSITIVES MATTER MORE THAN THE BLOCK, as everywhere else in this file. A gate that
# fires on a legitimate answer gets switched off within a day, and this one fires on the shape
# of ordinary technical writing, so it gets the larger share of the cases below.
#
# THE FIXTURES CARRY A REAL BACKTICK. The first draft of these cases wrote it as \` inside the
# payload, which no real payload contains: a backtick needs no escaping in JSON. The stray
# backslash rode along into the token, so `four.json\` failed the extension test and two cases
# reported a count of three where a reader would have seen five. The fixture was wrong, not the
# hook, but the hook now strips a stray escape anyway.
BT='`'
say() {  # $1 body -> a payload carrying it verbatim
  printf '{"last_assistant_message":"%s"}' "$1"
}

# --- blocks: more distinct things than a reader can hold ---
check "five backticked file paths blocks" 2 \
  "$(run "$(say "See ${BT}alpha/one.sh${BT} and ${BT}beta/two.sh${BT} and ${BT}gamma/three.md${BT} and ${BT}four.json${BT} and ${BT}five.yml${BT} now.")")"

# A line number is part of the reference, not a second reference.
check "a path with a line number counts once" 2 \
  "$(run "$(say "Look at ${BT}a/one.sh:12${BT} ${BT}b/two.sh:3${BT} ${BT}c/three.md:9${BT} ${BT}d/four.json:1${BT} and ${BT}e/five.yml:7${BT} here.")")"

# --- passes: at or under the cap ---
check "three file paths passes"           0 \
  "$(run "$(say "See ${BT}alpha/one.sh${BT} and ${BT}delta/two.md${BT} and ${BT}three.json${BT} for the detail.")")"
check "the same file named five times counts once" 0 \
  "$(run "$(say "In ${BT}verify.sh${BT}, ${BT}verify.sh${BT}, ${BT}verify.sh${BT}, ${BT}verify.sh${BT} and ${BT}verify.sh${BT} again.")")"
check "prose naming no files at all passes" 0 \
  "$(run "$(say "You threw out a design tool. Two pieces of it were still on your computer.")")"

# THE HEX WORDS. The first draft counted any bare seven-to-forty character hex word, to catch a
# commit id written without backticks. Codex found that "defaced" is seven characters and every
# one of them is a hex digit; so are "facade", "decade" and "beaded". Backticks are required.
check "ordinary English hex-looking words pass" 0 \
  "$(run "$(say "The wall was defaced, the facade took a decade, and the trim was beaded.")")"
check "four backticked commit ids block"  2 \
  "$(run "$(say "Compare ${BT}be7ff1a${BT} with ${BT}63f687d${BT} and ${BT}c222cd9${BT} and ${BT}f36e765${BT} before deciding.")")"

# --- fenced code is removed before counting, not exempted ---
# Five paths INSIDE a fence and one outside. Only the one counts, so this passes. The old
# design exempted the whole reply on seeing a fence, which left the prose around a code block
# unchecked entirely.
FENCED_FIVE="Run this:\\n\`\`\`bash\\ncat alpha/a.sh beta/b.sh gamma/c.md d.json e.yml\\n\`\`\`\\nThat updates ${BT}your-settings.json${BT} only."
check "paths inside a fence are not counted" 0 "$(run "$(say "$FENCED_FIVE")")"

# The prose OUTSIDE a fence is still counted, which is the whole point of removing rather than
# exempting.
FENCED_PROSE="Touching ${BT}a/one.sh${BT} ${BT}b/two.sh${BT} ${BT}c/three.md${BT} ${BT}d/four.json${BT} ${BT}e/five.yml${BT}.\\n\`\`\`bash\\necho hello\\n\`\`\`"
check "paths outside a fence still count"  2 "$(run "$(say "$FENCED_PROSE")")"

# An unclosed fence swallowed the rest of the reply, so the count cannot be trusted and the
# gate stands down rather than guessing.
UNCLOSED="Look at ${BT}a/one.sh${BT} ${BT}b/two.sh${BT} ${BT}c/three.md${BT} ${BT}d/four.json${BT} ${BT}e/five.yml${BT}.\\n\`\`\`bash\\nnever closed"
check "an unclosed fence fails open"       0 "$(run "$(say "$UNCLOSED")")"

# --- the escapes are NOT shared between the two gates ---
# A code fence exempts LENGTH. It must not exempt references, or one fenced block switches off
# both gates at once, which is what the first draft did.
FIVE="${BT}a/one.sh${BT} ${BT}b/two.sh${BT} ${BT}c/three.md${BT} ${BT}d/four.json${BT} ${BT}e/five.yml${BT}"
check "<!-- terms --> exempts the reference gate" 0 \
  "$(run "$(say "Five: $FIVE <!-- terms -->")")"
check "<!-- long --> does NOT exempt the reference gate" 2 \
  "$(run "$(say "Five: $FIVE <!-- long -->")")"
check "a table does NOT exempt the reference gate" 2 \
  "$(run "$(say "|---| $FIVE")")"

# --- both gates failing report together, and still exit 2 once ---
LONGREF=""
i=0
while [ "$i" -lt 200 ]; do LONGREF="$LONGREF word"; i=$((i + 1)); done
BOTH_PAYLOAD="$(say "$LONGREF $FIVE")"
check "a reply failing both gates exits 2" 2 "$(run "$BOTH_PAYLOAD")"
both_out="$(printf '%s' "$BOTH_PAYLOAD" | bash "$HOOK" 2>&1 >/dev/null)"
both_len=0; both_ref=0
case "$both_out" in *"words against"*) both_len=1 ;; esac
case "$both_out" in *"different files"*) both_ref=1 ;; esac
check "the length reason is printed"       1 "$both_len"
check "the reference reason is printed too" 1 "$both_ref"

# --- a hostile cap must not wave a reply through ---
check "non-numeric REPLY_REF_CAP falls back and still blocks" 2 \
  "$(printf '%s' "$(say "Five: $FIVE")" | REPLY_REF_CAP=abc bash "$HOOK" >/dev/null 2>&1; printf '%s' "$?")"

printf '%s\n' "$results" | grep -v '^$'
if [ "$fail" -eq 0 ]; then
  printf '\nreply-shape: all cases pass\n'
else
  printf '\nreply-shape: FAILURES above\n'
fi
exit "$fail"
