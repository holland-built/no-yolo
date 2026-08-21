#!/bin/bash
# Tests for hooks/slop-block.sh — the PostToolUse writing check on Write and Edit.
# Run: bash hooks/tests/slop-block.test.sh
#
# The hook decides only what a program can decide. Judgement rules live in
# docs/PROSE.md and a person applies those, so nothing here asserts taste.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO/hooks/slop-block.sh"

fail=0
pass=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Write body to a file with the given extension, run the hook on it, assert the code.
# 2 = the file came back for a rewrite, 0 = it passed.
assert_file() {
  local want="$1" name="$2" body="$3" desc="$4" got
  printf '%s\n' "$body" > "$TMP/$name"
  printf '{"tool_input":{"file_path":"%s"}}' "$TMP/$name" | bash "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" != "$want" ]; then
    echo "FAIL: $desc — wanted $want, got $got"
    fail=1
  else
    pass=$((pass + 1))
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq is not installed, so the hook cannot run and neither can its tests."
  exit 0
fi

# --- The long dash ------------------------------------------------------------
assert_file 2 a.md 'The plan is simple — build it.'          "long dash in prose"
assert_file 0 b.md 'The plan is simple. Build it.'           "a full stop instead"
assert_file 0 c.md 'The `—` character is the one meant here.' "a specimen inside backticks"

# --- Machine vocabulary, which only counts at three ---------------------------
assert_file 0 d.md 'This will elevate the design.'           "one such word is nothing"
assert_file 0 e.md 'Elevate the seamless design.'            "two is still nothing"
assert_file 2 f.md 'Elevate the seamless holistic tapestry.' "three on a page is the signal"

# --- Sign-offs that name no next step -----------------------------------------
assert_file 2 g.md 'Let me know if you need anything else.'  "a closing line with no action"
assert_file 2 h.md 'Feel free to ask questions.'             "another form of the same"
assert_file 0 i.md 'Next: run bash verify.sh.'               "a closing line that names one"

# --- Scope: only prose files, and only files that exist -----------------------
assert_file 0 j.js 'const x = 1; // simple — really'         "a code file is not prose"
assert_file 0 k.txt 'Plain text is checked too.'             "plain text is in scope"
assert_file 2 l.mdx 'The result — it works.'                 "mdx is in scope"

printf '{"tool_input":{"file_path":"%s/does-not-exist.md"}}' "$TMP" | bash "$HOOK" >/dev/null 2>&1
rc=$?
if [ "$rc" != 0 ]; then
  echo "FAIL: a missing file should pass quietly (exit 0), got $rc"
  fail=1
else
  pass=$((pass + 1))
fi

printf '{"tool_input":{}}' | bash "$HOOK" >/dev/null 2>&1
rc=$?
if [ "$rc" != 0 ]; then
  echo "FAIL: no file path should pass quietly (exit 0), got $rc"
  fail=1
else
  pass=$((pass + 1))
fi

if [ "$fail" -eq 0 ]; then
  echo "All $pass asserts passed."
  exit 0
else
  echo "Some asserts failed."
  exit 1
fi
