#!/usr/bin/env python3
"""Mark a chat's row in Orca's sidebar while it needs the user.

The chat's tab name gets a red dot in front, and a chime plays once. When the user replies, the
tab goes back to Orca's automatic name (a name the user typed is not kept, by the user's choice:
Orca does not let a script read it). Runs on Stop, UserPromptSubmit and SessionEnd. A chat counts
as waiting when its last reply opens with the Action First "Waiting on you" block or ends with
the "Not done yet" banner's waiting line. Helpers never print either, so they never get a dot.
Never blocks a chat: every failure is ignored.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

STATE_DIR = Path.home() / ("Library/Caches" if sys.platform == "darwin" else ".cache") / "orca-waiting"
DOT = "🔴 "
SOUND = "/System/Library/Sounds/Glass.aiff"
VOLUME = "0.05"  # afplay volume, 1 is full; the user found full volume, 0.3 and 0.12 too loud
BLOCK_LINE = re.compile(r"^-{5,}\s*Waiting on you\s*-{5,}$")
BANNER_LINE = re.compile(r"^Waiting on you: \S")


def is_waiting(text):
    lines = [l.strip() for l in text.splitlines() if l.strip() and not l.strip().startswith("```")]
    return bool(lines) and bool(BLOCK_LINE.match(lines[0]) or BANNER_LINE.match(lines[-1]))


def last_reply(data):
    if data.get("last_assistant_message"):
        return data["last_assistant_message"]
    path = data.get("transcript_path")
    if not path or not os.path.exists(path):
        return ""
    reply = ""
    with open(path, encoding="utf-8", errors="replace") as transcript:
        for line in transcript:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if entry.get("type") != "assistant":
                continue
            parts = entry.get("message", {}).get("content", [])
            text = "\n".join(p.get("text", "") for p in parts if isinstance(p, dict) and p.get("type") == "text")
            if text.strip():
                reply = text
    return reply


def orca(*args, check=False):
    binary = os.path.join(os.environ.get("ORCA_CLI_BIN_DIR", ""), "orca")
    done = subprocess.run([binary if os.path.exists(binary) else "orca", *args],
                          capture_output=True, text=True, timeout=5, check=check)
    return done.stdout


def tab_title(handle):
    for terminal in json.loads(orca("terminal", "list", "--json"))["result"]["terminals"]:
        if terminal.get("handle") == handle:
            return (terminal.get("title") or "Claude").removeprefix(DOT)
    raise LookupError(handle)


def main():
    handle = os.environ.get("ORCA_TERMINAL_HANDLE")
    if not handle:
        return
    data = json.load(sys.stdin)
    marker = STATE_DIR / handle
    reply = last_reply(data) if data.get("hook_event_name") == "Stop" else ""
    if is_waiting(reply):
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        if not marker.exists():
            # One chime when a chat starts waiting; no Mac pop-up, by the user's choice.
            subprocess.Popen(["afplay", "-v", VOLUME, SOUND], start_new_session=True,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        orca("terminal", "rename", "--terminal", handle, "--title", DOT + tab_title(handle), check=True)
        marker.touch()
    elif marker.exists():
        # Keep the marker until the rename works, so a failed try is retried on the next reply.
        orca("terminal", "rename", "--terminal", handle, check=True)
        marker.unlink()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
