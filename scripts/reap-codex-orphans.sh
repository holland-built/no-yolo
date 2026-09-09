#!/usr/bin/env bash
#
# Shut down abandoned Codex app-server brokers.
#
# How the plugin works (codex 1.0.6):
#   - One broker per working directory, not per session. It is spawned with
#     detached: true (broker-lifecycle.mjs:64), so EVERY broker is reparented
#     to launchd. Parent PID says nothing about whether it is in use.
#   - The live broker for a directory is registered in
#     ~/.claude/plugins/data/codex-openai-codex/state/*/broker.json
#   - The SessionEnd hook is meant to shut it down, with a 5 second timeout.
#     When that hook does not run or times out, the broker and its children
#     survive, holding ~120 MB per group with no idle timeout to reclaim it.
#
# So this script does what the plugin does: sends broker/shutdown over the
# socket. If a session needs a broker afterwards, ensureBrokerSession() spawns
# a fresh one, which is the plugin's normal recovery path.
#
# It skips any broker that looks busy, judged by its log file being touched
# recently. SIGKILL is a last resort, only for a broker that will not shut down.
#
# Usage: reap-codex-orphans.sh [--dry-run] [--idle-minutes N]   (default N=10)

set -uo pipefail

DRY_RUN=0
IDLE_MINUTES=10
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --idle-minutes) IDLE_MINUTES="${2:?--idle-minutes needs a number}"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

PATTERN="app-server-broker|codex app-server|codex-code-mode-host"
STATE_ROOT="$HOME/.claude/plugins/data/codex-openai-codex/state"
PLUGIN="$HOME/.claude/plugins/cache/openai-codex/codex/1.0.6"

mb() { ps -eo rss,command | grep -E "$PATTERN" | grep -v grep \
        | awk '{s+=$1} END {printf "%.0f", s+0 ? s/1024 : 0}'; }

# All running broker PIDs, with the session dir they were given.
brokers() {
  ps -eo pid,command | grep app-server-broker | grep -v grep \
    | sed -n 's/^ *\([0-9]*\).*--pid-file \([^ ]*\)\/broker\.pid.*/\1 \2/p'
}

# Every descendant of $1 that is itself a Codex process. The pattern filter is
# the safety net: a wrong tree walk can never reach a non-Codex process.
codex_tree() {
  local pid="$1" kid
  if ps -p "$pid" -o command= 2>/dev/null | grep -qE "$PATTERN"; then
    printf '%s\n' "$pid"
  fi
  for kid in $(pgrep -P "$pid" 2>/dev/null); do
    codex_tree "$kid"
  done
}

BEFORE=$(mb)
FOUND=0; SKIPPED=0; STOPPED=0

while read -r pid sessiondir; do
  [[ -z "${pid:-}" ]] && continue
  FOUND=$((FOUND + 1))
  log="$sessiondir/broker.log"
  age=$(ps -p "$pid" -o etime= 2>/dev/null | tr -d ' ')

  # Busy check: a broker whose log was written recently may be mid-call.
  if [[ -f "$log" ]] && [[ -n $(find "$log" -newermt "-${IDLE_MINUTES} minutes" 2>/dev/null) ]]; then
    echo "skip  $pid  age $age  active in the last ${IDLE_MINUTES}m"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo "stop  $pid  age $age  $sessiondir"
  (( DRY_RUN )) && { STOPPED=$((STOPPED + 1)); continue; }

  # Graceful first: the same broker/shutdown the SessionEnd hook sends.
  node -e '
    const net = require("node:net");
    const sock = net.createConnection({ path: process.argv[1] });
    sock.on("connect", () => sock.write(JSON.stringify({id:1,method:"broker/shutdown",params:{}}) + "\n"));
    sock.on("data", () => { sock.end(); process.exit(0); });
    sock.on("error", () => process.exit(1));
    setTimeout(() => process.exit(1), 3000);
  ' "$sessiondir/broker.sock" 2>/dev/null

  sleep 1
  # Last resort: it ignored shutdown. SIGTERM is ignored too, so SIGKILL.
  if ps -p "$pid" >/dev/null 2>&1; then
    echo "      did not shut down, killing its Codex tree"
    for p in $(codex_tree "$pid" | awk '{print NR"\t"$0}' | sort -rn | cut -f2); do
      kill -9 "$p" 2>/dev/null
    done
  fi
  STOPPED=$((STOPPED + 1))
done < <(brokers)

if (( FOUND == 0 )); then
  echo "No Codex brokers running."
  exit 0
fi

# A broker.json naming a pid that is gone is stale. The plugin tolerates this
# (ensureBrokerSession tears it down), so leave the files alone and just say so.
STALE=0
if [[ -d "$STATE_ROOT" ]]; then
  for f in "$STATE_ROOT"/*/broker.json; do
    [[ -f "$f" ]] || continue
    rpid=$(sed -n 's/.*"pid": *\([0-9]*\).*/\1/p' "$f" | head -1)
    [[ -n "$rpid" ]] && ! ps -p "$rpid" >/dev/null 2>&1 && STALE=$((STALE + 1))
  done
fi

echo
if (( DRY_RUN )); then
  echo "Would stop $STOPPED of $FOUND brokers. Skipped $SKIPPED as active."
  echo "Run without --dry-run to do it."
else
  echo "Stopped $STOPPED of $FOUND brokers. Skipped $SKIPPED as active."
  echo "Memory held by Codex: ${BEFORE} MB → $(mb) MB."
fi
(( STALE )) && echo "$STALE registry entries name a process that is gone; the plugin clears these itself."
exit 0
