#!/usr/bin/env python3
"""Name a chat's tab after what it needs while it waits for the user.

The tab name goes back when the user replies. Runs on Stop, UserPromptSubmit and SessionEnd. A chat counts
as waiting when its last reply opens with the Action First "Waiting on you" block or ends with
the "Not done yet" banner's waiting line. Never blocks a chat: every failure is ignored.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

STATE_DIR = Path.home() / ("Library/Caches" if sys.platform == "darwin" else ".cache") / "orca-waiting"
MAX_NEED = 32
BLOCK_LINE = re.compile(r"^-{5,}\s*Waiting on you\s*-{5,}$")
BANNER_LINE = re.compile(r"^Waiting on you: \S")


def is_waiting(text):
    lines = [l.strip() for l in text.splitlines() if l.strip() and not l.strip().startswith("```")]
    return bool(lines) and bool(BLOCK_LINE.match(lines[0]) or BANNER_LINE.match(lines[-1]))


def short_need(text):
    """A few words for the tab: the banner's waiting line, or else the first question's title."""
    lines = [l.strip() for l in text.splitlines() if l.strip() and not l.strip().startswith("```")]
    need = next((l.split(":", 1)[1].strip() for l in reversed(lines) if BANNER_LINE.match(l)), "")
    if (not need or "questions above" in need) and BLOCK_LINE.match(lines[0]) and len(lines) > 1:
        need = lines[1]
    need = need.split(",")[0].rstrip(" .") or "Needs your reply"
    if len(need) > MAX_NEED:
        need = need[:MAX_NEED].rsplit(" ", 1)[0]
    return need[0].upper() + need[1:]


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


def orca(*args):
    binary = os.path.join(os.environ.get("ORCA_CLI_BIN_DIR", ""), "orca")
    done = subprocess.run([binary if os.path.exists(binary) else "orca", *args],
                          capture_output=True, text=True, timeout=5)
    return done.stdout


def main():
    handle = os.environ.get("ORCA_TERMINAL_HANDLE")
    if not handle:
        return
    data = json.load(sys.stdin)
    marker = STATE_DIR / handle
    reply = last_reply(data) if data.get("hook_event_name") == "Stop" else ""
    if is_waiting(reply):
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        orca("terminal", "rename", "--terminal", handle, "--title", short_need(reply))
        marker.touch()
    elif marker.exists():
        orca("terminal", "rename", "--terminal", handle)
        marker.unlink()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
