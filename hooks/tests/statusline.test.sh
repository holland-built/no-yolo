#!/bin/bash
# Tests for hooks/statusline.sh — the line at the bottom of every session.
# Run: bash hooks/tests/statusline.test.sh
#
# It runs on every turn and its output is decoration, so a failure is invisible:
# a blank bar and a stack trace on stderr look much the same to whoever is
# reading their own code. These assert the two things that actually matter, that
# it never fails and never hangs, and then that it reads what it claims to read.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO/hooks/statusline.sh"

fail=0
pass=0

# Feed JSON in, capture stdout only. stderr is checked separately where it matters.
run() { printf '%s' "$1" | bash "$HOOK" 2>/dev/null; }

contains() {
  local desc="$1" needle="$2" hay="$3"
  case "$hay" in
    *"$needle"*) pass=$((pass + 1)) ;;
    *) echo "FAIL: $desc — [$needle] missing from [$hay]"; fail=1 ;;
  esac
}

exits_zero() {
  local desc="$1" input="$2"
  printf '%s' "$input" | bash "$HOOK" >/dev/null 2>&1
  if [ $? = 0 ]; then pass=$((pass + 1)); else echo "FAIL: $desc — exited nonzero"; fail=1; fi
}

FULL='{"workspace":{"current_dir":"/tmp"},"model":{"id":"claude-opus-5","display_name":"Opus 5"},
"context_window":{"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":18},
"seven_day":{"used_percentage":40}},"effort":{"level":"high"}}'

# 1. The pieces the README documents are the pieces it draws.
out="$(run "$FULL")"
contains "model name is shown"      "Opus 5" "$out"
contains "reasoning effort is shown" "high"  "$out"
contains "context percentage is shown" "42%ctx" "$out"
contains "5-hour allowance is shown"   "5h 18%" "$out"
contains "7-day allowance is shown"    "wk 40%" "$out"
contains "folder name is shown"        "tmp"    "$out"

# 2. Malformed input must still draw a bar. The python fallback exists for this,
#    and a bar that vanishes on one bad frame is how a broken statusline hides.
exits_zero "malformed JSON exits 0" 'not json at all'
out="$(run 'not json at all')"
contains "malformed JSON still names a model" "Claude" "$out"

# 3. Empty input, the shape seen when the harness sends nothing during startup.
exits_zero "empty input exits 0" ''

# 4. Missing keys, one at a time. Each optional segment is guarded by a test for
#    emptiness, so an absent key drops its segment rather than printing a stray
#    separator or the word null.
out="$(run '{"model":{"display_name":"Opus 5"}}')"
exits_zero "JSON with only a model exits 0" '{"model":{"display_name":"Opus 5"}}'
case "$out" in
  *null*|*None*) echo "FAIL: a missing key printed as null/None — [$out]"; fail=1 ;;
  *) pass=$((pass + 1)) ;;
esac

# 5. A directory with a space in it. The parser joins fields with \x1f rather than
#    whitespace precisely so this survives; a space-delimited version truncates here.
out="$(run '{"workspace":{"current_dir":"/tmp/two words"},"model":{"display_name":"Opus 5"}}')"
contains "a path with a space keeps its whole basename" "two words" "$out"

# 6. It never blocks. The statusline is called on every turn, so a script that
#    waits on stdin or on a network call stalls the session rather than the bar.
if command -v perl >/dev/null 2>&1; then
  start=$(perl -MTime::HiRes=time -e 'print int(time*1000)')
  run "$FULL" >/dev/null
  elapsed=$(( $(perl -MTime::HiRes=time -e 'print int(time*1000)') - start ))
  if [ "$elapsed" -lt 5000 ]; then pass=$((pass + 1))
  else echo "FAIL: statusline took ${elapsed}ms, over the 5s budget"; fail=1; fi
fi

# 7. Nothing is written to stderr on the ordinary path. Noise here is printed
#    under the prompt on every turn and is the failure mode nobody reports.
err="$(printf '%s' "$FULL" | bash "$HOOK" 2>&1 >/dev/null)"
if [ -z "$err" ]; then pass=$((pass + 1))
else echo "FAIL: stderr was not empty on valid input — [$err]"; fail=1; fi

# 8. The badge script is found beside this one, not under $HOME.
#    The path was hardcoded to $HOME/.claude/hooks/ until 2026-08-21. That was
#    survivable while both directories existed, because the badge script reads
#    CLAUDE_CONFIG_DIR itself and returned the right answer whichever copy ran.
#    It failed only where $HOME/.claude is absent, an install that lives entirely
#    under a second profile: the badge then vanished for a session that had the
#    mode on, with nothing on stderr. That is the case asserted here, so HOME is
#    pointed somewhere empty. A version that hardcodes $HOME cannot pass it.
PROF="$(mktemp -d)"; EMPTY="$(mktemp -d)"
trap 'rm -rf "$PROF" "$EMPTY"' EXIT

: > "$PROF/.literal-active"
out="$(printf '%s' "$FULL" | HOME="$EMPTY" CLAUDE_CONFIG_DIR="$PROF" bash "$HOOK" 2>/dev/null)"
contains "badge still drawn when \$HOME/.claude does not exist" "LITERAL" "$out"

rm -f "$PROF/.literal-active"
out="$(printf '%s' "$FULL" | HOME="$EMPTY" CLAUDE_CONFIG_DIR="$PROF" bash "$HOOK" 2>/dev/null)"
case "$out" in
  *LITERAL*) echo "FAIL: badge shown for a profile with literal mode off"; fail=1 ;;
  *) pass=$((pass + 1)) ;;
esac

if [ "$fail" = 0 ]; then
  echo "statusline: $pass checks passed"
else
  echo "statusline: FAILURES above"
fi
exit "$fail"
