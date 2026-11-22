#!/usr/bin/env python3
"""PreToolUse hook (Bash): block a git push straight to main or master.

Every change ships through a pull request, so CI and review always run. A push of a feature
branch passes; a push whose target is main/master, or a bare `git push` from main/master, is
denied with the way to do it instead. A PR that touches risky code must be reviewed first.

Optional extra patterns live in ~/.claude/risky-extra.txt, one per line: `risky: <regex>` adds a
risky path, `skip: <regex>` adds a path that needs no review. A bare line counts as risky.
This is a guard against ordinary pushes, not a sandbox: `bash -c '...'` and the like get past it.
"""
import json
import os
import re
import shlex
import subprocess
import sys

PROTECTED = {"main", "master"}
REVIEW_DIR = os.path.expanduser("~/.claude/state/risky-review")
EXTRA_FILE = os.path.expanduser("~/.claude/risky-extra.txt")
RISKY_WORDS = (r"updat|upgrad|apply|delet|remov|teardown|migrat|auth|login|signin|sso|"
               r"session|passw|secret|token|vault")
SKIP_WORDS = r"_test\.|\.test\.|\.spec\.|/tests?/|/e2e/|/dist/|\.md$|package-lock\.json$|go\.sum$"


def extra_patterns():
    """Read the optional private list. A pattern that is not valid regex is matched literally."""
    risky, skip = [], []
    try:
        with open(EXTRA_FILE, encoding="utf-8") as extra:
            lines = [line.strip() for line in extra]
    except (OSError, UnicodeDecodeError):
        return risky, skip
    for line in lines:
        if not line or line.startswith("#") or line.startswith("built:"):
            continue
        kind, _, value = line.partition(":") if line.startswith(("risky:", "skip:")) else ("risky", "", line)
        value = value.strip()
        try:
            re.compile(value)
        except re.error:
            value = re.escape(value)
        if value:
            (skip if kind == "skip" else risky).append(value)
    return risky, skip


_extra_risky, _extra_skip = extra_patterns()
RISKY = re.compile("|".join([RISKY_WORDS, *_extra_risky]), re.I)
NOT_REVIEWED = re.compile("|".join([SKIP_WORDS, *_extra_skip]), re.I)


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
        "PR (gh pr create --fill), then follow your merge rules."
    )


def strip(text, prefix):
    return text[len(prefix):] if text.startswith(prefix) else text


def git(cwd, *args):
    try:
        r = subprocess.run(["git", "-C", cwd, *args], capture_output=True, text=True, timeout=5)
        return r.stdout.strip() if r.returncode == 0 else ""
    except Exception:
        return ""


def require_risky_review(cmd, cwd):
    """Before a PR opens on a risky change, require one Claude review of that exact commit.

    A review costs real tokens, so it runs only where a miss is expensive.
    """
    if not re.search(r"\bgh\s+pr\s+create\b", cmd):
        return
    match = re.search(r"(?:^|[;&|\n]\s*)cd\s+(\"[^\"]+\"|'[^']+'|\S+)", cmd)
    if match:
        target = os.path.expanduser(match.group(1).strip("\"'"))
        cwd = target if os.path.isabs(target) else os.path.join(cwd, target)
    head = git(cwd, "rev-parse", "HEAD")
    base = git(cwd, "symbolic-ref", "--short", "refs/remotes/origin/HEAD")
    if not head or not base:
        return
    risky = [f for f in git(cwd, "diff", "--name-only", f"{base}...HEAD").splitlines()
             if RISKY.search(f) and not NOT_REVIEWED.search(f)]
    marker = os.path.join(REVIEW_DIR, head)
    if not risky or os.path.exists(marker):
        return
    deny(
        f"This change touches risky code ({', '.join(risky[:5])}). Before opening the PR, run "
        f"`python3 ~/.claude/tools/ocr-review.py {base}`, which prints a folder with files.txt and "
        "rules.json. Then start one fresh read-only Claude reviewer (Agent tool, subagent_type "
        f"Plan) on `git diff {base}...HEAD`, telling it to review every file in files.txt against "
        "its rule group in rules.json and report only defects that break the intended case. If "
        "the script fails or says the network block is unavailable, do not run the tool another "
        "way: review every changed file by hand and say so. Check each finding against the code and "
        "fix the real ones, committing the fixes. Then "
        f"run `mkdir -p {REVIEW_DIR} && touch {REVIEW_DIR}/$(git rev-parse HEAD)` and open the PR."
    )


def main():
    data = json.load(sys.stdin)
    cmd = (data.get("tool_input") or {}).get("command", "")
    cwd = data.get("cwd") or os.getcwd()
    require_risky_review(cmd, cwd)
    if "push" not in cmd or "git" not in cmd:
        return

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
