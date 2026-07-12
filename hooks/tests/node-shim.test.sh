#!/bin/bash
# Tests for hooks/node-shim.sh
# Plain bash asserts (the shim is bash, not node). Run: bash hooks/tests/node-shim.test.sh
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHIM="$REPO/hooks/node-shim.sh"
BASH_BIN="$(command -v bash)"

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

# Guard: a stray lockstep flag would skew the node-present case.
rm -f "$HOME/.claude/.lockstep-active"

# --- Case 1: node present -> runs lockstep-guard.js -> exit 0 (no flag set) ---
bash "$SHIM" "$REPO/hooks/lockstep-guard.js"
rc1=$?
assert_eq "node present: lockstep-guard exit code" "0" "$rc1"

# Cases 2 & 3 need a HOME with no real .nvm install so the fallback glob
# genuinely finds nothing (this machine's real $HOME has a live nvm install,
# so reusing it here would defeat the "no node found" simulation). We also
# resolve bash to an absolute path first: `env -i PATH=/nonexistent bash`
# can't locate `bash` itself via the stripped PATH.
FAKE_HOME="$(mktemp -d)"

# --- Case 2: PATH stripped, no node anywhere -> lockstep-guard.js -> exit 2 (fail closed) ---
out2=$(env -i PATH=/nonexistent HOME="$FAKE_HOME" "$BASH_BIN" "$SHIM" "$REPO/hooks/lockstep-guard.js" 2>&1)
rc2=$?
assert_eq "no node: lockstep-guard fail-closed exit code" "2" "$rc2"

# --- Case 3: PATH stripped, no node anywhere -> caveman-activate.js -> exit 0 (fail open, harmless) ---
env -i PATH=/nonexistent HOME="$FAKE_HOME" "$BASH_BIN" "$SHIM" "$REPO/hooks/caveman-activate.js"
rc3=$?
assert_eq "no node: caveman-activate quiet exit code" "0" "$rc3"

rm -rf "$FAKE_HOME"

if [ "$fail" -eq 0 ]; then
  echo "All asserts passed."
  exit 0
else
  echo "Some asserts failed."
  exit 1
fi
