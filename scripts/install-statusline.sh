#!/usr/bin/env bash
#
# Install the Claude Code status line:
#   model │ effort │ ctx 21% │ 5h 23% │ 3h20m │ output style │ branch
#
# Adds one key to ~/.claude/settings.json and leaves every other setting alone.
# Safe to run twice.

set -euo pipefail

RAW="https://raw.githubusercontent.com/holland-built/no-yolo/main/statusline.sh"
DEST="$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"

command -v jq      >/dev/null 2>&1 || { echo "needs jq: brew install jq"      >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "needs python3"                  >&2; exit 1; }
command -v curl    >/dev/null 2>&1 || { echo "needs curl"                     >&2; exit 1; }

mkdir -p "$HOME/.claude"

echo "Downloading the status line..."
curl -fsSL "$RAW" -o "$DEST.tmp"
bash -n "$DEST.tmp" || { echo "downloaded file is not valid bash; nothing changed" >&2; rm -f "$DEST.tmp"; exit 1; }
mv "$DEST.tmp" "$DEST"
chmod +x "$DEST"

if [[ -f "$SETTINGS" ]]; then
  cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d%H%M%S)"
  echo "Backed up your settings next to the original."
fi

python3 - "$SETTINGS" "$DEST" <<'PY'
import json, pathlib, sys
p, script = pathlib.Path(sys.argv[1]), sys.argv[2]
d = {}
if p.exists():
    try:
        d = json.loads(p.read_text())
    except Exception:
        print("settings.json is not valid JSON; fix it first, nothing changed", file=sys.stderr)
        raise SystemExit(1)
old = d.get("statusLine")
d["statusLine"] = {"type": "command", "command": script, "padding": 0}
p.write_text(json.dumps(d, indent=2) + "\n")
if old and old != d["statusLine"]:
    print(f"Replaced your previous status line: {old.get('command', old)}")
print(f"Kept {len(d) - 1} other setting(s).")
PY

echo
echo "Done. Restart Claude Code to see it."
