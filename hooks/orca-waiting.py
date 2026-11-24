#!/usr/bin/env python3
"""Mark a chat's row in Orca's sidebar while it needs the user.

The project name becomes a red dot plus bold capitals, a chime plays once, and the tab name says
what the chat needs.
Both go back when the user replies. Runs on Stop, UserPromptSubmit and SessionEnd. A chat counts
as waiting when its last reply opens with the Action First "Waiting on you" block or ends with
the "Not done yet" banner's waiting line. Never blocks a chat: every failure is ignored.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

STATE_DIR = Path.home() / ("Library/Caches" if sys.platform == "darwin" else ".cache") / "orca-waiting"
NAMES_DIR = STATE_DIR / "names"
DOT = "🔴 "
MAX_NEED = 32
SOUND = "/System/Library/Sounds/Glass.aiff"
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


def orca(*args, check=False):
    binary = os.path.join(os.environ.get("ORCA_CLI_BIN_DIR", ""), "orca")
    done = subprocess.run([binary if os.path.exists(binary) else "orca", *args],
                          capture_output=True, text=True, timeout=5, check=check)
    return done.stdout


def worktree_of(handle):
    for terminal in json.loads(orca("terminal", "list", "--json"))["result"]["terminals"]:
        if terminal.get("handle") == handle:
            return terminal["worktreeId"]
    raise LookupError(handle)


def bold(text):
    """Orca has no font setting, so use Unicode's bold capital letters and digits."""
    out = ""
    for char in text.upper():
        if "A" <= char <= "Z":
            out += chr(0x1D5D4 + ord(char) - ord("A"))
        elif "0" <= char <= "9":
            out += chr(0x1D7EC + ord(char) - ord("0"))
        else:
            out += char
    return out


def saved_name(worktree):
    return NAMES_DIR / hashlib.sha256(worktree.encode()).hexdigest()


def show_dot(worktree):
    saved = saved_name(worktree)
    if saved.exists():
        return
    rows = json.loads(orca("worktree", "list", "--json"))["result"]["worktrees"]
    name = next(row["displayName"] for row in rows if row["id"] == worktree)
    if name.startswith(DOT):
        return  # Already marked, and saving this name would bring back a second dot later.
    NAMES_DIR.mkdir(parents=True, exist_ok=True)
    orca("worktree", "set", "--worktree", f"id:{worktree}", "--display-name", DOT + bold(name),
         check=True)
    saved.write_text(name, encoding="utf-8")


def clear_dot(worktree, marker):
    """Put the real name back once no other chat in this project is waiting."""
    others = [p for p in STATE_DIR.glob("term_*")
              if p != marker and p.read_text(encoding="utf-8") == worktree]
    saved = saved_name(worktree)
    if others or not saved.exists():
        return
    # Keep the saved name until the rename works, so a failed try is retried on the next reply.
    orca("worktree", "set", "--worktree", f"id:{worktree}",
         "--display-name", saved.read_text(encoding="utf-8"), check=True)
    saved.unlink()


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
            subprocess.Popen(["afplay", SOUND], start_new_session=True,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        worktree = worktree_of(handle)
        orca("terminal", "rename", "--terminal", handle, "--title", short_need(reply))
        marker.write_text(worktree, encoding="utf-8")
        show_dot(worktree)
    elif marker.exists():
        orca("terminal", "rename", "--terminal", handle)
        worktree = marker.read_text(encoding="utf-8")
        if worktree:
            clear_dot(worktree, marker)
        marker.unlink()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
