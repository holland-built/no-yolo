#!/bin/sh
# Rebuild ~/.codex/AGENTS.md from Codex's role, the rules Claude and Codex share, and the
# Action First output style (Claude gets that as an output style; Codex has none).
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
  printf '\n---\n\n# How to write replies to the user\n\n'
  # Claude's always-on output style, minus its front matter, so Codex answers the same way
  awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {fm=0; next} !fm' "$dir/../output-styles/action-first.md"
} > "$tmp"
mv "$tmp" "$out"
echo "wrote $out ($(wc -l < "$out" | tr -d ' ') lines, $(wc -c < "$out" | tr -d ' ') bytes)"
