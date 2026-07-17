#!/usr/bin/env bash
# Smoke test for hooks/worktree-autoclean.sh: with no extra worktrees present,
# the hook must be a no-op and exit 0 (it is wired to SessionStart/SessionEnd,
# so a non-zero exit here would surface as hook noise in every session).
set -uo pipefail
HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/worktree-autoclean.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git -C "$tmp" init -q
git -C "$tmp" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init

# Feed the hook a SessionEnd-style payload pointing at the fixture repo.
if printf '{"cwd":"%s"}' "$tmp" | bash "$HOOK"; then
  echo "PASS worktree-autoclean smoke (no worktrees -> exit 0)"
else
  echo "FAIL worktree-autoclean smoke: expected exit 0 with no worktrees"
  exit 1
fi
