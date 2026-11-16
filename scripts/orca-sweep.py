#!/usr/bin/env python3
"""Remove finished Orca builder copies (child worktrees) that are safe to delete.

Orca closes a finished builder's tab on its own but never deletes its worktree, so copies
pile up in the sidebar whenever the managing chat closes before its Done step. session-tidy.py
runs this at the start of every Claude session, so no timer is needed.

tools/session-tidy.py also runs this sweep when a Claude Code session starts.

A child worktree is removed only when all of these hold, so unmerged or unsaved work is
never lost and a builder that is still working is never pulled out from under it:
  - its branch is merged (see is_merged): an ancestor of the branch it was cut from
    (baseRef), or the head of a merged GitHub PR whose head commit is the branch tip and
    whose merge commit is in baseRef (PRs here are squash-merged, so a merged branch is
    usually not an ancestor)
  - `git status --porcelain` in it is empty
  - Orca saw no activity in it for MIN_IDLE_MIN minutes
  - its HEAD, read again just before removal, is still the commit that was checked
Everything else is left and logged with the reason.

Usage: orca-sweep.py [--dry-run]
"""
import json
import os
import subprocess
import sys
import time
from pathlib import Path

# ORCA_BIN lets the tests swap in a fake orca
ORCA = os.environ.get("ORCA_BIN", "/Applications/Orca.app/Contents/Resources/bin/orca")
LOG = Path.home() / ".claude/state/orca-sweep.log"
MIN_IDLE_MIN = 60
DRY = "--dry-run" in sys.argv
DEADLINE = None  # time.time() after which run() starts nothing; session-tidy.py sets it


def log(msg):
    line = f"{time.strftime('%Y-%m-%dT%H:%M:%S')} {msg}"
    print(line)
    with LOG.open("a") as f:
        f.write(line + "\n")


def run(args, cwd=None, timeout=120):
    """Run a command; with DEADLINE set, no call runs past it (TimeoutExpired instead)."""
    if DEADLINE is not None:
        remaining = DEADLINE - time.time()
        if remaining <= 0:
            raise subprocess.TimeoutExpired(args, 0)
        timeout = min(timeout, remaining)
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout)


def merged_prs(repo, timeout=30):
    """Merged GitHub PRs of the repo at `repo`, as
    {head branch: [(number, head commit, branch it merged into, merge commit or None)]}.

    One `gh pr list` call per repo instead of one per branch, to stay fast. Returns {} when
    gh fails (no remote, offline, not logged in), so nothing is treated as merged by PR.
    """
    try:
        res = run(["gh", "pr", "list", "--state", "merged", "--limit", "500",
                   "--json", "number,headRefName,headRefOid,baseRefName,mergeCommit"],
                  cwd=repo, timeout=timeout)
        if res.returncode != 0:
            return {}
        prs = {}
        for pr in json.loads(res.stdout or "[]"):
            merge = pr.get("mergeCommit")
            merge = merge.get("oid") if isinstance(merge, dict) else None
            prs.setdefault(pr["headRefName"], []).append(
                (pr["number"], pr["headRefOid"], pr["baseRefName"], merge))
        return prs
    except (OSError, ValueError, KeyError, subprocess.TimeoutExpired):
        return {}


def branch_tip(repo, branch, timeout=30):
    """The commit `branch` points at in the repo at `repo`, or None."""
    res = run(["git", "rev-parse", "--verify", "--quiet", f"refs/heads/{branch}^{{commit}}"],
              cwd=repo, timeout=timeout)
    return res.stdout.strip() if res.returncode == 0 and res.stdout.strip() else None


def is_merged(repo, branch, base, prs, tip, timeout=30):
    """How commit `tip` of `branch` is merged into `base` in the repo at `repo`, or None.

    "ancestor": every commit on the branch is in base.
    "PR #n": a merged PR came from this branch into base's branch, its head commit is the
    branch tip, and its merge commit is in base, so the squash-merged work is in base here
    and commits added after the merge are not lost. A PR merged into some other branch (a
    stacked PR), or one whose merge commit this repo's base does not have yet, does not count.
    `prs` is merged_prs(repo); `tip` is branch_tip(), so the caller deletes the commit checked.
    """
    def in_base(oid):
        return run(["git", "merge-base", "--is-ancestor", oid, base], cwd=repo,
                   timeout=timeout).returncode == 0

    if in_base(tip):
        return "ancestor"
    full = run(["git", "rev-parse", "--symbolic-full-name", base], cwd=repo, timeout=timeout)
    if full.returncode != 0:
        return None
    # refs/heads/main -> main; refs/remotes/origin/main -> main
    parts = full.stdout.strip().split("/")
    base_name = "/".join(parts[2:] if parts[:2] == ["refs", "heads"] else parts[3:])
    for number, head, pr_base, merge in prs.get(branch, []):
        if head == tip and pr_base == base_name and merge and in_base(merge):
            return f"PR #{number}"
    return None


def main(dry=None, log=log, deadline=None, timeout=120):
    """Sweep finished child worktrees. session-tidy.py calls this with its own log."""
    dry = DRY if dry is None else dry
    res = run([ORCA, "worktree", "list", "--json"], timeout=timeout)
    if res.returncode != 0:
        log(f"skip: orca not reachable ({res.stderr.strip()[:120]})")
        return
    data = json.loads(res.stdout)
    items = data.get("result", data)
    if isinstance(items, dict):
        items = items.get("worktrees", [])
    by_id = {w["id"]: w for w in items}
    prs_by_repo = {}

    for w in items:
        if deadline and time.time() > deadline:
            log("stop: out of time, the rest is checked next run")
            return
        try:
            sweep_one(w, by_id, prs_by_repo, dry, log, timeout)
        except subprocess.TimeoutExpired:
            log(f"stop: out of time at {w.get('displayName')}, the rest is checked next run")
            return


def sweep_one(w, by_id, prs_by_repo, dry, log, timeout):
    """Check one worktree from `orca worktree list` and remove it if it is finished."""
    parent_id = w.get("parentWorktreeId")
    if not parent_id or w.get("isMainWorktree"):
        return
    name = w.get("displayName")
    path = w.get("path")
    branch = (w.get("branch") or "").removeprefix("refs/heads/")
    base = w.get("baseRef")
    parent = by_id.get(parent_id)
    if not (path and branch and base and parent and Path(path).is_dir()):
        log(f"keep {name}: missing path, branch, base or parent")
        return

    last = w.get("lastActivityAt")
    if not last:
        log(f"keep {name}: Orca has no activity time for it")
        return
    idle_min = (time.time() * 1000 - last) / 60000
    if idle_min < MIN_IDLE_MIN:
        log(f"keep {name}: active {idle_min:.0f} min ago (waits {MIN_IDLE_MIN})")
        return

    repo = parent["path"]
    if repo not in prs_by_repo:
        prs_by_repo[repo] = merged_prs(repo, timeout)
    tip = branch_tip(repo, branch, timeout)
    how = tip and is_merged(repo, branch, base, prs_by_repo[repo], tip, timeout)
    if not how:
        log(f"keep {name}: {branch} is not merged into {base} and has no merged PR at its tip")
        return

    dirty = run(["git", "status", "--porcelain", "--untracked-files=all"], cwd=path,
                timeout=timeout)
    if dirty.returncode != 0 or dirty.stdout.strip():
        n = len(dirty.stdout.strip().splitlines())
        log(f"keep {name}: {n} unsaved file(s)")
        return

    if dry:
        log(f"would remove {name} ({branch}, merged: {how})")
        return
    # A commit made since the checks above would be lost with the branch, so check again.
    now = run(["git", "rev-parse", "HEAD"], cwd=path, timeout=timeout)
    if now.returncode != 0 or now.stdout.strip() != tip:
        log(f"keep {name}: {branch} moved since it was checked")
        return
    # No --force: git refuses to remove a copy that changed since the checks above, and
    # --delete-branch keeps any branch Orca cannot prove is merged.
    rm = run([ORCA, "worktree", "rm", "--worktree", f"id:{w['id']}", "--delete-branch"],
             timeout=timeout)
    if rm.returncode == 0:
        log(f"removed {name} ({branch}, merged into {base}: {how})")
    else:
        log(f"keep {name}: rm failed ({rm.stderr.strip()[:160]})")


if __name__ == "__main__":
    LOG.parent.mkdir(parents=True, exist_ok=True)
    main()
