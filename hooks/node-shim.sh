#!/usr/bin/env bash
# Finds a Node interpreter and hands it the hook it was asked to run:
#   bash node-shim.sh /path/to/hook.js [args...]
#
# Rewritten from a blank page 2026-08-22 (machinery rebuild). The contract is
# hooks/tests/node-shim.test.sh.
#
# WHY THIS EXISTS. The .js hooks are wired in settings.json, which survives nvm
# upgrades; the node binary's path does not. A pinned interpreter path goes dead
# the day nvm prunes that version, and a dead hook line errors on every event.
# So the interpreter is resolved at call time instead: PATH first, then the
# newest nvm-installed node as a fallback.
#
# WHO MAY FAIL OPEN. When no node exists at all, what happens next depends on
# which hook was being run, and the split is the whole point of this file:
#   - config-protection.js is a GUARD. A guard that cannot run must not read as
#     a guard that found nothing, so the edit is blocked (exit 2) with a message
#     saying the guard itself is down. Its predecessor named a hook that a
#     rebuild had deleted, so the fail-closed branch was dead and every hook
#     failed open — the reason this file's target list must only ever name
#     hooks that exist.
#   - everything else is cosmetic (a formatter pass, a mode tracker). A dead
#     cosmetic hook costs nothing; blocking the session over one costs plenty.
#     Exit 0, quietly.
set -u

target="${1:-}"

find_node() {
  command -v node 2>/dev/null && return 0
  # Fallback: nvm's install tree. The glob sorts ascending, so the last
  # executable match is the newest version present.
  local found=""
  local candidate
  for candidate in "$HOME"/.nvm/versions/node/*/bin/node; do
    [ -x "$candidate" ] && found="$candidate"
  done
  [ -n "$found" ] && printf '%s\n' "$found"
}

node_bin="$(find_node)"

if [ -z "$node_bin" ]; then
  case "${target##*/}" in
    config-protection.js)
      echo "node-shim: no node interpreter found; the config guard cannot run, so the edit is blocked (fail closed)" >&2
      exit 2 ;;
    *)
      exit 0 ;;
  esac
fi

exec "$node_bin" "$@"
