#!/bin/bash
# Tests for hooks/literal-statusline.sh — the badge the status bar draws when
# literal mode is on.
# Run: bash hooks/tests/literal-statusline.test.sh
#
# This script had no test until 2026-08-21, which docs/DECISIONS.md records as a
# weaker reason for keeping it than the guards around it. It runs on every turn,
# so a failure here is paid continuously and traced by nobody.
#
# The symlink case is the one that matters. The flag file is only ever checked
# for existence, so a symlink planted at that path would have its bytes rendered
# to the terminal on every keystroke, escape sequences included.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO/hooks/literal-statusline.sh"

fail=0
pass=0

check() {
  local desc="$1" want="$2" got="$3"
  if [ "$got" != "$want" ]; then
    echo "FAIL: $desc — wanted [$want], got [$got]"
    fail=1
  else
    pass=$((pass + 1))
  fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 1. No flag file: the bar shows nothing at all, and says so by exiting 0.
out="$(CLAUDE_CONFIG_DIR="$TMP" bash "$HOOK" 2>&1)"; rc=$?
check "no flag file prints nothing" "" "$out"
check "no flag file exits 0" "0" "$rc"

# 2. Flag present: the badge appears. Matched on the word rather than the exact
#    escape sequence, so a colour change is not a test failure.
: > "$TMP/.literal-active"
out="$(CLAUDE_CONFIG_DIR="$TMP" bash "$HOOK" 2>&1)"; rc=$?
case "$out" in *LITERAL*) got=yes ;; *) got=no ;; esac
check "flag file prints the badge" "yes" "$got"
check "flag file exits 0" "0" "$rc"

# 3. Symlink at the flag path: nothing is printed and nothing is read. Pointed at
#    a file with contents, so a version that followed the link would leak them here.
rm -f "$TMP/.literal-active"
printf 'SECRET-CANARY-VALUE' > "$TMP/decoy"
ln -s "$TMP/decoy" "$TMP/.literal-active"
out="$(CLAUDE_CONFIG_DIR="$TMP" bash "$HOOK" 2>&1)"; rc=$?
check "symlinked flag prints nothing" "" "$out"
check "symlinked flag exits 0" "0" "$rc"
case "$out" in *CANARY*) echo "FAIL: symlinked flag leaked the target's contents"; fail=1 ;; esac
rm -f "$TMP/.literal-active"

# 4. A directory at the flag path is not a regular file, so it prints nothing
#    rather than erroring. The -f test is what makes this true; without it the
#    script would fall through to printf and draw a badge for a directory.
mkdir -p "$TMP/.literal-active"
out="$(CLAUDE_CONFIG_DIR="$TMP" bash "$HOOK" 2>&1)"; rc=$?
check "directory at the flag path prints nothing" "" "$out"
check "directory at the flag path exits 0" "0" "$rc"
rmdir "$TMP/.literal-active"

# 5. CLAUDE_CONFIG_DIR is honoured rather than assumed. An unset variable has to
#    fall back to $HOME/.claude, and a set one has to win, or a second profile
#    reads the first profile's mode.
: > "$TMP/.literal-active"
out="$(CLAUDE_CONFIG_DIR="$TMP" bash "$HOOK" 2>&1)"
case "$out" in *LITERAL*) got=yes ;; *) got=no ;; esac
check "CLAUDE_CONFIG_DIR is read" "yes" "$got"

if [ "$fail" = 0 ]; then
  echo "literal-statusline: $pass checks passed"
else
  echo "literal-statusline: FAILURES above"
fi
exit "$fail"
