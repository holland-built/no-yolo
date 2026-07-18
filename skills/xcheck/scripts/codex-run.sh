#!/usr/bin/env bash
# codex-run.sh — shared process-level runner for `codex exec`.
#
# Kills the failure class every calling skill (xcheck, design, build, review,
# design-audit) used to handle inline: stdin hang, git-repo prompt, timeout,
# pinned-model fallback, exit codes. OUTPUT PARSING STAYS WITH THE CALLER —
# FINDING lines, delimiter splits, and test/visual verdicts are different
# formats, not one class.
#
# Usage: codex-run.sh [-m MODEL] [-t SECONDS] [-s SANDBOX] "PROMPT"
#   -m  pin a model; on unknown/deprecated it retries on the config default
#   -t  timeout seconds (default 300; exit 124 on expiry)
#   -s  sandbox mode (default read-only)
set -uo pipefail

MODEL="" TIMEOUT=300 SANDBOX="read-only"
while getopts "m:t:s:" o; do
  case $o in
    m) MODEL=$OPTARG ;;
    t) TIMEOUT=$OPTARG ;;
    s) SANDBOX=$OPTARG ;;
    *) exit 2 ;;
  esac
done
shift $((OPTIND - 1))
PROMPT=${1:?usage: codex-run.sh [-m model] [-t secs] [-s sandbox] PROMPT}

command -v codex >/dev/null || { echo "codex-run: codex CLI not installed" >&2; exit 127; }

# macOS ships no GNU `timeout`; prefer it (or gtimeout), fall back to perl alarm.
with_timeout() {
  if command -v timeout >/dev/null 2>&1; then timeout "$TIMEOUT" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$TIMEOUT" "$@"
  else perl -e 'alarm shift; exec @ARGV' "$TIMEOUT" "$@"
  fi
}

run() {
  # </dev/null: codex blocks forever on "Reading additional input from stdin..."
  # when run non-interactively; --skip-git-repo-check avoids a hang outside a repo.
  with_timeout codex exec --skip-git-repo-check --sandbox "$SANDBOX" "$@" "$PROMPT" </dev/null
}

if [ -n "$MODEL" ]; then
  OUT=$(run -m "$MODEL" 2>&1); CODE=$?
  if [ $CODE -ne 0 ] && [ $CODE -ne 124 ] && [ $CODE -ne 142 ] && printf '%s' "$OUT" | grep -qiE "unknown model|model.*not found|deprecated|unsupported model"; then
    echo "codex-run: model '$MODEL' rejected — falling back to config default (update the pin)" >&2
    OUT=$(run 2>&1); CODE=$?
  fi
else
  OUT=$(run 2>&1); CODE=$?
fi

# 124 = GNU timeout expiry; 142 = perl-alarm SIGALRM kill
{ [ $CODE -eq 124 ] || [ $CODE -eq 142 ]; } && echo "codex-run: timed out after ${TIMEOUT}s" >&2
printf '%s\n' "$OUT"
exit $CODE
