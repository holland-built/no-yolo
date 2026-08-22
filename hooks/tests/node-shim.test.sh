#!/usr/bin/env bash
# Contract for hooks/node-shim.sh, which finds a Node interpreter and hands it
# the hook it was asked to run.  Run: bash hooks/tests/node-shim.test.sh
#
# Rewritten from a blank page 2026-08-22 (machinery rebuild), AFTER the shim and
# judged against it.
#
# THE ONE THING THAT MATTERS. When no node exists, what happens depends on WHICH
# hook was being run, and getting that split wrong is silent: the guard's
# fail-closed branch once named a hook a rebuild had deleted, so the branch was
# dead and EVERY hook failed open. Nothing noticed, because a hook that exits 0
# without running looks exactly like a hook that ran and found nothing.
#
# The no-node cases run under `env -i` with a stripped PATH and a HOME that has
# no nvm tree, because this machine's real HOME has a live nvm install and the
# shim's fallback would find it, defeating the simulation. bash is resolved to an
# absolute path first, since the stripped PATH cannot locate bash itself.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHIM="$REPO/hooks/node-shim.sh"
BASH_BIN="$(command -v bash)"

fail=0
results=()
check() {  # $1 description, $2 expected, $3 actual
  if [ "$2" = "$3" ]; then
    results+=("PASS|$1")
  else
    results+=("FAIL|$1 (expected [$2], got [$3])")
    fail=1
  fi
}

EMPTY_HOME="$(mktemp -d)"
trap 'rm -rf "$EMPTY_HOME"' EXIT

no_node() {  # run the shim with no interpreter reachable anywhere
  env -i PATH=/nonexistent HOME="$EMPTY_HOME" "$BASH_BIN" "$SHIM" "$@" >/dev/null 2>&1
  echo $?
}

# --- node present: the shim gets out of the way ------------------------------
# An empty JSON object is a well-formed call that names no file, so a working
# shim plus a working guard exits 0. This proves the exec path, not the guard.
check "node present: the guard runs and allows" "0" \
  "$(echo '{}' | bash "$SHIM" "$REPO/hooks/config-protection.js" >/dev/null 2>&1; echo $?)"

check "node present: arguments reach the interpreter" "0" \
  "$(bash "$SHIM" -e 'process.exit(0)' >/dev/null 2>&1; echo $?)"

# --- no node: the guard fails CLOSED -----------------------------------------
check "no node: the config guard blocks the edit" "2" "$(no_node "$REPO/hooks/config-protection.js")"

# The branch is chosen by BASENAME, so any path to the guard must fail closed.
# A relative or oddly-spelled path silently taking the fail-open branch is the
# defect this asserts against.
check "no node: the guard fails closed via a relative path" "2" "$(no_node "hooks/config-protection.js")"
check "no node: the guard fails closed via a bare basename" "2" "$(no_node "config-protection.js")"

# --- no node: cosmetic hooks fail OPEN, quietly ------------------------------
# A dead formatter or mode tracker costs nothing; blocking a session over one
# costs plenty.
check "no node: the formatter hook exits quietly" "0" "$(no_node "$REPO/hooks/format-typecheck.js")"
check "no node: the mode tracker exits quietly"  "0" "$(no_node "$REPO/hooks/literal-mode-tracker.js")"
# Built at run time, not written as a literal: a nonexistent path spelled out in
# a tracked file is a dangling reference, and verify.sh's dangling-reference row
# would flag this suite for containing one. It caught exactly that on 2026-08-22.
UNKNOWN_HOOK="$REPO/hooks/zz-$(printf 'unknown')-hook.js"
check "no node: an unknown hook exits quietly"   "0" "$(no_node "$UNKNOWN_HOOK")"
check "no node: no argument at all exits quietly" "0" "$(no_node)"

# --- the fail-closed branch says why -----------------------------------------
# A guard that blocks in silence is indistinguishable from a crash, and the next
# person disables the wrong thing.
msg="$(env -i PATH=/nonexistent HOME="$EMPTY_HOME" "$BASH_BIN" "$SHIM" "$REPO/hooks/config-protection.js" 2>&1 >/dev/null)"
case "$msg" in
  *"no node"*) results+=("PASS|the fail-closed refusal explains itself on stderr") ;;
  *) results+=("FAIL|the fail-closed refusal said nothing useful: [$msg]"); fail=1 ;;
esac

printf '\n%-6s  %s\n' RESULT CASE
for r in "${results[@]}"; do printf '%-6s  %s\n' "${r%%|*}" "${r#*|}"; done

if [ "$fail" -eq 0 ]; then
  printf '\nAll asserts passed.\n'
  exit 0
else
  printf '\nSome asserts failed.\n'
  exit 1
fi
