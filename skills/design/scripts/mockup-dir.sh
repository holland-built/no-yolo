#!/usr/bin/env bash
# mockup-dir — create a mockup folder AND make sure the project ignores it.
#
# Usage:  bash ~/.claude/skills/design/scripts/mockup-dir.sh <skill>-<slug>
#         bash ~/.claude/skills/design/scripts/mockup-dir.sh --prune [days]
#
# Why this exists: /build once wrote `mockups/<slug>/` without the leading dot,
# which no ignore rule matched, so the files were committable. Two other repos
# had mockups committed before anyone noticed. Creating the folder and
# protecting it are now the same action — you cannot do one and forget the other.
set -euo pipefail

ensure_ignored() {
  local root; root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
  local gi="$root/.gitignore"
  grep -qE '^\.mockups/?$' "$gi" 2>/dev/null && return 0
  [ -s "$gi" ] && [ "$(tail -c1 "$gi")" != "" ] && printf '\n' >> "$gi"
  printf '\n# throwaway design mockups\n.mockups/\n' >> "$gi"
  echo "added .mockups/ to $gi — it was not ignored"
}

# --prune [days] : delete mockup folders older than N days (default 30).
# Never touches anything under 7 days old, whatever N says — a low number
# typed by accident should not eat work from this morning.
if [ "${1:-}" = "--prune" ]; then
  days="${2:-30}"
  [ "$days" -lt 7 ] && days=7
  [ -d .mockups ] || { echo "no .mockups here"; exit 0; }
  found=0
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    found=$((found+1))
    echo "  removing $(basename "$d")  ($(du -sh "$d" | cut -f1), untouched ${days}+ days)"
    rm -rf "$d"
  done < <(find .mockups -mindepth 1 -maxdepth 1 -type d -mtime +"$days" 2>/dev/null)
  rm -f .mockups/_index.html 2>/dev/null || true
  rmdir .mockups 2>/dev/null || true
  [ "$found" = 0 ] && echo "nothing older than $days days" || echo "pruned $found folder(s)"
  exit 0
fi

DIR="${1:?usage: mockup-dir.sh <skill>-<slug>  |  mockup-dir.sh --prune [days]}"
case "$DIR" in
  */*) echo "ERROR: pass one name like 'design-checkout', not a path" >&2; exit 1 ;;
esac
ensure_ignored
mkdir -p ".mockups/$DIR"
echo ".mockups/$DIR"
