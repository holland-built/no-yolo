#!/bin/bash
# Stop hook — passive session reflection
# Captures session summary to ~/.claude/proposals/ for weekly review.
# NO headless claude invocation — purely writes data to a file, never triggers a response.

set -euo pipefail

PROPOSALS_DIR="$HOME/.claude/proposals"
THRESHOLD=20

# Turn counter
COUNTER_FILE="$HOME/.claude/.reflect-turn-counter"
count=0
if [ -f "$COUNTER_FILE" ]; then
  count=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
fi
[[ "$count" =~ ^[0-9]+$ ]] || count=0
count=$((count + 1))
if [ "$count" -lt "$THRESHOLD" ]; then
  echo "$count" > "$COUNTER_FILE"
  echo "{}"
  exit 0
fi
echo 0 > "$COUNTER_FILE"

# Capture most recent session summary
LATEST_SESSION=$(ls -t "$HOME/.claude/session-data/"*.tmp 2>/dev/null | head -1 || true)
if [ -z "$LATEST_SESSION" ]; then
  echo "{}"
  exit 0
fi

mkdir -p "$PROPOSALS_DIR"
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="$PROPOSALS_DIR/session-$DATE.md"

{
  echo ""
  echo "## Session captured $(date '+%H:%M')"
  head -80 "$LATEST_SESSION" 2>/dev/null || true
  echo "---"
} >> "$OUTPUT_FILE"

# Brainstorms-today safety net — reminds about memory if forge/plan ran today
BRAINSTORMS_DIR="$HOME/.claude/brainstorms"
SENTINEL="$HOME/.claude/.memory-prompt-$(date +%Y-%m-%d)"
if [ -d "$BRAINSTORMS_DIR" ] && [ ! -f "$SENTINEL" ]; then
  TODAY_FILES=$(find "$BRAINSTORMS_DIR" -name "*-plan-*.md" -newermt "$(date +%F)" 2>/dev/null | head -1 || true)
  if [ -n "$TODAY_FILES" ]; then
    touch "$SENTINEL"
    {
      echo ""
      echo "## Memory reminder $(date '+%H:%M')"
      echo "Forge/plan run detected today — save key decisions to memory + run /memory-compile"
      echo "---"
    } >> "$OUTPUT_FILE"
  fi
fi

# Always output {} — never additionalContext
echo "{}"
exit 0
