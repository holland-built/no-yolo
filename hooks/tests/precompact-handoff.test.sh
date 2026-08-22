#!/bin/bash
# Tests for hooks/precompact-handoff.sh — the breadcrumb dropped when the window
# compacts before a handoff exists.
# Run: bash hooks/tests/precompact-handoff.test.sh
#
# The property under every case below is the same one: this hook runs at the
# moment the context window is full, and exit 2 there blocks compaction, which
# on a context-limit recovery fails the request outright. So every case,
# including the broken ones, checks for exit 0.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO/hooks/precompact-handoff.sh"

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

contains() {
  case "$2" in *"$1"*) echo yes ;; *) echo no ;; esac
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

INPUT='{"session_id":"abc123","transcript_path":"/tmp/t/00893aaf.jsonl","cwd":"/srv/x/proj","hook_event_name":"PreCompact","trigger":"auto","custom_instructions":""}'

# 1. The ordinary run: instructions on stdout, marker on disk, exit 0.
out="$(printf '%s' "$INPUT" | CLAUDE_CONFIG_DIR="$TMP" bash "$HOOK" 2>/dev/null)"; rc=$?
check "valid input exits 0" "0" "$rc"
check "marker file exists" "yes" "$([ -f "$TMP/handoffs/.last-precompact" ] && echo yes || echo no)"

# 2. Every section name skills/handoff/SKILL.md section 3 writes appears in the
#    output, in that file's wording. A summariser shaped by this text and a
#    handoff written by the skill have to name the same parts.
for section in \
  "The goal, in the owner's own words" \
  "First action on resume" \
  "Where we got to" \
  "Decided in conversation, written nowhere else" \
  "Tried and rejected" \
  "Open, needs a decision"; do
  check "output names section: $section" "yes" "$(contains "$section" "$out")"
done

# 3. The marker carries what the next /handoff needs to find this session again:
#    the session id, the directory, the trigger, and the transcript that still
#    holds the owner's own words.
marker="$(cat "$TMP/handoffs/.last-precompact")"
check "marker records session_id" "yes" "$(contains "session_id=abc123" "$marker")"
check "marker records cwd" "yes" "$(contains "cwd=/srv/x/proj" "$marker")"
check "marker records trigger" "yes" "$(contains "trigger=auto" "$marker")"
check "marker records transcript" "yes" "$(contains "transcript=/tmp/t/00893aaf.jsonl" "$marker")"
check "marker records the date" "yes" "$(contains "date=$(date +%Y-%m-%d)" "$marker")"

# 4. Unreadable input is not a reason to block compaction. Garbage on stdin
#    still exits 0 and still leaves a marker, with the fields it could not read
#    written as unknown rather than left blank.
rm -rf "${TMP:?}/handoffs"
out2="$(printf 'not json at all' | CLAUDE_CONFIG_DIR="$TMP" bash "$HOOK" 2>/dev/null)"; rc=$?
check "unparseable input exits 0" "0" "$rc"
check "unparseable input still writes the marker" "yes" \
  "$([ -f "$TMP/handoffs/.last-precompact" ] && echo yes || echo no)"
check "unparseable input still prints the sections" "yes" \
  "$(contains "First action on resume" "$out2")"
check "unknown session is named, not blank" "yes" \
  "$(contains "session_id=unknown" "$(cat "$TMP/handoffs/.last-precompact")")"

# 5. Empty stdin, which is what a hook harness sends when it has nothing.
rm -rf "${TMP:?}/handoffs"
printf '' | CLAUDE_CONFIG_DIR="$TMP" bash "$HOOK" >/dev/null 2>&1; rc=$?
check "empty stdin exits 0" "0" "$rc"

# 6. A symlink planted at the marker path is refused, not followed. The path is
#    predictable, so a link there would redirect the write onto its target.
rm -rf "${TMP:?}/handoffs"
mkdir -p "$TMP/handoffs"
printf 'ORIGINAL-CONTENTS' > "$TMP/decoy"
ln -s "$TMP/decoy" "$TMP/handoffs/.last-precompact"
printf '%s' "$INPUT" | CLAUDE_CONFIG_DIR="$TMP" bash "$HOOK" >/dev/null 2>&1; rc=$?
check "symlinked marker exits 0" "0" "$rc"
check "symlinked marker's target is untouched" "ORIGINAL-CONTENTS" "$(cat "$TMP/decoy")"
rm -f "$TMP/handoffs/.last-precompact"

# 7. An unwritable handoffs directory: still exit 0, because a breadcrumb that
#    could not be dropped is not worth a failed request.
chmod 500 "$TMP/handoffs"
printf '%s' "$INPUT" | CLAUDE_CONFIG_DIR="$TMP" bash "$HOOK" >/dev/null 2>&1; rc=$?
check "unwritable marker directory exits 0" "0" "$rc"
chmod 700 "$TMP/handoffs"

# 8. CLAUDE_CONFIG_DIR is honoured rather than assumed, or a second profile's
#    compaction drops its breadcrumb in the personal profile.
rm -rf "${TMP:?}/handoffs"
mkdir -p "$TMP/alt"
printf '%s' "$INPUT" | CLAUDE_CONFIG_DIR="$TMP/alt" bash "$HOOK" >/dev/null 2>&1
check "CLAUDE_CONFIG_DIR is read" "yes" \
  "$([ -f "$TMP/alt/handoffs/.last-precompact" ] && echo yes || echo no)"
check "the default location was not used" "no" \
  "$([ -e "$TMP/handoffs/.last-precompact" ] && echo yes || echo no)"

if [ "$fail" = 0 ]; then
  echo "precompact-handoff: $pass checks passed"
else
  echo "precompact-handoff: FAILURES above"
fi
exit "$fail"
