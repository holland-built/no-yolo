#!/usr/bin/env python3
"""Notify when Codex is stuck, so no chat waits on it for days unnoticed.

Run every 5 minutes by launchd (~/Library/LaunchAgents/local.codex-watchdog.plist).
Each run checks two things and posts a macOS notification when one is wrong:

1. A Codex job has run longer than WARN_MINUTES: a `codex exec` call, or a
   `codex-companion.mjs task` (/codex:rescue). A read-only `codex exec` (the review
   command in shared/codex.md) running longer than KILL_MINUTES is stopped, so the chat
   that started it gets empty output, which codex.md says to report as a failed review,
   and carries on. Rescue tasks may be writing code, so they are only reported.
2. OpenAI is throttling Codex: "429 Too Many Requests" retries in ~/.codex/logs_2.sqlite
   in the last 10 minutes. Codex then waits minutes per retry and looks frozen.

Each problem is notified once per REPEAT_MINUTES. Processes are keyed by pid and start
time, so a reused pid never inherits an old warning or gets signalled.

Usage: python3 -I codex-watchdog.py [--dry-run] [--warn-minutes N] [--kill-minutes N]
"""
import argparse
import json
import os
import re
import signal
import sqlite3
import subprocess
import time
from datetime import datetime

HOME = os.path.expanduser("~")
STATE_FILE = os.path.join(HOME, ".claude/state/codex-watchdog.json")
LOG_FILE = os.path.join(HOME, ".claude/state/codex-watchdog.log")
LOGS_DB = os.path.join(HOME, ".codex/logs_2.sqlite")
LOG_KEEP = 500
WARN_MINUTES = 20
KILL_MINUTES = 30
REPEAT_MINUTES = 60
THROTTLE_WINDOW_SECONDS = 600
THROTTLE_MIN_RETRIES = 3

# The codex binary itself (npm or app copy) running `exec`. Shells that only mention it do not count.
EXEC_PATTERN = re.compile(r"^(\S*/)?codex\s+(.*\s)?exec(\s|$)")
TASK_PATTERN = re.compile(r"^(\S*/)?node\s.*/codex-companion\.mjs\s+task(\s|$)")
STOP_GATE_MARKER = "Run a stop-gate review of the previous Claude turn."


def log(message):
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    line = f"{datetime.now():%Y-%m-%d %H:%M:%S} {message}\n"
    try:
        with open(LOG_FILE) as f:
            lines = f.readlines()[-(LOG_KEEP - 1):]
    except FileNotFoundError:
        lines = []
    with open(LOG_FILE, "w") as f:
        f.writelines(lines + [line])


def notify(title, message, dry_run):
    if dry_run:
        print(f"[notify] {title}: {message}")
        return
    log(f"NOTIFY {title}: {message}")
    script = f"display notification {json.dumps(message)} with title {json.dumps(title)} sound name \"Basso\""
    subprocess.run(["/usr/bin/osascript", "-e", script], check=False)


def load_state():
    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_state(state):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, "w") as f:
        json.dump(state, f)


def due(state, key, now):
    return now - state.get(key, 0) >= REPEAT_MINUTES * 60


def folder_of(pid):
    out = subprocess.run(
        ["/usr/sbin/lsof", "-a", "-p", str(pid), "-d", "cwd", "-Fn"],
        capture_output=True, text=True, check=False,
    ).stdout
    for line in out.splitlines():
        if line.startswith("n"):
            return os.path.basename(line[1:]) or line[1:]
    return "unknown folder"


def read_jobs():
    """Return Codex jobs as dicts: pid, start (epoch), minutes, kind, command."""
    out = subprocess.run(
        ["/bin/ps", "-axww", "-o", "pid=,etime=,lstart=,command="],
        capture_output=True, text=True, check=False,
    ).stdout
    now = time.time()
    jobs = []
    for line in out.splitlines():
        parts = line.split(None, 7)  # pid, etime, 5 lstart tokens, command
        if len(parts) < 8:
            continue
        pid, command = int(parts[0]), parts[7]
        if EXEC_PATTERN.search(command):
            kind = "exec"
        elif TASK_PATTERN.search(command) and STOP_GATE_MARKER not in command:
            kind = "task"
        else:
            continue
        start = time.mktime(time.strptime(" ".join(parts[2:7]), "%a %b %d %H:%M:%S %Y"))
        jobs.append({"pid": pid, "start": int(start), "minutes": int((now - start) / 60),
                     "kind": kind, "command": command})
    return jobs


def still_same(job):
    """True when the pid still runs the same command started at the same time."""
    for other in read_jobs():
        if other["pid"] == job["pid"] and other["start"] == job["start"]:
            return True
    return False


def check_jobs(state, now, args):
    for job in read_jobs():
        if job["minutes"] < args.warn_minutes:
            continue
        key = f"job:{job['pid']}:{job['start']}"
        folder = folder_of(job["pid"])
        label = "Codex review" if job["kind"] == "exec" else "Codex rescue task"
        read_only = job["kind"] == "exec" and "read-only" in job["command"]
        if read_only and job["minutes"] >= args.kill_minutes:
            if args.dry_run:
                print(f"[would stop] pid {job['pid']} in {folder}")
            elif still_same(job):
                os.kill(job["pid"], signal.SIGTERM)
            notify("Codex stuck: stopped it",
                   f"{label} in {folder} ran {job['minutes']} min. Stopped, so the chat carries on.",
                   args.dry_run)
            state[key] = now
        elif due(state, key, now):
            notify("Codex looks stuck",
                   f"{label} in {folder} has run {job['minutes']} min. Check that chat.",
                   args.dry_run)
            state[key] = now


def check_throttle(state, now, args):
    if not os.path.exists(LOGS_DB):
        return
    try:
        db = sqlite3.connect(f"file:{LOGS_DB}?mode=ro", uri=True, timeout=5)
        count = db.execute(
            "select count(*) from logs where target = 'codex_core::responses_retry' "
            "and feedback_log_body like '%429%' and ts > ?",
            (int(now) - THROTTLE_WINDOW_SECONDS,),
        ).fetchone()[0]
        db.close()
    except sqlite3.Error as error:
        log(f"could not read {LOGS_DB}: {error}")
        return
    if count >= THROTTLE_MIN_RETRIES and due(state, "throttle", now):
        notify("Codex is being throttled",
               f"OpenAI answered '429 Too Many Requests' {count} times in 10 min. "
               "Codex calls will hang for minutes. Fewer chats at once helps.",
               args.dry_run)
        state["throttle"] = now


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--warn-minutes", type=int, default=WARN_MINUTES)
    parser.add_argument("--kill-minutes", type=int, default=KILL_MINUTES)
    args = parser.parse_args()

    now = int(time.time())
    state = load_state()
    # Forget entries older than a day, so the state file stays small.
    state = {k: v for k, v in state.items() if now - v < 86400}
    check_jobs(state, now, args)
    check_throttle(state, now, args)
    if not args.dry_run:
        save_state(state)


if __name__ == "__main__":
    main()
