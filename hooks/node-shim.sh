#!/usr/bin/env bash
# node-shim.sh — resolve a Node interpreter dynamically so hooks survive nvm
# upgrades that delete a pinned version dir. Usage:
#   bash node-shim.sh /path/to/hook.js [args...]
# Fail-closed rule: if no node is found AND the target is config-protection.js,
# exit 2 (block the edit) — a guard that cannot run must not read as a guard that
# found nothing. For every other hook, exit 0 quietly (a dead cosmetic hook is
# harmless). This named lockstep-guard.js until 2026-08-21, when that hook was
# deleted; the branch had gone dead, so every hook was failing open.
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
    config-protection.js)
      echo "node-shim: no node interpreter found — blocking edit (config guard fail-closed)" >&2
      exit 2 ;;
    *)
      exit 0 ;;
  esac
fi

exec "$node_bin" "$@"
