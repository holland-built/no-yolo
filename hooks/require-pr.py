#!/usr/bin/env python3
"""PreToolUse hook (Bash): block a git push straight to main or master.

The user wants every change shipped through a pull request, so CI, the Codex review and the
merge rule in CLAUDE.md §0 always run. A push of a feature branch passes; a push whose target
is main/master, or a bare `git push` from main/master, is denied with the way to do it instead.

Exempt: the public no-yolo mirror (by its origin URL), which a sync script pushes to main.
This is a guard against ordinary pushes, not a sandbox: `bash -c '...'` and the like get past it.
"""
import json
import os
import re
import shlex
import subprocess
import sys

EXEMPT_REPOS = {"no-yolo"}
PROTECTED = {"main", "master"}


def deny(reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }}))
    sys.exit(0)


def deny_push(what):
    deny(
        f"Pushing straight to {what} is blocked: every change ships through a pull request. "
        "Create a branch (git switch -c <name>), push it (git push -u origin <name>), open the "
        "PR (gh pr create --fill), then follow CLAUDE.md §0 to merge."
    )


def strip(text, prefix):
    return text[len(prefix):] if text.startswith(prefix) else text


def is_exempt(repo):
    """The no-yolo mirror, recognised by its GitHub remote, not just its folder name."""
    url = git(repo, "remote", "get-url", "origin")
    url = url[:-4] if url.endswith(".git") else url
    return any(url.endswith("/" + name) for name in EXEMPT_REPOS)


def git(cwd, *args):
    try:
        r = subprocess.run(["git", "-C", cwd, *args], capture_output=True, text=True, timeout=5)
        return r.stdout.strip() if r.returncode == 0 else ""
    except Exception:
        return ""


def main():
    data = json.load(sys.stdin)
    cmd = (data.get("tool_input") or {}).get("command", "")
    if "push" not in cmd or "git" not in cmd:
        return
    cwd = data.get("cwd") or os.getcwd()

    # Each piece of a compound command, tracking `cd` so the branch is read in the right repo.
    for part in re.split(r"&&|\|\||;|\n", cmd):
        try:
            words = shlex.split(part)
        except ValueError:
            words = part.split()
        if not words:
            continue
        if words[0] == "cd" and len(words) > 1:
            target = os.path.expanduser(words[1])
            cwd = target if os.path.isabs(target) else os.path.join(cwd, target)
            continue
        while words and words[0] in ("command", "exec", "env", "nohup", "time"):
            words = words[1:]
        if not words or os.path.basename(words[0]) != "git":
            continue
        # skip git's own options (-C dir, -c key=val) to find the subcommand
        i, repo = 1, cwd
        while i < len(words) and words[i].startswith("-"):
            if words[i] == "-C" and i + 1 < len(words):
                repo = os.path.join(repo, os.path.expanduser(words[i + 1]))
                i += 2
            elif words[i] == "-c" and i + 1 < len(words):
                i += 2
            else:
                i += 1
        if i >= len(words) or words[i] != "push":
            continue

        if is_exempt(repo):
            continue
        opts = words[i + 1:]
        if any(o in ("--all", "--mirror", "--branches") for o in opts):
            deny_push("every branch at once (--all/--mirror), which includes main")
        remote_given = any(o.startswith("--repo") for o in opts)
        args, skip = [], False
        for o in opts:
            if skip:
                skip = False
                continue
            if o in ("--repo", "-o", "--push-option", "--receive-pack", "--exec"):
                skip = True  # option that takes the next word as its value
                continue
            if not o.startswith("-"):
                args.append(o)
        refspecs = args if remote_given else args[1:]
        targets = set()
        it = iter(refspecs)
        for r in it:
            if r == "tag":
                next(it, None)  # "tag <name>" pushes a tag, not a branch
                continue
            dst = strip(strip(r.split(":")[-1], "+"), "refs/heads/")
            if dst == "HEAD":
                dst = git(repo, "branch", "--show-current")
            targets.add(dst)
        if not refspecs and "--tags" in opts:
            continue  # pushing tags only (a release) is fine
        if not refspecs:
            # a bare push goes where git's push settings say, not always the same-named branch
            dest = git(repo, "rev-parse", "--abbrev-ref", "@{push}")
            targets.add(dest.split("/", 1)[-1] if dest else git(repo, "branch", "--show-current"))
        hit = targets & PROTECTED
        if hit:
            deny_push(hit.pop())


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass  # a broken hook must never block unrelated work
