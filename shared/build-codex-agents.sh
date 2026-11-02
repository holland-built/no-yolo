#!/bin/sh
# Rebuild ~/.codex/AGENTS.md from Codex's role plus the rules Claude and Codex share.
# Run it after editing codex-role.md or AGENTS.md in this folder. Codex has no file import,
# so its copy has to be built rather than linked.
set -eu
dir=$(cd "$(dirname "$0")" && pwd)
out="$HOME/.codex/AGENTS.md"
mkdir -p "$HOME/.codex"
tmp="$out.tmp.$$"
{
  printf '<!-- Built by ~/.claude/shared/build-codex-agents.sh. Edit codex-role.md or AGENTS.md there, not this file. -->\n\n'
  cat "$dir/codex-role.md"
  printf '\n---\n\n'
  cat "$dir/AGENTS.md"
} > "$tmp"
mv "$tmp" "$out"
echo "wrote $out ($(wc -l < "$out" | tr -d ' ') lines, $(wc -c < "$out" | tr -d ' ') bytes)"
