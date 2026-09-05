#!/bin/bash
# Tests for reply-check.sh. Run: bash hooks/reply-check.test.sh
#
# HOME is redirected to a temp dir so the real ~/.claude/.finish-line cannot
# change a result. Every case names what it expects and why.

set -u
HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/reply-check.sh"
SANDBOX="$(mktemp -d)"
mkdir -p "$SANDBOX/.claude"
# The word list the check reads. Kept small on purpose: these tests prove the
# check loads a list from a file, not that the real list has any given row.
cat > "$SANDBOX/.claude/CONTEXT.md" <<'WORDS'
| Do not say | Say this |
|---|---|
| hook | the check |
| repo | your project |
| commit | a saved version |
| symlink | a shortcut |
| marketplace | the list add-ons come from |
WORDS
trap 'rm -rf "$SANDBOX"' EXIT

pass=0; fail=0

# run <message> -> prints the hook's stdout
run() { printf '%s' "$1" | jq -Rs '{last_assistant_message:.}' | HOME="$SANDBOX" bash "$HOOK"; }

# check <name> <expect: pass|block> <substring> <message>
check() {
  local name="$1" expect="$2" want="$3" msg="$4" out
  out=$(run "$msg")
  if [ "$expect" = pass ]; then
    if [ -z "$out" ]; then pass=$((pass+1)); echo "ok   $name"
    else fail=$((fail+1)); echo "FAIL $name: expected no block, got: $out"; fi
  else
    if printf '%s' "$out" | grep -q "$want"; then pass=$((pass+1)); echo "ok   $name"
    else fail=$((fail+1)); echo "FAIL $name: expected block containing '$want', got: ${out:-<nothing>}"; fi
  fi
}

check "clean reply passes" pass "" \
  "Fixed it. The test now runs."

check "too many lines blocks" block "prose lines" \
  "$(for i in $(seq 1 20); do echo "line $i here"; done)"

check "too many named things blocks" block "distinct named things" \
  "Touched \`a/one.js\` \`b/two.js\` \`c/three.js\` \`d/four.js\` \`e/five.js\` \`f/six.js\` \`g/seven.js\`."

check "long sentence blocks" block "over 20 words" \
  "The hook reads the reply and counts the words in every sentence because a long sentence is hard to read for anyone."

check "long sentence names the cut point" block "Cut it at" \
  "The hook reads the reply and counts the words in every sentence because a long sentence is hard to read for anyone."

check "excuse without proof blocks" block "excuses something" \
  "That is a pre-existing bug."

check "excuse with a command passes" pass "" \
  "$(printf 'Ran it:\n\ngit status --short\n\nIt is a pre-existing bug.')"

check "quoted trigger phrase passes" pass "" \
  'The check stops the phrase "pre-existing bug" on sight.'

check "jargon in prose blocks" block "Use the words on the right" \
  "I removed the symlink from the marketplace."

check "jargon in backticks passes" pass "" \
  'I removed the `symlink` and the `marketplace` entry.'

check "plain words pass" pass "" \
  "Done. The add-on is gone."

check "stock AI word blocks" block "Stock AI words" \
  "This is a crucial change and a testament to the work."

check "chatbot offer blocks" block "Chatbot filler" \
  "Done. Want me to fix the rest?"

check "filler phrase blocks" block "Filler" \
  "In order to fix it, I changed the file."

check "not X but Y blocks" block "straight" \
  "It is not just a check, it is a gate."

check "plain negative passes" pass "" \
  "That is not the file I changed. Only the check can stop me."

check "word from his list blocks" block "Use the words on the right" \
  "I changed the hook and pushed the commit."

check "his word is offered back" block "the check" \
  "I changed the hook so it runs first."

FENCE='```'
check "long code block passes" pass "" \
  "$(printf 'Here:\n\n%s\n%s\n%s\n' "$FENCE" "$(for i in $(seq 1 30); do echo "code line $i"; done)" "$FENCE")"

check "short table passes" pass "" \
  "$(printf 'Two gaps:\n\n| Gap | Where |\n|---|---|\n| One | here |\n| Two | there |\n')"

# Second block on one turn: the rewrite must land.
out=$(printf '%s' "$(for i in $(seq 1 20); do echo "line $i"; done)" \
  | jq -Rs '{last_assistant_message:., stop_hook_active:true}' | HOME="$SANDBOX" bash "$HOOK")
if [ -z "$out" ]; then pass=$((pass+1)); echo "ok   stop_hook_active passes"
else fail=$((fail+1)); echo "FAIL stop_hook_active: got $out"; fi

# Fails open: bad input must never block.
for bad in "" "not json" '{}'; do
  out=$(printf '%s' "$bad" | HOME="$SANDBOX" bash "$HOOK" 2>/dev/null)
  if [ -z "$out" ]; then pass=$((pass+1)); echo "ok   fails open on '${bad:-<empty>}'"
  else fail=$((fail+1)); echo "FAIL fails open on '${bad:-<empty>}': got $out"; fi
done

# An unmet finish line blocks even a clean reply.
printf 'Make the test pass.\n' > "$SANDBOX/.claude/.finish-line"
out=$(run "Done for now.")
if printf '%s' "$out" | grep -q "Work is not finished"; then pass=$((pass+1)); echo "ok   unmet finish line blocks"
else fail=$((fail+1)); echo "FAIL unmet finish line: got ${out:-<nothing>}"; fi

# A finish line marked DONE stops blocking.
printf 'Make the test pass.\nDONE: bash hooks/reply-check.test.sh\n' > "$SANDBOX/.claude/.finish-line"
out=$(run "Done.")
if [ -z "$out" ]; then pass=$((pass+1)); echo "ok   DONE finish line passes"
else fail=$((fail+1)); echo "FAIL DONE finish line: got $out"; fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
