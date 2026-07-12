#!/bin/bash
# Tests for hooks/reflect-claude-md-stop.sh
# Plain bash asserts. Isolates via HOME (the script keys off $HOME, unlike the
# node tests which isolate via CLAUDE_CONFIG_DIR) so the real ~/.claude is
# never touched. Run: bash hooks/tests/reflect-stop.test.sh
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO/hooks/reflect-claude-md-stop.sh"

fail=0
assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" != "$actual" ]; then
    echo "FAIL: $desc (expected [$expected], got [$actual])"
    fail=1
  else
    echo "PASS: $desc"
  fi
}

run_hook() {
  local tmp="$1"
  ( HOME="$tmp" bash "$HOOK" )
}

# --- Case 1: garbage counter -> exit 0, stdout {} ---
TMP1="$(mktemp -d)"
mkdir -p "$TMP1/.claude/session-data" "$TMP1/.claude/brainstorms"
echo "1 2" > "$TMP1/.claude/.reflect-turn-counter"
out1=$(run_hook "$TMP1"); rc1=$?
assert_eq "garbage counter: exit code" "0" "$rc1"
assert_eq "garbage counter: stdout" "{}" "$out1"
rm -rf "$TMP1"

# --- Case 2: valid counter increments ---
TMP2="$(mktemp -d)"
mkdir -p "$TMP2/.claude/session-data" "$TMP2/.claude/brainstorms"
echo "5" > "$TMP2/.claude/.reflect-turn-counter"
out2=$(run_hook "$TMP2"); rc2=$?
newcount=$(cat "$TMP2/.claude/.reflect-turn-counter")
assert_eq "valid counter: exit code" "0" "$rc2"
assert_eq "valid counter: incremented to 6" "6" "$newcount"
assert_eq "valid counter: stdout" "{}" "$out2"
rm -rf "$TMP2"

# --- Case 3: today-file detection fires the memory reminder ---
TMP3="$(mktemp -d)"
mkdir -p "$TMP3/.claude/session-data" "$TMP3/.claude/brainstorms"
echo "19" > "$TMP3/.claude/.reflect-turn-counter"
echo "some session summary" > "$TMP3/.claude/session-data/s.tmp"
echo "# plan" > "$TMP3/.claude/brainstorms/x-plan-1.md"
today="$(date +%Y-%m-%d)"
sentinel="$TMP3/.claude/.memory-prompt-$today"
[ ! -f "$sentinel" ] || { echo "FAIL: sentinel pre-existed"; fail=1; }
out3=$(run_hook "$TMP3"); rc3=$?
proposal_file="$TMP3/.claude/proposals/session-$today.md"
assert_eq "today-file: exit code" "0" "$rc3"
assert_eq "today-file: stdout" "{}" "$out3"
if [ -f "$proposal_file" ] && grep -q "Memory reminder" "$proposal_file"; then
  echo "PASS: today-file: Memory reminder block fired"
else
  echo "FAIL: today-file: Memory reminder block did not fire"
  fail=1
fi
rm -rf "$TMP3"

if [ "$fail" -eq 0 ]; then
  echo "All asserts passed."
  exit 0
else
  echo "Some asserts failed."
  exit 1
fi
