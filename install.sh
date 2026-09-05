#!/usr/bin/env bash
# Copies the eleven files into ~/.claude and merges the settings snippet.
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
    elif [ -L "$dst" ]; then say "SYMLINK, untouched: $rel"
    else
      side="$dst.theirs.$STAMP"
      cp "$src" "$side"; say "YOURS, kept:   $rel   (mine at $(basename "$side"))"
    fi
    kept=$((kept+1))
  else
    mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"
    # Only ever chmod a file this script actually created.
    case "$rel" in *.sh|*.py) chmod +x "$dst" ;; esac
    say "installed:     $rel"; copied=$((copied+1))
  fi
# The hook's own test stays in the repo. It is not part of your setup.
done < <(cd "$SRC" && find CLAUDE.md CONTEXT.md statusline.sh rules hooks skills output-styles -type f ! -name '*.test.sh' ! -name '.DS_Store' 2>/dev/null)

echo "==> settings.json"
SET="$DEST/settings.json"
if [ ! -f "$SET" ]; then
  cp "$SRC/settings.snippet.json" "$SET"; say "created settings.json from the snippet"
else
  cp "$SET" "$SET.bak.$STAMP"; say "backed up to settings.json.bak.$STAMP"
  # Deep merge: keep every existing hook event AND every existing Stop entry.
  # Also adds env keys and deny rules you do not already have.
  # Appends our Stop hook only if an identical command is not already present.
  tmp="$(mktemp)"
  # Never edit an existing Stop entry: a sibling hook or matcher lives in there.
  # Append a new entry only when no entry anywhere already runs this command.
  jq -s '
    .[0] as $cur | .[1] as $new |
    ($new.hooks.Stop[0].hooks[0].command) as $cmd |
    (($cur.hooks.Stop // []) | any(.hooks // [] | any(.command == $cmd))) as $present |
    $cur
    | .autoMemoryDirectory = ($cur.autoMemoryDirectory // $new.autoMemoryDirectory)
    | .statusLine = ($cur.statusLine // $new.statusLine)
    # Your writing style wins if you already set one.
    | .outputStyle = ($cur.outputStyle // $new.outputStyle)
    # Your value for a key always wins. Only missing keys are added.
    | .env = (($new.env // {}) * ($cur.env // {}))
    # Deny rules add up. Yours stay, mine append, order kept, no duplicates.
    | .permissions = (($cur.permissions // {}) | .deny = (
        (((.deny // []) + ($new.permissions.deny // []))
          | reduce .[] as $d ([]; if index($d) then . else . + [$d] end))
      ))
    | .hooks = (($cur.hooks // {}) | .Stop = (
        if $present then (.Stop // []) else ((.Stop // []) + [$new.hooks.Stop[0]]) end
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
