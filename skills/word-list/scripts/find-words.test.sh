#!/bin/bash
# Tests for find-words.py. Run: bash skills/word-list/scripts/find-words.test.sh
#
# SESSIONS_DIR points the script at fake conversations in a temp dir, so the
# real ~/.claude/projects cannot change a result. Every case names what it
# expects and why.

set -u
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/find-words.py"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

pass=0; fail=0

# say <role> <text> -> one line of a saved conversation
say() { python3 -c 'import json,sys; print(json.dumps({"type":sys.argv[1],"message":{"content":sys.argv[2]}}))' "$1" "$2"; }

mkdir -p "$SANDBOX/proj"
FAKE="$SANDBOX/proj/fake.jsonl"
: > "$FAKE"

# Said six times by me, never by him: this is what a candidate looks like.
say assistant "quixotic quixotic quixotic quixotic quixotic quixotic" >> "$FAKE"
# Said six times, but always as a command name. Backticks must not count.
say assistant "\`widget\` \`widget\` \`widget\` \`widget\` \`widget\` \`widget\`" >> "$FAKE"
# Said six times inside a code block. Code blocks must not count.
say assistant '```
gizmo gizmo gizmo gizmo gizmo gizmo
```' >> "$FAKE"
# Ordinary English, said often. Never a candidate however often I use it.
say assistant "because because because because because because" >> "$FAKE"
# Said six times by me and once by him. He owns it, so it is dropped.
say assistant "flange flange flange flange flange flange" >> "$FAKE"
say user "flange" >> "$FAKE"

# A word he never typed at me, but writes in his own notes. His word, so it goes.
say assistant "hydrology hydrology hydrology hydrology hydrology hydrology" >> "$FAKE"
mkdir -p "$SANDBOX/notes/deep"
printf 'hydrology in a note.\n' > "$SANDBOX/notes/deep/one.md"

OUT="$(SESSIONS_DIR="$SANDBOX" NOTES_DIR="$SANDBOX/notes" python3 "$SCRIPT")"

# want <name> <listed|absent> <word>
want() {
  local name="$1" expect="$2" word="$3"
  if printf '%s' "$OUT" | grep -qE "^$word "; then got=listed; else got=absent; fi
  if [ "$got" = "$expect" ]; then pass=$((pass+1)); echo "ok   $name"
  else fail=$((fail+1)); echo "FAIL $name: expected $expect, got $got"; fi
}

want "a word only I use is listed"   listed "quixotic"
want "a word in backticks is ignored" absent "widget"
want "a word in a code block is ignored" absent "gizmo"
want "ordinary English is never a candidate" absent "because"
want "a word he says back is dropped" absent "flange"
want "a word from his notes is dropped" absent "hydrology"

# No saved conversations: say so and stop, never invent a list.
if SESSIONS_DIR="$SANDBOX/empty" NOTES_DIR="" python3 "$SCRIPT" >/dev/null 2>&1; then
  fail=$((fail+1)); echo "FAIL empty folder should exit non-zero"
else
  pass=$((pass+1)); echo "ok   empty folder stops"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
