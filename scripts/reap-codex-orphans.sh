#!/usr/bin/env bash
#
# Shut down abandoned Codex app-server brokers.
#
# How the plugin works (codex 1.0.6), all of it load-bearing here:
#   - One broker per workspace, not per session. Spawned with detached: true
#     (broker-lifecycle.mjs:64), so EVERY broker is reparented to launchd and
#     its parent PID tells you nothing.
#   - The broker for a workspace is registered in that workspace's state dir:
#     ~/.claude/plugins/data/codex-openai-codex/state/<slug>-<hash>/broker.json
#     which holds its pid and socket endpoint.
#   - Work in flight is recorded in that same state dir under jobs/*.json, each
#     carrying a status. Active is "queued" or "running"; terminal is
#     "completed", "failed" or "cancelled".
#   - The SessionEnd hook stops the broker by sending broker/shutdown over the
#     socket, with a 5 second timeout. There is no idle timeout, so a broker
#     whose SessionEnd never ran survives forever at roughly 120 MB a group.
#
# A broker is left alone if its workspace has any queued or running job, or if
# it is younger than the age floor (a broker spawned seconds ago may not have
# written its first job file yet). Everything else is asked to shut down the way
# the plugin asks: broker/shutdown over the socket. SIGKILL only if it refuses.
#
# broker.log is NOT a liveness signal. It is opened at spawn and never written,
# so its mtime is just the spawn time. An earlier version of this script used
# it and would have stopped brokers mid-review.
#
# Usage: reap-codex-orphans.sh [--dry-run] [--min-age-minutes N]   (default 2)

set -uo pipefail

DRY_RUN=0
MIN_AGE=2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --min-age-minutes) MIN_AGE="${2:?--min-age-minutes needs a number}"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

PATTERN="app-server-broker|codex app-server|codex-code-mode-host"
STATE_ROOT="$HOME/.claude/plugins/data/codex-openai-codex/state"

mb() { ps -eo rss,command | grep -E "$PATTERN" | grep -v grep \
        | awk '{s+=$1} END {printf "%.0f", (NR ? s/1024 : 0)}'; }

# Running broker pids, with the session dir each was given.
brokers() {
  ps -eo pid,command | grep app-server-broker | grep -v grep \
    | sed -n 's/^ *\([0-9]*\).*--pid-file \([^ ]*\)\/broker\.pid.*/\1 \2/p'
}

# Age of a pid in whole seconds.
age_seconds() {
  ps -p "$1" -o etime= 2>/dev/null | tr -d ' ' \
    | awk -F'[-:]' '{ if (NF==4) print $1*86400+$2*3600+$3*60+$4;
                      else if (NF==3) print $1*3600+$2*60+$3;
                      else if (NF==2) print $1*60+$2; else print 0 }'
}

# The state dir whose broker.json names this pid, if any.
state_dir_for_pid() {
  local pid="$1" f rpid
  for f in "$STATE_ROOT"/*/broker.json; do
    [[ -f "$f" ]] || continue
    rpid=$(sed -n 's/.*"pid": *\([0-9]*\).*/\1/p' "$f" | head -1)
    if [[ "$rpid" == "$pid" ]]; then
      dirname "$f"
      return 0
    fi
  done
  return 1
}

# Names of queued or running jobs in a state dir.
active_jobs() {
  local dir="$1"
  [[ -d "$dir/jobs" ]] || return 0
  python3 - "$dir/jobs" <<'PY'
import json, os, sys
d = sys.argv[1]
for name in sorted(os.listdir(d)):
    if not name.endswith(".json"):
        continue
    try:
        job = json.load(open(os.path.join(d, name)))
    except Exception:
        # Unreadable job file: treat as active. Refusing to act is the safe
        # direction when we cannot tell.
        print(f"{name} (unreadable)")
        continue
    if job.get("status") in ("queued", "running"):
        print(f"{job.get('title') or job.get('id') or name} [{job.get('status')}]")
PY
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
  secs=$(age_seconds "$pid"); secs=${secs:-0}
  age=$(ps -p "$pid" -o etime= 2>/dev/null | tr -d ' ')

  if (( secs < MIN_AGE * 60 )); then
    echo "skip  $pid  age $age  younger than the ${MIN_AGE}m floor"
    SKIPPED=$((SKIPPED + 1)); continue
  fi

  if dir=$(state_dir_for_pid "$pid"); then
    busy=$(active_jobs "$dir")
    if [[ -n "$busy" ]]; then
      echo "skip  $pid  age $age  $(basename "$dir") has work in flight:"
      while IFS= read -r line; do echo "        $line"; done <<< "$busy"
      SKIPPED=$((SKIPPED + 1)); continue
    fi
    echo "stop  $pid  age $age  $(basename "$dir"), no active jobs"
  else
    echo "stop  $pid  age $age  registered to no workspace"
  fi

  (( DRY_RUN )) && { STOPPED=$((STOPPED + 1)); continue; }

  # Graceful: the same broker/shutdown the SessionEnd hook sends.
  node -e '
    const net = require("node:net");
    const sock = net.createConnection({ path: process.argv[1] });
    sock.on("connect", () => sock.write(JSON.stringify({id:1,method:"broker/shutdown",params:{}}) + "\n"));
    sock.on("data", () => { sock.end(); process.exit(0); });
    sock.on("error", () => process.exit(1));
    setTimeout(() => process.exit(1), 3000);
  ' "$sessiondir/broker.sock" 2>/dev/null

  sleep 1
  if ps -p "$pid" >/dev/null 2>&1; then
    echo "      refused shutdown, killing its Codex tree"
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

echo
if (( DRY_RUN )); then
  echo "Would stop $STOPPED of $FOUND brokers. Left $SKIPPED alone."
  echo "Run without --dry-run to do it."
else
  echo "Stopped $STOPPED of $FOUND brokers. Left $SKIPPED alone."
  echo "Memory held by Codex: ${BEFORE} MB → $(mb) MB."
fi
