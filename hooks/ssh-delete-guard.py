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
    | \bdestroy\b | \bpurge\b | \bprune\b
    | \bpvesm\s+free\b
    | \bgit\s+(?:reset\s+--hard|clean\b|push\b.*(?:--force|\s-f\b))
    | \bdocker\s+(?:\S+\s+)?(?:rm|rmi)\b
    | \b(?:drop\s+(?:table|database)|delete\s+from)\b
    | >\s*/dev/(?:sd|nvme|vd|disk)
    | \b(?:ba|z)?sh\s+-s\b | \bbase64\b
    """
)


def main():
    try:
        command = json.load(sys.stdin).get("tool_input", {}).get("command", "")
    except (ValueError, AttributeError):
        return
    if not isinstance(command, str) or not SSH.search(command) or not RISKY.search(command):
        return
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": "This ssh command may delete or wipe something on a server.",
    }}))


if __name__ == "__main__":
    main()
