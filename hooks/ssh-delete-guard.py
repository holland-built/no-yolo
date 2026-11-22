#!/usr/bin/env python3
"""PreToolUse hook (Bash): ask the user before a risky command goes over ssh.

CC Safety Net guards this computer but cannot read a command quoted inside `ssh host "..."`, and
a server can hold things that cannot be rebuilt. Any ssh command with a delete, wipe or
hidden-script word gets a permission prompt; every other ssh command just runs.
This is a word check, not a sandbox: it cannot see inside a script already on the server.
"""
import json
import re
import sys

SSH = re.compile(r"(?<![\w./-])(?:\S*/)?ssh(?=\s)")
RISKY = re.compile(
    r"""(?ix)
    (?<![-\w.])(?:rm|rmdir|unlink|shred|wipefs|mkfs(?:\.\w+)?|dd|truncate|sfdisk|fdisk|parted|
        lvremove|vgremove|pvremove|rmi)(?![\w-])
    | \bfind\b.*\s-delete\b
    | \b(?:pct|qm|zfs|zpool)\s+(?:\S+\s+)*?destroy\b
    | \bpvesm\s+free\b
    | \bgit\s+(?:reset\s+--hard|clean\b|push\b.*(?:--force|\s-f\b))
    | \bdocker\s+(?:\S+\s+)?(?:rm|rmi)\b
    | \b(?:drop\s+(?:table|database)|delete\s+from)\b
    | >\s*/dev/(?:sd|nvme|vd|disk)
    | \b(?:ba|z)?sh\s+-s\b(?![^\n]*<<-?\s*['"\\])
    | \bbase64\s+(?:-\S+\s+)*-(?:\w*d\b|-decode\b)
    | \bb64decode\b[^\n]*\|\s*(?:sudo\s+)?(?:ba|z)?sh\b
    """
)
ORCA_WORKTREE_RM = re.compile(r"\borca\s+worktree\s+rm\b")
# A quoted heredoc (<<'EOF') is exempt above because its whole script is in the command and scanned.
DELETE_WORD = re.compile(r"(?i)\b(?:destroy|purge|prune)\b")
READ_ONLY = {"cat", "cut", "echo", "grep", "head", "less", "ls", "sed", "stat", "tail", "wc"}
PIPED_TO_RUNNER = re.compile(r"\|\s*(?:sudo\s+)?(?:(?:ba|z)?sh|xargs)\b")


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


def names_delete_word(command):
    """True if destroy/purge/prune appears anywhere except as text a read-only command only reads."""
    if PIPED_TO_RUNNER.search(command):
        return bool(DELETE_WORD.search(command))
    # Open the quote after `ssh host` so the commands inside it are checked one by one.
    unquoted = re.sub(r"(\bssh\b[^\n'\"]*)['\"]", r"\1;", command)
    return any(DELETE_WORD.search(p) for p in split_commands(unquoted) if not only_reads(p))


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


def main():
    try:
        command = json.load(sys.stdin).get("tool_input", {}).get("command", "")
    except (ValueError, AttributeError):
        return
    if not isinstance(command, str) or not SSH.search(command):
        return
    checked = without_local_deletes(command)
    if not RISKY.search(checked) and not names_delete_word(checked):
        return
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": "This ssh command may delete or wipe something on a server.",
    }}))


if __name__ == "__main__":
    main()
