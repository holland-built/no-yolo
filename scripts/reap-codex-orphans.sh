#!/usr/bin/env bash
#
# Reap orphaned Codex broker process trees.
#
# The Codex plugin starts an app-server broker per Claude Code session. When a
# session ends the broker is not always cleaned up: it gets reparented to
# launchd (PID 1) and keeps its app-server and code-mode-host children alive,
# holding ~120 MB per group indefinitely.
#
# This kills only trees whose broker's parent is PID 1. A broker belonging to a
# live session has that session as its parent, so it is never touched.
#
# Safe to run any time. Run with --dry-run to see what it would kill.

set -uo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

PATTERN="app-server-broker|codex app-server|codex-code-mode-host"

mb() { ps -eo rss,command | grep -E "$PATTERN" | grep -v grep \
        | awk '{s+=$1} END {printf "%.0f", s/1024}'; }

# Orphaned brokers: the broker process itself, whose parent is PID 1.
orphan_brokers() {
  ps -eo pid,ppid,command | grep app-server-broker | grep -v grep \
    | awk '$2==1 {print $1}'
}

# Every descendant of $1, via pgrep -P. Returns PIDs one per line.
descendants() {
  local pid="$1" kid
  printf '%s\n' "$pid"
  for kid in $(pgrep -P "$pid" 2>/dev/null); do
    descendants "$kid"
  done
}

# Only PIDs whose command matches the Codex pattern. This is the hard safety
# net: even if the tree walk ever goes wrong, nothing outside Codex is killed.
codex_only() {
  local pid
  while read -r pid; do
    [[ -z "$pid" ]] && continue
    if ps -p "$pid" -o command= 2>/dev/null | grep -qE "$PATTERN"; then
      printf '%s\n' "$pid"
    fi
  done
}

BEFORE=$(mb)
BROKERS=$(orphan_brokers)

if [[ -z "$BROKERS" ]]; then
  echo "No orphaned Codex brokers. ${BEFORE} MB held by live ones."
  exit 0
fi

TARGETS=""
for b in $BROKERS; do
  cwd=$(ps -p "$b" -o command= | sed -n 's/.*--cwd \([^ ]*\).*/\1/p')
  age=$(ps -p "$b" -o etime= | tr -d ' ')
  echo "orphan broker $b  age $age  cwd ${cwd:-unknown}"
  TARGETS="$TARGETS $(descendants "$b" | codex_only | tr '\n' ' ')"
done

COUNT=$(echo $TARGETS | wc -w | tr -d ' ')

if (( DRY_RUN )); then
  echo
  echo "Would kill $COUNT processes, freeing roughly ${BEFORE} MB."
  echo "Run without --dry-run to do it."
  exit 0
fi

echo
echo "Killing $COUNT processes."

# Children before parents, so a dying parent cannot respawn one.
# SIGTERM is ignored by these processes, so go straight to SIGKILL.
for p in $(echo $TARGETS | tr ' ' '\n' | awk '{print NR"\t"$0}' | sort -rn | cut -f2); do
  kill -9 "$p" 2>/dev/null
done

sleep 2
AFTER=$(mb)
LEFT=$(ps -eo command | grep -E "$PATTERN" | grep -v grep | wc -l | tr -d ' ')
echo
echo "Done. ${BEFORE} MB → ${AFTER} MB. $LEFT Codex processes still running."
