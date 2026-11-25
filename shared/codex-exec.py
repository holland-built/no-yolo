#!/usr/bin/env python3
"""Run `codex exec` through a shared queue, so many chats can call Codex without a 429 freeze.

On 2026-11-25 about 9 chats called Codex at once, OpenAI answered "429 Too Many Requests",
and Codex calls then hung for minutes. This wrapper lets at most MAX_PARALLEL calls run at
once across every chat on this Mac; the rest wait their turn. Each slot is a file lock, which
the system releases when the holder exits, so a crashed call never blocks the queue.

Every call also gets `--ephemeral` (no saved session) and no stdin (the cause of an old hang),
and is stopped after TIME_LIMIT_MINUTES, printing CODEX TIMED OUT on stderr with exit code 124.
Empty output is still a failed review, as shared/codex.md says.

Usage: python3 -I ~/.claude/shared/codex-exec.py <codex exec options> "<prompt>"
Env:   CODEX_MAX_PARALLEL (default 3), CODEX_BIN (default: codex on PATH)
"""
import fcntl
import os
import shutil
import signal
import subprocess
import sys
import time

HOME = os.path.expanduser("~")
SLOT_DIR = os.path.join(HOME, ".claude/state/codex-slots")
MAX_PARALLEL = int(os.environ.get("CODEX_MAX_PARALLEL", "3"))
TIME_LIMIT_MINUTES = 15
QUEUE_LIMIT_MINUTES = 20


def take_slot():
    """Hold one of MAX_PARALLEL lock files; wait while all are taken."""
    os.makedirs(SLOT_DIR, exist_ok=True)
    deadline = time.time() + QUEUE_LIMIT_MINUTES * 60
    told = False
    while True:
        for number in range(1, MAX_PARALLEL + 1):
            handle = open(os.path.join(SLOT_DIR, f"slot{number}.lock"), "w")
            try:
                fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
                return handle
            except BlockingIOError:
                handle.close()
        if time.time() > deadline:
            sys.stderr.write(f"CODEX QUEUE FULL: {MAX_PARALLEL} calls stayed busy for "
                             f"{QUEUE_LIMIT_MINUTES} min; treat this review as failed.\n")
            sys.exit(75)
        if not told:
            sys.stderr.write(f"Codex queue: {MAX_PARALLEL} calls already running, waiting for a slot.\n")
            told = True
        time.sleep(2)


def main():
    codex = os.environ.get("CODEX_BIN") or shutil.which("codex")
    if not codex:
        sys.stderr.write("codex is not installed; skip the Codex step and say so once.\n")
        sys.exit(127)
    slot = take_slot()
    args = sys.argv[1:]
    command = [codex] if os.environ.get("CODEX_BIN") else [codex, "exec", "--ephemeral"]
    process = subprocess.Popen(command + args, stdin=subprocess.DEVNULL, start_new_session=True)
    try:
        code = process.wait(timeout=TIME_LIMIT_MINUTES * 60)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait()
        sys.stderr.write(f"CODEX TIMED OUT after {TIME_LIMIT_MINUTES} min; treat this review as failed.\n")
        code = 124
    finally:
        slot.close()
    sys.exit(code)


if __name__ == "__main__":
    main()
