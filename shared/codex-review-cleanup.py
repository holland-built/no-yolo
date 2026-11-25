#!/usr/bin/env python3
"""Archive old end-of-chat review threads, so the Codex app's list stays usable.

The Codex plugin's Stop gate starts one Codex thread per reviewed Claude reply, and Codex
saves each one. By 2026-11-25 there were 13,761 of them. This runs weekly from launchd
(~/Library/LaunchAgents/local.codex-review-cleanup.plist) and archives review threads not
touched for KEEP_DAYS, using Codex's own `codex archive <id>` (undo: `codex unarchive <id>`).
It only reads Codex's database; every change goes through the codex command.

A thread is cleaned up only when it is one of: a Stop gate review (its first message holds
the plugin's fixed review instruction), a one-off `codex exec` call, or an auto-review side
session (thread_source guardian_review). Threads the user started in the Codex app or TUI,
and /codex:rescue tasks, are never touched.

Usage: python3 -I codex-review-cleanup.py [--dry-run] [--keep-days N] [--max N]
"""
import argparse
import glob
import os
import shutil
import sqlite3
import subprocess
import time
from datetime import datetime

HOME = os.path.expanduser("~")
STATE_DB = os.path.join(HOME, ".codex/state_5.sqlite")
LOG_FILE = os.path.join(HOME, ".claude/state/codex-review-cleanup.log")
LOG_KEEP = 200
KEEP_DAYS = 7
MAX_PER_RUN = 3000
MARKER = "Run a stop-gate review of the previous Claude turn."


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


def find_codex():
    # launchd starts with a bare PATH, so look in the usual install places too.
    for path in [shutil.which("codex"), *sorted(
            glob.glob(os.path.join(HOME, ".nvm/versions/node/*/bin/codex")), reverse=True),
            "/opt/homebrew/bin/codex", "/usr/local/bin/codex"]:
        if path and os.access(path, os.X_OK):
            return path
    return None


def old_review_ids(keep_days, limit):
    cutoff = int(time.time()) - keep_days * 86400
    db = sqlite3.connect(f"file:{STATE_DB}?mode=ro", uri=True, timeout=10)
    rows = db.execute(
        "select id from threads where archived = 0 and is_pinned = 0 and updated_at < ? "
        "and (instr(first_user_message, ?) > 0 or originator = 'codex_exec' "
        "or thread_source = 'guardian_review') order by updated_at limit ?",
        (cutoff, MARKER, limit),
    ).fetchall()
    db.close()
    return [row[0] for row in rows]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--keep-days", type=int, default=KEEP_DAYS)
    parser.add_argument("--max", type=int, default=MAX_PER_RUN)
    args = parser.parse_args()

    codex = find_codex()
    if not codex:
        log("codex command not found; nothing archived")
        return
    ids = old_review_ids(args.keep_days, args.max)
    if args.dry_run:
        print(f"would archive {len(ids)} review threads older than {args.keep_days} days")
        return

    done = failed = 0
    for thread_id in ids:
        try:
            result = subprocess.run([codex, "archive", thread_id], stdin=subprocess.DEVNULL,
                                    capture_output=True, text=True, timeout=60)
            ok = result.returncode == 0
        except subprocess.TimeoutExpired:
            ok = False
        if ok:
            done += 1
        else:
            failed += 1
            if failed >= 20 and done == 0:
                log(f"stopped: first 20 archives failed (last: {thread_id})")
                break
    log(f"archived {done}, failed {failed}, of {len(ids)} review threads older than {args.keep_days} days")


if __name__ == "__main__":
    main()
