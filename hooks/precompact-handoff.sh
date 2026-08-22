#!/usr/bin/env bash
# Leaves a breadcrumb when the window compacts before anyone wrote a handoff.
# Wired in settings.json as a PreCompact hook on the `auto` matcher.
#
# What this hook can and cannot do, read out of the 2.1.240 hooks reference on
# 2026-08-22 rather than assumed:
#   - PreCompact has NO field that reaches the summariser. Its input carries
#     `trigger` and `custom_instructions`; its only decision control is a
#     top-level `decision: "block"`, and "Claude Code discards a PreCompact
#     hook's `systemMessage` and `continue` fields."
#   - stdout is not context. "For most events, stdout is written to the debug
#     log but not shown in the transcript. The exceptions are UserPromptSubmit,
#     UserPromptExpansion, and SessionStart."
#   - `prompt` and `agent` hooks, which would let a model write the handoff
#     itself, list PreCompact under the events that do NOT support them.
# So the instructions printed below are advisory, and land in the debug log.
# The marker file is the part that survives, and the next /handoff reads it.
#
# It never blocks. Exit 2 on PreCompact blocks compaction, and when compaction
# was triggered to recover from a context-limit error the request fails outright.
# Every path here exits 0, including the ones where nothing could be written.
set -uo pipefail

CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MARKER="$CONFIG_DIR/handoffs/.last-precompact"

raw="$(cat 2>/dev/null || true)"

# One field out of the input JSON, without jq: this hook runs at the moment the
# window is full, and a missing binary here must not cost the breadcrumb.
field() {
  printf '%s' "$raw" | tr -d '\n' |
    sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1
}

session_id="$(field session_id)"
transcript="$(field transcript_path)"
trigger="$(field trigger)"
cwd_in="$(field cwd)"
[ -n "$cwd_in" ] || cwd_in="$PWD"
[ -n "$trigger" ] || trigger="unknown"
[ -n "$session_id" ] || session_id="unknown"

# The instructions. Advisory, per the header. The headings are the ones
# skills/handoff/SKILL.md section 3 writes, in its order, so a summary shaped by
# this text and a handoff written by the skill agree.
cat <<'INSTRUCTIONS'
This conversation is about to be compacted. Carry these across, in this order:

1. The goal, in the owner's own words — the verbatim quote, not a paraphrase.
2. First action on resume — one action, doable in under two minutes.
3. Where we got to — each piece and its state.
4. Decided in conversation, written nowhere else — each decision with its reason.
5. Tried and rejected — what failed, so the next attempt skips it.
6. Open, needs a decision — numbered, each naming who decides.

Section 1 outranks everything below it. A summary that keeps every technical
detail and loses the owner's own words sends the next hours in the wrong
direction.
INSTRUCTIONS

# A symlink at the marker path is refused rather than followed: the path is
# predictable, and a link planted there would redirect this write onto whatever
# it points at.
if [ -L "$MARKER" ]; then
  echo "precompact-handoff: $MARKER is a symlink; marker not written." >&2
  exit 0
fi

mkdir -p "$CONFIG_DIR/handoffs" 2>/dev/null || {
  echo "precompact-handoff: could not create $CONFIG_DIR/handoffs; marker not written." >&2
  exit 0
}

{
  # States what it observed, never why. This hook fires on the `auto` matcher and
  # has no way to see whether a handoff was written, so a header claiming none was
  # would be a guess wearing a fact's clothes.
  echo "# Auto-compaction ran here. This file records where, not whether a handoff exists."
  echo "date=$(date +%Y-%m-%d)"
  echo "time=$(date +%H:%M:%S)"
  echo "trigger=$trigger"
  echo "cwd=$cwd_in"
  echo "session_id=$session_id"
  echo "transcript=$transcript"
  echo "# The transcript above is the pre-compaction record. Read it for the"
  echo "# owner's own words before writing ~/.claude/handoffs/<date>-<slug>.md."
} > "$MARKER" 2>/dev/null || {
  echo "precompact-handoff: could not write $MARKER." >&2
  exit 0
}

exit 0
