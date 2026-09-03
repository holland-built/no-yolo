#!/usr/bin/env bash
# Copies the five files into ~/.claude and merges the settings snippet.
# Never overwrites anything you already have. Safe to run twice.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HOME}/.claude"
STAMP="$(date +%Y%m%d-%H%M%S)"
say() { printf '  %s\n' "$1"; }

command -v jq >/dev/null || { echo "! jq is required. brew install jq"; exit 1; }
[ -d "$DEST" ] || { echo "! $DEST does not exist. Run Claude Code once first."; exit 1; }

echo "==> Files"
kept=0; copied=0
while IFS= read -r rel; do
  src="$SRC/$rel"; dst="$DEST/$rel"
  if [ -e "$dst" ]; then
    if cmp -s "$src" "$dst"; then say "same, skipped: $rel"
    else say "YOURS, kept:   $rel   (theirs at $rel.theirs)"; cp "$src" "$dst.theirs"; fi
    kept=$((kept+1))
  else
    mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"
    # Only ever chmod a file this script actually created.
    case "$rel" in *.sh|*.py) chmod +x "$dst" ;; esac
    say "installed:     $rel"; copied=$((copied+1))
  fi
done < <(cd "$SRC" && find CLAUDE.md rules hooks skills -type f 2>/dev/null)

echo "==> settings.json"
SET="$DEST/settings.json"
if [ ! -f "$SET" ]; then
  cp "$SRC/settings.snippet.json" "$SET"; say "created settings.json from the snippet"
else
  cp "$SET" "$SET.bak.$STAMP"; say "backed up to settings.json.bak.$STAMP"
  # Deep merge: keep every existing hook event AND every existing Stop entry.
  # Appends our Stop hook only if an identical command is not already present.
  tmp="$(mktemp)"
  jq -s '
    .[0] as $cur | .[1] as $new |
    ($new.hooks.Stop[0]) as $add |
    $cur
    | .autoMemoryDirectory = ($cur.autoMemoryDirectory // $new.autoMemoryDirectory)
    | .hooks = (($cur.hooks // {}) as $h |
        $h | .Stop = (
          (($h.Stop // []) | map(select(
              (.hooks // []) | map(.command) | index($add.hooks[0].command) | not
          ))) + [$add]
        ))
  ' "$SET" "$SRC/settings.snippet.json" > "$tmp"
  if jq -e . "$tmp" >/dev/null 2>&1; then
    mv "$tmp" "$SET"; say "merged; existing hook events and Stop entries preserved"
  else
    rm -f "$tmp"; say "! merge produced invalid JSON — settings.json left untouched"; exit 1
  fi
fi

echo "==> Done. $copied installed, $kept already yours."
say "Restart Claude Code, then type /build"
