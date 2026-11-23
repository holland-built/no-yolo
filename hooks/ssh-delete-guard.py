#!/usr/bin/env python3
"""PreToolUse hook (Bash): ask the user only before an ssh command that could wreck a whole server.

CC Safety Net guards this computer but cannot read a command quoted inside `ssh host "..."`. The
user asked for a prompt only in the worst cases, because routine cleanup prompts were constant:
wiping a disk, a volume, a VM or container, a database, or a top-level folder. Everything else runs.
This is a word check, not a sandbox: it cannot see inside a script already on the server.
"""
import json
import re
import sys

SSH = re.compile(r"(?<![\w./-])(?:\S*/)?ssh(?=\s)")
CATASTROPHIC = re.compile(
    r"""(?ix)
    (?<![-\w.])(?:wipefs|mkfs(?:\.\w+)?|sgdisk|lvremove|vgremove|pvremove)(?![\w-])
    | (?<![-\w.])(?:fdisk|sfdisk|parted)(?![\w-])(?!\s+-l\b)
    | (?<![-\w.])shred\b[^\n;|&]*/dev/
    | (?<![-\w.])dd\b[^\n;|&]*\bof=/dev/(?!null\b)
    | >\s*/dev/(?:sd|nvme|vd|hd|mmcblk|disk)
    | \b(?:pct|qm|zfs|zpool)\s+(?:[^\s;|&]+\s+)*?destroy\b
    | \bpvesm\s+free\b
    | \bdocker\s+volume\s+(?:rm|prune)\b
    | \bdocker\s+system\s+prune\b[^\n;|&]*--volumes
    | \bdrop\s+database\b
    | --no-preserve-root\b
    """
)
# Checked on the unsplit text, because the pipe into a shell is what makes it a hidden script.
HIDDEN_SCRIPT = re.compile(
    r"""(?ix)
    \bbase64\s+(?:-\S+\s+)*-(?:\w*d\b|-decode\b)[^\n]*\|\s*(?:sudo\s+)?(?:ba|z)?sh\b
    | \bb64decode\b[^\n]*\|\s*(?:sudo\s+)?(?:ba|z)?sh\b
    """
)
ORCA_WORKTREE_RM = re.compile(r"\borca\s+worktree\s+rm\b")
READ_ONLY = {"cat", "cut", "echo", "grep", "head", "less", "ls", "sed", "stat", "tail", "wc"}
RM = re.compile(r"(?<![-\w.])rm\s+([^\n]*)")
FIND_DELETE = re.compile(r"\bfind\s+(\S+)[^\n]*\s-delete\b")
# Folders one level below the top that hold a whole system's data.
PROTECTED = {"/var/lib", "/usr/bin", "/usr/lib", "/usr/local", "/config/.storage"}
SAFE_TOP = {"/tmp"}


def split_commands(text):
    """Split on ; & | and newlines outside quotes. Quotes reset per line so a stray ' can't hide text."""
    parts, current, quote = [], "", None
    for char in text:
        if char == "\n":
            parts.append(current)
            current, quote = "", None
        elif quote:
            quote = None if char == quote else quote
            current += char
        elif char in "'\"":
            quote = char
            current += char
        elif char in ";&|":
            parts.append(current)
            current = ""
        else:
            current += char
    return parts + [current]


def only_reads(part):
    words = part.split()
    if not words or words[0] not in READ_ONLY:
        return False
    return not (words[0] == "sed" and any(w.startswith("-i") or w == "--in-place" for w in words))


def wipes_everything(target):
    """True for /, a top-level folder, home, the current folder, or a bare variable that may be empty."""
    target = target.strip("'\"")
    bare = re.sub(r"(?:/\*?|/\.\*?)+$", "", target)
    if bare in {"", ".", "..", "*", "~"} or re.fullmatch(r"\$\{?\w+\}?\*?", bare):
        return True
    if not target.startswith("/"):
        return False
    path = target.rstrip("*").rstrip("/")
    if path in SAFE_TOP:
        return False
    return path.count("/") <= 1 or path in PROTECTED


def wipes_a_system(command):
    """True if a recursive rm or find -delete aims at a whole system's folders."""
    opened = re.sub(r"(\bssh\b[^\n'\"]*)['\"]", r"\1;", command)
    for part in split_commands(opened):
        if only_reads(part):
            continue
        found = FIND_DELETE.search(part)
        if found and wipes_everything(found.group(1)):
            return True
        for match in RM.finditer(part):
            words = match.group(1).split()
            recursive = any(w == "--recursive" or re.fullmatch(r"-[a-zA-Z]*[rR][a-zA-Z]*", w) for w in words)
            if recursive and any(wipes_everything(w) for w in words if not w.startswith("-")):
                return True
    return False


def without_local_deletes(command):
    """Drop deletes that run on this Mac: `orca worktree rm`, and plain `rm` before the first ssh.

    Keeps the text unchanged if anything before ssh could carry a script to the server
    (a heredoc, or a quote spanning lines), because then an `rm` line may run remotely.
    """
    command = ORCA_WORKTREE_RM.sub("orca worktree", command)
    start = SSH.search(command).start()
    before = command[:start]
    if "<<" in before or any(line.count("'") % 2 or line.count('"') % 2 for line in before.split("\n")):
        return command
    parts = split_commands(before)
    kept = [p for p in parts if p.split()[:1] != ["rm"]]
    if len(kept) == len(parts):
        return command
    return "; ".join(kept + [command[start:]])


def is_catastrophic(command):
    if not SSH.search(command):
        return False
    checked = without_local_deletes(command)
    readable = "; ".join(p for p in split_commands(re.sub(r"(\bssh\b[^\n'\"]*)['\"]", r"\1;", checked))
                         if not only_reads(p))
    return bool(CATASTROPHIC.search(readable) or HIDDEN_SCRIPT.search(checked)) or wipes_a_system(checked)


def main():
    try:
        command = json.load(sys.stdin).get("tool_input", {}).get("command", "")
    except (ValueError, AttributeError):
        return
    if not isinstance(command, str) or not is_catastrophic(command):
        return
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": "This ssh command could wipe a disk, system or database on a server.",
    }}))


if __name__ == "__main__":
    main()
