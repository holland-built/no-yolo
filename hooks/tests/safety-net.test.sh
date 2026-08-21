#!/bin/bash
# Tests for hooks/safety-net.sh — the PreToolUse guard on Bash.
# Run: bash hooks/tests/safety-net.test.sh
#
# The guard was rewritten four times before it held (docs/DECISIONS.md). Each
# rewrite looked correct on the page and failed when run: fixed-string matching
# let `rm -fr /` past, BSD sed's missing \b let everything past, and checking only
# the first command let `rm -rf /tmp/x && rm -rf /etc` hide behind its harmless
# half. So the forms below are asserted one by one, not summarised.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO/hooks/safety-net.sh"

fail=0
pass=0

# Feed one command through the hook and assert the exit code.
# 2 = refused, 0 = allowed.
assert_rc() {
  local want="$1" cmd="$2" desc="$3" got
  printf '%s' "$cmd" | jq -Rs '{tool_input:{command:.}}' | bash "$HOOK" >/dev/null 2>&1
  got=$?
  if [ "$got" != "$want" ]; then
    echo "FAIL: $desc — wanted $want, got $got   [$cmd]"
    fail=1
  else
    pass=$((pass + 1))
  fi
}

blocked() { assert_rc 2 "$1" "$2"; }
allowed() { assert_rc 0 "$1" "$2"; }

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq is not installed, so the hook cannot run and neither can its tests."
  exit 0
fi

# --- Recursive deletes with no bounded target ---------------------------------
blocked 'rm -rf /'                     "rm -rf /"
blocked 'rm -fr /'                     "flags in the other order"
blocked 'rm -r -f /'                   "flags as separate arguments"
blocked 'rm -Rf /'                     "capital R"
blocked 'rm --recursive --force /'     "long flags"
blocked 'rm -rf /*'                    "glob under root"
blocked 'rm -rf ~/*'                   "glob under home"
blocked 'rm -rf $HOME/*'               "glob under home as a variable"
blocked 'rm -rf /etc/*'                "glob under a system directory"
blocked 'rm -rf /*/'                   "glob with a trailing slash"
blocked 'rm -rf /**'                   "a doubled glob"
blocked 'rm -rf /*/*'                  "two glob levels"

# --- A protected path behind a harmless one, on the SAME command -------------
# Not a second command after && or ;, which the segment split already covers:
# a second operand of one rm. The guard read only the first operand until a
# cross-model review of the diff caught it on 2026-08-21.
blocked 'rm -rf /tmp /etc'             "second operand is protected"
blocked 'rm -rf ./safe /'              "root as the second operand"
blocked 'rm -rf ./a ./b /usr'          "protected path as the third operand"
blocked 'rm -rf ~'                     "home as a tilde"
blocked 'rm -rf $HOME'                 "home as a variable"
blocked 'rm -rf "$HOME"'               "home quoted"
blocked 'rm -rf ${HOME}'               "home in braces"

# --- The configuration directory this repo is ---------------------------------
blocked 'rm -rf ~/.claude'             "config dir as a tilde path"
blocked 'rm -rf "$HOME/.claude"'       "config dir as a variable path"
blocked 'rm -rf /'                     "root with a trailing slash kept"
blocked 'rm -rf /etc/'                 "system dir with a trailing slash"

# --- System directories --------------------------------------------------------
blocked 'rm -rf /usr'                  "/usr"
blocked 'rm -rf /System'               "/System"
blocked 'rm -rf /Users'                "/Users"

# --- Hiding behind a harmless first half --------------------------------------
blocked 'ls -la && rm -rf /etc'        "second command after &&"
blocked 'echo hi; rm -rf /var'         "second command after ;"
blocked 'true | rm -rf /opt'           "second command after a pipe"

# --- Git and disk commands that cannot be undone ------------------------------
blocked 'git push --force origin main' "force push"
blocked 'git push -f origin main'      "force push, short flag"
blocked 'git reset --hard HEAD~3'      "hard reset"
blocked 'git clean -fdx'               "git clean"
blocked 'chmod -R 777 /'               "recursive world-writable"
blocked 'dd if=/dev/zero of=/dev/disk0' "raw block-device write"
blocked 'mkfs.ext4 /dev/sda1'          "formatting a disk"
blocked 'psql -c "DROP TABLE users"'   "dropping a table"

# --- Ordinary work must not be refused ----------------------------------------
# A guard that blocks real work gets unwired, so the negative control matters
# as much as the positive one.
allowed 'ls -la'                       "listing files"
allowed 'git status'                   "git status"
allowed 'rm -rf ./node_modules'        "a bounded relative path"
allowed 'rm -rf /tmp/build-cache'      "a bounded path under /tmp"
allowed 'rm file.txt'                  "a plain single-file delete"
allowed 'git push origin main'         "an ordinary push"
allowed 'git reset HEAD~1'             "a soft reset"
allowed 'grep -rn "form" src/'         "a search containing no rm"
allowed 'npm run format'               "a command whose name contains rm"

# --- The hook must fail closed, never quiet -----------------------------------
echo 'not json at all' | bash "$HOOK" >/dev/null 2>&1
rc=$?
if [ "$rc" != 2 ]; then
  echo "FAIL: unreadable input should refuse (exit 2), got $rc"
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
