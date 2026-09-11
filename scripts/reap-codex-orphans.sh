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
# A broker is stopped only when all four of these hold. Anything unreadable or
# unknown counts against stopping, never for it:
#   - it is older than the age floor (a broker spawned seconds ago may not have
#     written its first job file yet),
#   - it is registered to a workspace we can name,
#   - that workspace has no queued or running job,
#   - and no live `claude` session is sitting in that workspace.
# The last one is the point. An idle session is the normal resting state, and
# this script runs from SessionStart, so without it, opening a session in one
# workspace shuts down the broker of a live session in another.
# Everything that survives all four is asked to shut down the way the plugin
# asks: broker/shutdown over the socket. SIGKILL only if it refuses.
#
# The workspace path comes from jobs[].workspaceRoot in the state dir's
# state.json; broker.json does not carry it. A broker that has never run a job
# therefore has no recoverable workspace, and is left alone forever.
#
# broker.log is NOT a liveness signal. It is opened at spawn and never written,
# so its mtime is just the spawn time. An earlier version of this script used
# it and would have stopped brokers mid-review. State-dir mtime is no better:
# an idle session writes nothing, which is the case this script must respect.
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
STATE_ROOT="${CODEX_REAPER_STATE_ROOT:-$HOME/.claude/plugins/data/codex-openai-codex/state}"

# Every check below reads plugin state. If any of it cannot be read, a broker
# doing real work looks idle, so refuse to run rather than guess.
refuse() { echo "refusing to act: $1" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || refuse "python3 is needed to read job state"
command -v node    >/dev/null 2>&1 || refuse "node is needed to send broker/shutdown"

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

# The state dir whose broker.json names this pid.
# Exit 0 = found (prints the dir). 1 = readable registry, pid absent.
# 2 = registry could not be read, so nothing can be concluded.
state_dir_for_pid() {
  local pid="$1" d f rpid
  [[ -d "$STATE_ROOT" && -r "$STATE_ROOT" && -x "$STATE_ROOT" ]] || return 2

  # A workspace we cannot enter hides its own broker.json from the glob below,
  # which would read as "this pid is registered nowhere". That is the fail-open
  # this function must not have, so an unusable workspace makes the whole
  # lookup unknown.
  for d in "$STATE_ROOT"/*/; do
    [[ -e "$d" ]] || continue
    [[ -d "$d" && -r "$d" && -x "$d" ]] || return 2
  done

  for f in "$STATE_ROOT"/*/broker.json; do
    [[ -e "$f" ]] || continue          # glob matched nothing: empty registry
    [[ -r "$f" ]] || return 2          # present but unreadable: unknown
    rpid=$(sed -n 's/.*"pid": *\([0-9]*\).*/\1/p' "$f" | head -1) || return 2
    if [[ "$rpid" == "$pid" ]]; then
      dirname "$f"
      return 0
    fi
  done
  return 1
}

# Active (queued or running) jobs in a state dir, printed one per line.
# Exit 0 = definitely nothing active. 1 = something active, OR state we could
# not read. Every failure lands on 1, so a broker doing real work can never
# look idle because a file would not open or parse.
active_jobs() {
  local dir="$1" out rc
  # The workspace dir must be readable and traversable first. Without that,
  # "$dir/jobs does not exist" is indistinguishable from "cannot look", and
  # believing the first is how a busy workspace reads as idle.
  if [[ ! -d "$dir" || ! -r "$dir" || ! -x "$dir" ]]; then
    echo "workspace directory unreadable"
    return 1
  fi
  [[ -e "$dir/jobs" ]] || return 0          # no jobs dir at all: nothing running
  if [[ ! -d "$dir/jobs" || ! -r "$dir/jobs" || ! -x "$dir/jobs" ]]; then
    echo "jobs directory unreadable"
    return 1
  fi
  out=$(python3 - "$dir/jobs" <<'PYJOBS'
import json, os, sys

d = sys.argv[1]
try:
    names = sorted(os.listdir(d))
except Exception as exc:
    print(f"cannot list jobs: {exc}")
    sys.exit(1)

active = []
for name in names:
    if not name.endswith(".json"):
        continue
    try:
        with open(os.path.join(d, name)) as fh:
            job = json.load(fh)
    except Exception:
        active.append(f"{name} (unreadable)")
        continue
    if not isinstance(job, dict):
        active.append(f"{name} (unexpected shape)")
        continue
    status = job.get("status")
    if status is None:
        active.append(f"{job.get('id') or name} (no status)")
    elif status in ("queued", "running"):
        active.append(f"{job.get('title') or job.get('id') or name} [{status}]")

for line in active:
    print(line)
sys.exit(1 if active else 0)
PYJOBS
  )
  rc=$?
  [[ -n "$out" ]] && printf '%s\n' "$out"
  # A python crash exits non-zero with no output. Still active, by policy.
  if (( rc != 0 )) && [[ -z "$out" ]]; then
    echo "job state could not be read"
  fi
  (( rc == 0 )) && return 0
  return 1
}

# The workspace root a state dir belongs to, read from its state.json jobs.
# Exit 0 = found (prints the path). 2 = no job ever recorded one, or the file
# could not be read. There is deliberately no "this dir has no workspace"
# answer: a missing root is absence of evidence, not evidence of an orphan.
workspace_root_for_dir() {
  local dir="$1" out
  [[ -r "$dir/state.json" ]] || return 2
  out=$(python3 - "$dir/state.json" <<'PYROOT'
import json, sys

try:
    with open(sys.argv[1]) as fh:
        state = json.load(fh)
except Exception:
    sys.exit(2)
if not isinstance(state, dict):
    sys.exit(2)
roots = [j.get("workspaceRoot") for j in state.get("jobs", [])
         if isinstance(j, dict) and j.get("workspaceRoot")]
if not roots:
    sys.exit(2)
print(roots[-1])
PYROOT
  ) || return 2
  [[ -n "$out" ]] || return 2
  printf '%s\n' "$out"
}

# Is a live Claude Code session sitting in $1?
# Exit 0 = yes. 1 = definitely none. 2 = could not tell, which callers must
# treat as yes. Directories are compared by device:inode, so /tmp and
# /private/tmp are one directory here, not two.
live_session_in() {
  local root="$1" want pids pid cwd got rc unknown=0
  want=$(stat -f '%d:%i' "$root" 2>/dev/null) || return 2
  [[ -n "$want" ]] || return 2
  command -v lsof >/dev/null 2>&1 || return 2

  # pgrep matches comm exactly, so the desktop app's "Claude" processes are not
  # in here; only `claude` CLI sessions are. Exit 1 is a real "none running".
  pids=$(pgrep -x claude 2>/dev/null); rc=$?
  (( rc > 1 )) && return 2
  (( rc == 1 )) && return 1

  # A session we cannot inspect is not a session we have ruled out. Keep looking
  # for a definite match, but remember that the sweep was incomplete: ending on
  # "no match" after failing to read one of them would be the fail-open that
  # stops a live session's broker.
  for pid in $pids; do
    cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p' | head -1)
    if [[ -z "$cwd" ]]; then unknown=1; continue; fi
    got=$(stat -f '%d:%i' "$cwd" 2>/dev/null) || { unknown=1; continue; }
    [[ -n "$got" ]] || { unknown=1; continue; }
    [[ "$got" == "$want" ]] && return 0
  done
  (( unknown )) && return 2
  return 1
}

# A broker whose workspace still has a live session is not an orphan, however
# idle it looks: a session with no queued job is the normal resting state, and
# this script runs from SessionStart in some other workspace.
# Exit 0 = safe to stop. 1 = leave alone, and print why.
owned_by_live_session() {
  local dir="$1" root
  root=$(workspace_root_for_dir "$dir") || {
    echo "workspace unknown, so it cannot be shown to be an orphan"; return 1; }
  live_session_in "$root"
  case $? in
    0) echo "a live Claude session is sitting in $root"; return 1 ;;
    2) echo "could not tell whether a session is in $root"; return 1 ;;
  esac
  return 0
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

  dir=$(state_dir_for_pid "$pid"); lookup=$?
  if (( lookup == 2 )); then
    echo "skip  $pid  age $age  broker registry could not be read"
    SKIPPED=$((SKIPPED + 1)); continue
  fi

  if (( lookup != 0 )); then
    echo "skip  $pid  age $age  registered to no workspace, so it cannot be shown to be an orphan"
    SKIPPED=$((SKIPPED + 1)); continue
  fi

  busy=$(active_jobs "$dir"); idle=$?
  if (( idle != 0 )); then
    echo "skip  $pid  age $age  $(basename "$dir") has work in flight:"
    while IFS= read -r line; do [[ -n "$line" ]] && echo "        $line"; done <<< "$busy"
    SKIPPED=$((SKIPPED + 1)); continue
  fi

  owner=$(owned_by_live_session "$dir") || {
    echo "skip  $pid  age $age  $(basename "$dir"): $owner"
    SKIPPED=$((SKIPPED + 1)); continue
  }

  echo "stop  $pid  age $age  $(basename "$dir"), no active jobs and no live session"

  (( DRY_RUN )) && { STOPPED=$((STOPPED + 1)); continue; }

  # Last look before acting. A job can start between the check above and the
  # shutdown below; re-reading here narrows that window to the gap between
  # these two lines. It cannot close it. Closing it needs a "shut down only if
  # idle" operation inside the broker, which is the plugin's code, not ours.
  busy=$(active_jobs "$dir"); idle=$?
  if (( idle != 0 )); then
    echo "skip  $pid  work started while we were deciding"
    SKIPPED=$((SKIPPED + 1)); continue
  fi
  owner=$(owned_by_live_session "$dir") || {
    echo "skip  $pid  a session appeared while we were deciding: $owner"
    SKIPPED=$((SKIPPED + 1)); continue
  }

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
