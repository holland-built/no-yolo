#!/usr/bin/env bash
# Auto-clean finished git worktrees for the session's repo.
#
# Safety contract (never loses work):
#   - Always prunes registrations whose directory is already gone (git worktree prune).
#   - Removes a LIVE worktree only when ALL hold:
#       * it is not the repo's primary checkout
#       * it is not the worktree this session is running in
#       * its working tree is clean (no uncommitted / untracked changes)
#       * its HEAD is already merged into the repo's default branch
#     => commits survive on the base branch; edits are impossible to lose.
#
# Wired to SessionStart (sweep leftovers) and SessionEnd (clean on done).
# Emits one line per removal so the SessionStart context shows what happened.
set -uo pipefail

input="$(cat 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -z "$cwd" ] && cwd="$PWD"

cd "$cwd" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# 1) Always safe: drop stale registrations (directory already deleted).
git worktree prune 2>/dev/null || true

# Resolve the default branch (origin/HEAD -> main -> master).
base="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')"
[ -z "$base" ] && git show-ref --verify --quiet refs/heads/main   && base=main
[ -z "$base" ] && git show-ref --verify --quiet refs/heads/master && base=master
[ -z "$base" ] && exit 0

primary="$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')"
self="$(git rev-parse --show-toplevel 2>/dev/null || echo "$cwd")"

# 2) Remove live worktrees that are provably done (clean + merged).
git worktree list --porcelain | awk '/^worktree /{print $2}' | while IFS= read -r wt; do
  [ "$wt" = "$primary" ] && continue
  [ "$wt" = "$self" ]    && continue
  [ -d "$wt" ]           || continue
  [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ] && continue   # dirty -> keep
  head="$(git -C "$wt" rev-parse HEAD 2>/dev/null)" || continue
  if git merge-base --is-ancestor "$head" "refs/heads/$base" 2>/dev/null; then
    if git worktree remove "$wt" 2>/dev/null; then
      echo "worktree-autoclean: removed done worktree $wt (merged into $base, clean)"
    fi
  fi
done

exit 0
