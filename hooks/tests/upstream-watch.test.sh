#!/bin/bash
# Contract for hooks/upstream-watch.sh, the session-start check on borrowed content.
# Run: bash hooks/tests/upstream-watch.test.sh
#
# THE ONLY THING THAT MUST NEVER HAPPEN IS A SLOW OR FAILING SESSION START. Every case below
# asserts the same two properties: exit 0, and returns fast. A watcher that stalls the first
# prompt or errors on a plane gets switched off, and then it watches nothing. Correctness of
# the fetch is secondary to that, and the fetch is deliberately in a detached child so its
# failure cannot reach the parent.
#
# EACH CASE RUNS AGAINST ITS OWN THROWAWAY CLAUDE_CONFIG_DIR. The hook writes state, and a
# suite that shared the real config would leave the owner's daily stamp burned.
#
# BASH-3.2 CLEAN (stock macOS).
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO/hooks/upstream-watch.sh"

fail=0
results=""
upstream_expect() {  # $1 description, $2 expected, $3 actual
  if [ "$2" = "$3" ]; then
    results="$results
PASS|$1"
  else
    results="$results
FAIL|$1 (expected $2, got $3)"
    fail=1
  fi
}

box() { mktemp -d "${TMPDIR:-/tmp}/upstream-watch.XXXXXX"; }

# 1. Empty config: no BORROWED.md, no state. Must still exit 0.
d="$(box)"
CLAUDE_CONFIG_DIR="$d" bash "$HOOK" >/dev/null 2>&1
upstream_expect "empty config exits 0" 0 "$?"
upstream_expect "creates its state directory" 0 "$([ -d "$d/.upstream" ] && echo 0 || echo 1)"
upstream_expect "writes today's stamp" 0 "$([ -s "$d/.upstream/last-run" ] && echo 0 || echo 1)"
rm -rf "$d"

# 2. A report left by a previous run is printed, then cleared, so it shows once only.
d="$(box)"; mkdir -p "$d/.upstream"
printf '## Upstream check\n- thing moved\n' > "$d/.upstream/report.md"
got="$(CLAUDE_CONFIG_DIR="$d" bash "$HOOK" 2>/dev/null | grep -c 'thing moved')"
upstream_expect "an existing report is printed" 1 "$got"
upstream_expect "the report is cleared after printing" 1 "$([ -f "$d/.upstream/report.md" ] && echo 0 || echo 1)"
rm -rf "$d"

# 3. Throttle: a second run on the same day does no work and prints nothing.
d="$(box)"; mkdir -p "$d/.upstream"
printf '%s' "$(date +%Y-%m-%d)" > "$d/.upstream/last-run"
out="$(CLAUDE_CONFIG_DIR="$d" bash "$HOOK" 2>/dev/null)"
upstream_expect "throttled run is silent" "" "$out"
upstream_expect "throttled run exits 0" 0 "$?"
rm -rf "$d"

# 4. Speed. The parent must return promptly whatever the network is doing, because the fetch
#    is detached. Two seconds is generous; the real figure is milliseconds.
d="$(box)"
start="$(date +%s)"
CLAUDE_CONFIG_DIR="$d" bash "$HOOK" >/dev/null 2>&1
elapsed=$(( $(date +%s) - start ))
upstream_expect "returns in under 3 seconds" 0 "$([ "$elapsed" -lt 3 ] && echo 0 || echo 1)"
rm -rf "$d"

# 5. A BORROWED.md with no pinned rows must not error.
d="$(box)"; mkdir -p "$d/docs"
printf '# Borrowed\n\n| Name | Where |\n|---|---|\n| a thing | installed by hand |\n' > "$d/docs/BORROWED.md"
CLAUDE_CONFIG_DIR="$d" bash "$HOOK" >/dev/null 2>&1
upstream_expect "unpinned rows exit 0" 0 "$?"
rm -rf "$d"

# 6. The portable time bound. `timeout` is GNU coreutils and is absent from a stock Mac:
#    neither it nor `gtimeout` was on the machine this was written on, so the original code
#    silently produced no result on every call while claiming to be bounded. Codex found it at
#    the review gate. This asserts the replacement actually cuts a long command short.
#    The function is EXTRACTED from the hook rather than copied into this file. A copy drifts,
#    and then the suite proves a private duplicate works while the shipped one rots.
fn="$(sed -n '/^bounded() {/,/^}/p' "$HOOK")"
upstream_expect "bounded() is extractable from the hook" 0 "$([ -n "$fn" ] && echo 0 || echo 1)"
start="$(date +%s)"
bounded_rc="$(bash -c "$fn
  bounded 2 sleep 30; printf '%s' \"\$?\"" 2>/dev/null)"
bounded_elapsed=$(( $(date +%s) - start ))
upstream_expect "bounded cuts a 30s command short" 0 "$([ "$bounded_elapsed" -lt 8 ] && echo 0 || echo 1)"
upstream_expect "bounded reports the kill, not success" 0 "$([ "$bounded_rc" != "0" ] && echo 0 || echo 1)"
upstream_expect "the hook no longer calls GNU timeout" 0 \
  "$(grep -qE '(^|[^_[:alnum:]])timeout ' "$HOOK" && echo 1 || echo 0)"

# 7. An unwritable state directory must not take the session down.
d="$(box)"; mkdir -p "$d/.upstream"; chmod 500 "$d/.upstream" 2>/dev/null
CLAUDE_CONFIG_DIR="$d" bash "$HOOK" >/dev/null 2>&1
upstream_expect "unwritable state exits 0" 0 "$?"
chmod 700 "$d/.upstream" 2>/dev/null; rm -rf "$d"

printf '%s\n' "$results" | grep -v '^$'
if [ "$fail" -eq 0 ]; then
  printf '\nupstream-watch: all cases pass\n'
else
  printf '\nupstream-watch: FAILURES above\n'
fi
exit "$fail"
