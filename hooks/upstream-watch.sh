#!/bin/bash
# SessionStart hook. Answers one question the owner cannot answer for themselves:
# "did the author change something and I missed it?"
#
# TWO HALVES, AND THE ORDER IS THE POINT.
#   1. PRINT a report that a previous session already fetched. Reads one local file. Instant.
#   2. SPAWN a detached background fetch for next time, at most once a day.
# The session never waits on a network call. Codex ruled at the second plan gate that fetching
# inside session start would delay the first prompt and break outright when offline. So this
# session shows yesterday's answer and earns tomorrow's. A day-old answer to "has upstream
# moved" is worth having; a two-second stall on every single start is not.
#
# FAILS OPEN, ALWAYS AND SILENTLY. No network, no git, no curl, a timeout, a broken clone: the
# hook exits 0 and says nothing. A watcher that blocks the session it is trying to help gets
# switched off within a day, and then it watches nothing at all.
#
# WHAT IT WATCHES. Every row in docs/BORROWED.md that carries a pinned commit, plus the Claude
# Code version, so a skill whose job has become a built-in command can be flagged. It never
# replaces anything. It reports, and the owner decides.
#
# BASH-3.2 CLEAN (stock macOS): no associative arrays, no case-changing expansions.
set -uo pipefail

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STATE="$CFG/.upstream"
REPORT="$STATE/report.md"
STAMP="$STATE/last-run"
SEEN_VERSION="$STATE/claude-version"

mkdir -p "$STATE" 2>/dev/null || exit 0

# ── half one: show what a previous run found ────────────────────────────────
if [ -s "$REPORT" ]; then
  cat "$REPORT"
  rm -f "$REPORT" 2>/dev/null
fi

# ── half two: earn the next report, at most once a day ──────────────────────
today="$(date +%Y-%m-%d 2>/dev/null)" || exit 0
[ -f "$STAMP" ] && [ "$(cat "$STAMP" 2>/dev/null)" = "$today" ] && exit 0
printf '%s' "$today" > "$STAMP" 2>/dev/null || exit 0

# Detached, output discarded, never waited on.
(
  exec >/dev/null 2>&1
  out=""

  # --- borrowed content: has the pinned upstream moved? ---
  # Only rows with a pinned commit can be checked. Rows without one are listed in
  # docs/BORROWED.md as explicitly unwatched, and this loop does not pretend otherwise.
  if command -v git >/dev/null 2>&1 && [ -f "$CFG/docs/BORROWED.md" ]; then
    while IFS='|' read -r _ name repo pinned _rest; do
      case "$repo" in *github.com/*) ;; *) continue ;; esac
      name="$(printf '%s' "$name" | tr -d ' `')"
      slug="$(printf '%s' "$repo" | tr -d ' `' | sed 's#.*github.com/##')"
      pinned="$(printf '%s' "$pinned" | tr -d ' `')"
      [ -n "$slug" ] && [ -n "$pinned" ] || continue
      head="$(timeout 20 git ls-remote "https://github.com/$slug" HEAD 2>/dev/null | cut -f1)"
      [ -n "$head" ] || continue
      if [ "$head" != "$pinned" ]; then
        out="$out
- **$name** has moved. You have \`$(printf '%s' "$pinned" | cut -c1-8)\`, they are now on \`$(printf '%s' "$head" | cut -c1-8)\`.
  Nothing has changed on your machine. Say \"show me what changed in $name\" to see it."
      fi
    done < <(grep -E '^\|.*github\.com/' "$CFG/docs/BORROWED.md" 2>/dev/null)
  fi

  # --- Claude Code: did a skill's job become a built-in? ---
  # A version change is a REVIEW CANDIDATE, never a removal. Changelog prose cannot
  # mechanically prove a skill is obsolete, so this only ever says "worth a look".
  if command -v claude >/dev/null 2>&1; then
    now="$(timeout 15 claude --version 2>/dev/null | awk '{print $1}')"
    was="$(cat "$SEEN_VERSION" 2>/dev/null)"
    if [ -n "$now" ]; then
      printf '%s' "$now" > "$SEEN_VERSION" 2>/dev/null
      if [ -n "$was" ] && [ "$was" != "$now" ]; then
        out="$out
- **Claude Code went from $was to $now.** Some of what your own commands do may now be
  built in. Say \"what became built in\" and I will read the changelog between those two
  versions and tell you, in plain words. Nothing is removed without you saying so."
      fi
    fi
  fi

  [ -n "$out" ] || exit 0
  {
    printf '## Upstream check, %s\n' "$today"
    printf '%s\n' "$out"
    printf '\nNothing above has been changed for you. Each one waits for your yes.\n'
  } > "$REPORT" 2>/dev/null
) </dev/null >/dev/null 2>&1 &

exit 0
