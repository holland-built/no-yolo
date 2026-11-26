#!/usr/bin/env python3
"""Tidy git when a Claude Code session starts, in place of a timer.

A SessionStart hook runs this with the hook's JSON on stdin; only its `cwd` field is used.
It does three things and logs every decision to ~/.claude/state/session-tidy.log:

  1. Orca copies: runs the sweep from orca-sweep.py (finished, merged, clean, idle builder
     copies are removed).
  2. Old branches in the session's repo: deletes local branches that are merged (an
     ancestor of the default branch, or the head of a merged PR whose head commit is the
     branch tip and whose merge commit is in the default branch), not checked out in any
     worktree, not current, and not main/master. The delete is `git update-ref -d` with the
     commit that was checked, so a branch that moved since then is kept.
  0. Orca's own skills: the user removed them on 2026-11-26 and does not want Orca running the
     work, and Orca has no setting that stops it reinstalling them. Any it put back in
     ~/.agents/skills are moved to the Trash, and their links in ~/.claude/skills removed.
  3. Catch up with GitHub: `git fetch`, then `git merge --ff-only` when the current branch
     has an upstream, no changed tracked files, and is only behind. When it is ahead or has
     diverged, prints one line to stdout, which Claude sees as session context.

It never pushes, resets, stashes, rebases or pulls, never raises (a failure is logged, not
shown) and stops starting new work after BUDGET seconds.

Usage: session-tidy.py [--dry-run] < hook.json
"""
import importlib.util
import json
import os
import subprocess
import tempfile
import sys
import time
import traceback
from pathlib import Path

LOG = Path.home() / ".claude/state/session-tidy.log"
BUDGET = 15  # seconds; the hook should finish in under ~20
ORCA_BUDGET = 6  # seconds of BUDGET the Orca sweep may use, so the session's repo gets the rest
STEP_TIMEOUT = 8  # seconds for any one git/gh/orca call
START = time.time()
DEADLINE = START + BUDGET  # no git, gh or orca call starts or runs past this
DRY = "--dry-run" in sys.argv
PROTECTED = {"main", "master"}


def log(msg):
    try:
        LOG.parent.mkdir(parents=True, exist_ok=True)
        with LOG.open("a") as f:
            f.write(f"{time.strftime('%Y-%m-%dT%H:%M:%S')} {'[dry-run] ' if DRY else ''}{msg}\n")
    except OSError:
        pass


def left():
    """Seconds the next call may take; TimeoutExpired once the budget is spent."""
    remaining = DEADLINE - time.time()
    if remaining <= 0:
        raise subprocess.TimeoutExpired("session-tidy", 0)
    return min(STEP_TIMEOUT, remaining)


def git(repo, *args):
    return subprocess.run(["git", *args], cwd=repo, capture_output=True, text=True,
                          timeout=left(), env={**os.environ, "GIT_TERMINAL_PROMPT": "0"})


def load_sweep():
    path = Path(__file__).resolve().parent / "orca-sweep.py"
    spec = importlib.util.spec_from_file_location("orca_sweep", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def sweep_orca(sweep):
    sweep.DEADLINE = min(DEADLINE, START + ORCA_BUDGET)
    try:
        sweep.main(dry=DRY, log=lambda m: log(f"orca: {m}"), deadline=sweep.DEADLINE,
                   timeout=STEP_TIMEOUT)
    finally:
        sweep.DEADLINE = DEADLINE  # its merged test is reused for branches below


def default_base(repo):
    """The branch merged work lands on: origin's default branch, else local main/master."""
    res = git(repo, "symbolic-ref", "--quiet", "refs/remotes/origin/HEAD")
    if res.returncode == 0 and res.stdout.strip():
        return res.stdout.strip().removeprefix("refs/remotes/")
    for name in ("origin/main", "origin/master", "main", "master"):
        if git(repo, "rev-parse", "--verify", "--quiet", name).returncode == 0:
            return name
    return None


def tidy_branches(sweep, repo, current):
    base = default_base(repo)
    if not base:
        log(f"branches: skip {repo}: no main or master to compare with")
        return
    wt = git(repo, "worktree", "list", "--porcelain")
    checked_out = {line.split(" ", 1)[1].removeprefix("refs/heads/")
                   for line in wt.stdout.splitlines() if line.startswith("branch ")}
    res = git(repo, "for-each-ref", "--format=%(refname:short)", "refs/heads/")
    prs = None
    for branch in res.stdout.split():
        if time.time() > DEADLINE:
            log("branches: stop: out of time, the rest is checked next session")
            return
        if branch in PROTECTED or branch == current:
            continue
        if branch in checked_out:
            log(f"branches: keep {branch}: checked out in a worktree")
            continue
        if prs is None:
            prs = sweep.merged_prs(repo, timeout=left())
        tip = sweep.branch_tip(repo, branch, timeout=left())
        how = tip and sweep.is_merged(repo, branch, base, prs, tip, timeout=left())
        if not how:
            log(f"branches: keep {branch}: not merged into {base}")
            continue
        if DRY:
            log(f"branches: would delete {branch} (merged: {how})")
            continue
        # Deletes only if the branch still points at the commit checked above.
        rm = git(repo, "update-ref", "-d", f"refs/heads/{branch}", tip)
        if rm.returncode == 0:
            git(repo, "config", "--remove-section", f"branch.{branch}")  # as git branch -d does
            log(f"branches: deleted {branch} (merged into {base}: {how})")
        else:
            log(f"branches: keep {branch}: it moved since the check, or git refused "
                f"({rm.stderr.strip()[:160]})")


def catch_up(repo, current):
    """Fetch, then fast-forward or say why not. Returns the line for Claude, or None."""
    if DRY:
        log("sync: would run git fetch (dry run compares with the refs already fetched)")
    else:
        fetch = git(repo, "fetch", "--quiet")
        if fetch.returncode != 0:
            log(f"sync: fetch failed ({fetch.stderr.strip()[:160]})")
            return None
    if not current:
        log("sync: skip: detached HEAD")
        return None
    up = git(repo, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}")
    if up.returncode != 0:
        log(f"sync: skip {current}: no upstream")
        return None
    upstream = up.stdout.strip()
    counts = git(repo, "rev-list", "--left-right", "--count", f"HEAD...{upstream}")
    if counts.returncode != 0:
        log(f"sync: skip {current}: could not compare with {upstream}")
        return None
    ahead, behind = (int(n) for n in counts.stdout.split())
    if ahead and behind:
        log(f"sync: {current} diverged: {behind} behind, {ahead} ahead of {upstream}; left alone")
        return (f"Git: {current} is {behind} behind and {ahead} ahead of {upstream}; "
                "sync before starting work.")
    if ahead:
        log(f"sync: {current} is {ahead} ahead of {upstream}; left alone")
        return f"Git: {current} is {ahead} ahead of {upstream} (not pushed); push or open a PR."
    if not behind:
        log(f"sync: {current} is up to date with {upstream}")
        return None
    # Untracked files are not counted here: git merge refuses to overwrite untracked files,
    # and --no-overwrite-ignore below makes it refuse for ignored files too.
    dirty = git(repo, "status", "--porcelain", "--untracked-files=no")
    if dirty.returncode != 0 or dirty.stdout.strip():
        log(f"sync: {current} is {behind} behind {upstream} but has changed files; left alone")
        return None
    if DRY:
        log(f"sync: would fast-forward {current} by {behind} commit(s) from {upstream}")
        return None
    ff = git(repo, "merge", "--ff-only", "--no-overwrite-ignore", "--quiet", upstream)
    if ff.returncode == 0:
        log(f"sync: fast-forwarded {current} by {behind} commit(s) from {upstream}")
    else:
        log(f"sync: fast-forward of {current} failed ({ff.stderr.strip()[:160]})")
    return None


ORCA_SKILLS = ("orca-cli", "orca-computer-use", "orchestration")


def park_orca_skills():
    """Move Orca's own skills to the Trash if Orca reinstalled them. Moves, never deletes."""
    home = Path.home()
    shared, claude = home / ".agents/skills", home / ".claude/skills"
    trash = home / ".Trash"
    for name in ORCA_SKILLS:
        link = claude / name
        # Only a link into Orca's copy is Orca's; any other link with this name is the user's.
        if link.is_symlink() and os.path.normpath(os.path.join(claude, os.readlink(link))) == str(shared / name):
            if not DRY:
                link.unlink()
            log(f"orca skills: removed link {link}")
        src = shared / name
        if src.is_dir() and not src.is_symlink():
            if not DRY:
                trash.mkdir(exist_ok=True)
                # a new folder per move, so a second reinstall never collides with the first
                dest = Path(tempfile.mkdtemp(prefix=f"orca-skill-{name}-", dir=trash)) / name
                src.rename(dest)
            log(f"orca skills: moved {name} to the Trash")


def step(name, fn, *args):
    try:
        return fn(*args)
    except subprocess.TimeoutExpired:
        log(f"{name}: stop: out of time, the rest runs next session")
        return None
    except Exception as e:  # noqa: BLE001 - a hook must never fail the session
        log(f"{name}: error {type(e).__name__}: {str(e)[:200]}")
        return None


def main():
    log("start")
    try:
        data = json.loads(sys.stdin.read() or "{}")
        cwd = data.get("cwd") if isinstance(data, dict) else None
    except (ValueError, OSError) as e:
        log(f"bad hook input ({e}); only the Orca sweep runs")
        cwd = None

    step("orca skills", park_orca_skills)
    sweep = step("load orca-sweep", load_sweep)
    if sweep:
        step("orca", sweep_orca, sweep)

    repo = None
    if cwd and Path(cwd).is_dir():
        top = step("repo", git, cwd, "rev-parse", "--show-toplevel")
        if top and top.returncode == 0:
            repo = top.stdout.strip()
    if not repo:
        log(f"no git repo at {cwd!r}; branch tidy and sync skipped")
    else:
        log(f"repo {repo}")
        head = step("head", git, repo, "symbolic-ref", "--quiet", "--short", "HEAD")
        current = head.stdout.strip() if head and head.returncode == 0 else None
        # Sync first so the branch test compares with an up-to-date origin.
        line = step("sync", catch_up, repo, current)
        if sweep:
            step("branches", tidy_branches, sweep, repo, current)
        if line:
            print(line)
    log(f"done in {time.time() - START:.1f}s")


if __name__ == "__main__":
    try:
        main()
    except Exception:  # noqa: BLE001
        log("fatal: " + traceback.format_exc().strip().splitlines()[-1][:200])
    sys.exit(0)
