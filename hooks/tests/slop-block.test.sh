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

# --- Code is not prose --------------------------------------------------------
# Every case below came from a real file in this repo that the first version of the
# hook refused on 2026-08-21. Four of the six were the hook's own supporting docs.
assert_file 0 m.md '```bash
printf "The plan is simple — build it.\n"
```' "a long dash inside a fenced block"

assert_file 0 n.md 'A few `- **Term** — explanation` rows are a reference block.' \
  "a long dash inside an inline code span"

assert_file 0 o.md '```
Size: <tweak|fix> — <what made it that size>
```' "a long dash inside a fenced output template"

# The fence must close at the fence and not swallow what follows.
assert_file 2 p.md '```
code — here
```
And then real prose — with a dash in it.' "prose on a line after the fence closes"

# A shorter run never closes a longer one, so the inner fence stays inside.
assert_file 0 q.md '````
```
still — inside
````' "a short fence nested in a longer one"

# A tilde fence is a fence. A backtick run must not close it.
assert_file 0 r.md '~~~
tilde — fenced
~~~' "a tilde fence"

# Four spaces of indent is an indented code block, not a fence opener, so the dash
# after it is prose and must still be caught.
assert_file 2 s.md '    ```
prose — after a non-fence' "four-space indent does not open a fence"

# An unterminated fence must not switch the rest of the file off. It is reported,
# and every line is still checked.
assert_file 2 t.md '```
never closed
and then prose — with a dash' "an unterminated fence is reported, not obeyed"

# An unmatched backtick must not blank the rest of the line.
assert_file 2 u.md 'A stray ` backtick and then a dash — right here.' \
  "an unmatched backtick leaves the prose visible"

# Counting still works when the words are real prose rather than specimens.
assert_file 2 v.md 'We elevate the seamless holistic result.' "three plain words still count"
assert_file 0 w.md 'The list is `elevate` `seamless` `holistic`.' "three quoted words do not"

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
