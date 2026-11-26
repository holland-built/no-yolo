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
    usually not an ancestor), or its exact tip is one of the commits of such a PR (the main
    chat often ships a builder's work from a new `<branch>-pr` branch built on top of it)
  - `git status --porcelain` in it is empty
  - Orca saw no activity in it for MIN_IDLE_MIN minutes
  - its HEAD, read again just before removal, is still the commit that was checked
Everything else is left and logged with the reason.

Usage: orca-sweep.py [--dry-run]
"""
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

# ORCA_BIN lets the tests swap in a fake orca
ORCA = (os.environ.get("ORCA_BIN") or shutil.which("orca")
        or "/Applications/Orca.app/Contents/Resources/bin/orca")
LOG = Path.home() / ".claude/state/orca-sweep.log"
MIN_IDLE_MIN = 60
DRY = "--dry-run" in sys.argv
# How many recent merged PRs pr_commits() asks for. GitHub refuses a bigger list with
# commits (each commit carries its authors, and 50 PRs already pass its 500,000-node cap),
# and a builder copy is normally swept within days of its PR.
PR_COMMITS_LIMIT = 30
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


def pr_commits(repo, timeout=30):
    """Commits of the PR_COMMITS_LIMIT most recently merged PRs of the repo at `repo`, as
    {commit: [(number, branch it merged into, merge commit or None)]}.

    Returns {} when gh fails, so nothing is treated as merged by it.
    """
    try:
        res = run(["gh", "pr", "list", "--state", "merged", "--limit", str(PR_COMMITS_LIMIT),
                   "--json", "number,baseRefName,mergeCommit,commits"], cwd=repo, timeout=timeout)
        if res.returncode != 0:
            return {}
        out = {}
        for pr in json.loads(res.stdout or "[]"):
            merge = pr.get("mergeCommit")
            merge = merge.get("oid") if isinstance(merge, dict) else None
            for c in pr.get("commits") or []:
                out.setdefault(c["oid"], []).append((pr["number"], pr["baseRefName"], merge))
        return out
    except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired):
        return {}


def branch_tip(repo, branch, timeout=30):
    """The commit `branch` points at in the repo at `repo`, or None."""
    res = run(["git", "rev-parse", "--verify", "--quiet", f"refs/heads/{branch}^{{commit}}"],
              cwd=repo, timeout=timeout)
    return res.stdout.strip() if res.returncode == 0 and res.stdout.strip() else None


def is_merged(repo, branch, base, prs, tip, timeout=30, commits=None):
    """How commit `tip` of `branch` is merged into `base` in the repo at `repo`, or None.

    "ancestor": every commit on the branch is in base.
    "PR #n": a merged PR came from this branch into base's branch, its head commit is the
    branch tip, and its merge commit is in base, so the squash-merged work is in base here
    and commits added after the merge are not lost. A PR merged into some other branch (a
    stacked PR), or one whose merge commit this repo's base does not have yet, does not count.
    "tip in merged PR #n": `commits` (pr_commits(repo)) is given and `tip` is one of the
    commits of PR #n, and its merge commit is in base (PR into base's branch) or in main or
    master (PR into that branch). Everything up to the tip is then in that branch, even though
    the PR's head is a later commit on another branch.
    `prs` is merged_prs(repo); `tip` is branch_tip(), so the caller deletes the commit checked.
    """
    def in_ref(oid, ref):
        return run(["git", "merge-base", "--is-ancestor", oid, ref], cwd=repo,
                   timeout=timeout).returncode == 0

    def in_base(oid):
        return in_ref(oid, base)

    if in_base(tip):
        return "ancestor"
    full = run(["git", "rev-parse", "--symbolic-full-name", base], cwd=repo, timeout=timeout)
    # refs/heads/main -> main; refs/remotes/origin/main -> main. None when base is gone (a
    # builder cut from another builder's branch that was deleted after it shipped).
    parts = full.stdout.strip().split("/") if full.returncode == 0 else []
    base_name = "/".join(parts[2:] if parts[:2] == ["refs", "heads"] else parts[3:]) or None
    for number, head, pr_base, merge in prs.get(branch, []):
        if head == tip and pr_base == base_name and merge and in_base(merge):
            return f"PR #{number}"
    for number, pr_base, merge in (commits or {}).get(tip, []):
        # The copy may have been cut from another builder's branch while its work shipped to
        # main, so a PR into main or master also counts once the merge commit is there.
        targets = [base] if pr_base == base_name else []
        if pr_base in ("main", "master"):
            targets += [pr_base, f"origin/{pr_base}"]
        if merge and any(in_ref(merge, ref) for ref in targets):
            return f"tip in merged PR #{number}"
    return None


def main(dry=None, log=log, deadline=None, timeout=120):
    """Sweep finished child worktrees. session-tidy.py calls this with its own log."""
    dry = DRY if dry is None else dry
    if not os.path.exists(ORCA):
        log("skip: Orca is not installed")
        return
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
    commits_by_repo = {}

    for w in items:
        if deadline and time.time() > deadline:
            log("stop: out of time, the rest is checked next run")
            return
        try:
            sweep_one(w, by_id, prs_by_repo, commits_by_repo, dry, log, timeout)
        except subprocess.TimeoutExpired:
            log(f"stop: out of time at {w.get('displayName')}, the rest is checked next run")
            return


def sweep_one(w, by_id, prs_by_repo, commits_by_repo, dry, log, timeout):
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
    if tip and not how:
        # Fetched only now, and once per repo, because the list with commits is the slow call.
        if repo not in commits_by_repo:
            commits_by_repo[repo] = pr_commits(repo, timeout)
        how = is_merged(repo, branch, base, prs_by_repo[repo], tip, timeout,
                        commits=commits_by_repo[repo])
    if not how:
        log(f"keep {name}: {branch} is not merged into {base} and its tip is in no merged PR")
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
