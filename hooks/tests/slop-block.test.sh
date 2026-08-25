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

# --- Vale, the maintained second opinion --------------------------------------
# "production-ready" is docs/PROSE.md's "Say the fact, not the adjective", and it
# is the half of that standard the regexes above do NOT carry. So it separates
# the two checks cleanly: red only when vale ran, green when it did not. Using a
# tell BOTH checks catch would pass either way and prove nothing.
VALE_ONLY='The release is production-ready.'

if command -v vale >/dev/null 2>&1 && [ -f "$REPO/.vale.ini" ]; then
  assert_file 2 vale1.md "$VALE_ONLY" "vale catches an adjective the regexes do not"
else
  echo "SKIP: vale is not installed, so its finding cannot be proved here."
fi

# The same file with vale masked off PATH. A stub directory holds symlinks to the
# tools the hook genuinely needs and no vale, rather than PATH=/usr/bin:/bin,
# because jq lives in /opt/homebrew/bin on this machine and blanking the PATH
# would disable the hook itself and make every case below pass for the wrong
# reason. Two asserts, and the second is the load-bearing one: absent vale must
# take nothing away from the rules the hook already had.
STUB="$TMP/stub-bin"
mkdir -p "$STUB"
for t in jq awk grep sed mktemp rm cat printf; do
  p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$STUB/$t"
done

assert_masked() {
  local want="$1" name="$2" body="$3" desc="$4" got
  printf '%s\n' "$body" > "$TMP/$name"
  printf '{"tool_input":{"file_path":"%s"}}' "$TMP/$name" \
    | PATH="$STUB:/usr/bin:/bin" bash "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" != "$want" ]; then
    echo "FAIL: $desc — wanted $want, got $got"
    fail=1
  else
    pass=$((pass + 1))
  fi
}

if command -v vale >/dev/null 2>&1; then
  assert_masked 0 vale2.md "$VALE_ONLY" "vale off PATH: its finding goes quiet, not red"
fi
assert_masked 2 vale3.md 'The plan is simple — build it.' \
  "vale off PATH: the hook's own rules still run"

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

# --- The report is scoped to what the edit wrote -------------------------------
#
# Every assert above passes only `file_path`, which names no new text, so the filter is empty
# and the whole file is reported. That is the documented fallback and it is why those 28 went
# on passing when the scoping landed — they do not reach it. These do.
#
# The case that bought this: a three-line edit to a 1,130-line design document returned 53
# long-dash findings, 52 of them about prose written months earlier. A finding you have to
# search for is a finding people stop reading.

# Write body, then run the hook with an Edit payload whose new_string is `touched`.
assert_edit() {
  local want="$1" name="$2" body="$3" touched="$4" desc="$5" got
  printf '%s\n' "$body" > "$TMP/$name"
  jq -nc --arg f "$TMP/$name" --arg s "$touched" \
    '{tool_input:{file_path:$f, old_string:"x", new_string:$s}}' \
    | bash "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" != "$want" ]; then
    echo "FAIL: $desc — wanted $want, got $got"
    fail=1
  else
    pass=$((pass + 1))
  fi
}

DIRTY='Old prose with a dash — right here.
A clean line nobody is touching.'

assert_edit 0 s1.md "$DIRTY" 'A clean line nobody is touching.' \
  "a clean line edited in a file that already has a dash elsewhere"
assert_edit 2 s2.md "$DIRTY" 'Old prose with a dash — right here.' \
  "the dashed line itself edited, which is the author's to fix"
assert_edit 2 s3.md "$DIRTY" 'A brand new line — with its own dash.' \
  "new text carrying a dash, even when it is not yet in the file"

# A Write hands over the whole file as `content`, so all of it was just written and all of it
# is reported. Nothing is exempt because it is long.
printf '%s\n' "$DIRTY" > "$TMP/s4.md"
jq -nc --arg f "$TMP/s4.md" --arg c "$DIRTY" '{tool_input:{file_path:$f, content:$c}}' \
  | bash "$HOOK" >/dev/null 2>&1
if [ "$?" != 2 ]; then echo "FAIL: a Write reports the whole file"; fail=1; else pass=$((pass + 1)); fi

# And the fallback itself: no new text named, so nothing can be scoped and everything is said.
# A filter that cannot tell what changed must not be the thing that decides nothing did.
assert_file 2 s5.md "$DIRTY" "no new text in the payload reports the whole file"

if [ "$fail" -eq 0 ]; then
  echo "All $pass asserts passed."
  exit 0
else
  echo "Some asserts failed."
  exit 1
fi
