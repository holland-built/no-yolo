#!/usr/bin/env bash
# node-shim.sh — resolve a Node interpreter dynamically so hooks survive nvm
# upgrades that delete a pinned version dir. Usage:
#   bash node-shim.sh /path/to/hook.js [args...]
# Fail-closed rule: if no node is found AND the target is lockstep-guard.js,
# exit 2 (block the edit) — the lockstep gate must never fail open. For every
# other hook, exit 0 quietly (a dead cosmetic hook is harmless).
set -u
script="${1:-}"

# 1. node on PATH
node_bin="$(command -v node 2>/dev/null || true)"

# 2. fallback: newest nvm-installed node
if [ -z "$node_bin" ]; then
  for d in "$HOME"/.nvm/versions/node/*/bin/node; do
    [ -x "$d" ] && node_bin="$d"   # glob sorts ascending → last match = newest-ish
  done
fi

if [ -z "$node_bin" ] || [ ! -x "$node_bin" ]; then
  case "${script##*/}" in
    lockstep-guard.js)
      echo "node-shim: no node interpreter found — blocking edit (lockstep fail-closed)" >&2
      exit 2 ;;
    *)
      exit 0 ;;
  esac
fi

exec "$node_bin" "$@"
