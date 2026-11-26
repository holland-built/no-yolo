"""Tests for session-tidy.py (and the merged test it shares with orca-sweep.py).

Every repo is a throwaway under a temp folder: a bare "origin" plus clones. gh and orca are
fake scripts on PATH that answer from JSON files, so nothing real is touched.
Run: python3 -m unittest tools/test_session_tidy.py
"""
import json
import os
import subprocess
import sys
import tempfile
import time
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "session-tidy.py")

FAKE_GH = """#!/bin/sh
# fake gh: `gh pr list ...` prints the merged PRs in $FAKE_GH_JSON, after $FAKE_SLEEP seconds
sleep "${FAKE_SLEEP:-0}"
[ "$1 $2" = "pr list" ] && cat "$FAKE_GH_JSON" && exit 0
exit 1
"""
FAKE_ORCA = """#!/bin/sh
# fake orca: list prints $FAKE_ORCA_JSON, rm records its arguments in $FAKE_ORCA_RM
sleep "${FAKE_SLEEP:-0}"
if [ "$1 $2" = "worktree list" ]; then cat "$FAKE_ORCA_JSON"; exit 0; fi
if [ "$1 $2" = "worktree rm" ]; then echo "$@" >> "$FAKE_ORCA_RM"; exit 0; fi
exit 1
"""
FAKE_GIT = f"""#!{sys.executable}
# fake git: runs the real git, but moves $RACE_BRANCH to $RACE_OID just before git deletes
# that branch, or just after `git status` runs in $RACE_DIR, as another process might
import os, subprocess, sys
a, env = sys.argv[1:], os.environ
branch = env.get("RACE_BRANCH")
def move():
    subprocess.run([env["REAL_GIT"], "-C", env["RACE_REPO"], "update-ref",
                    "refs/heads/" + branch, env["RACE_OID"]], check=True)
if branch and ((a[:1] == ["branch"] and branch in a and ("-d" in a or "-D" in a))
               or (a[:2] == ["update-ref", "-d"] and "refs/heads/" + branch in a)):
    move()
res = subprocess.run([env["REAL_GIT"], *a])
if branch and a[:1] == ["status"] and os.path.realpath(os.getcwd()) == env.get("RACE_DIR"):
    move()
sys.exit(res.returncode)
"""


def git(cwd, *args):
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True,
                          check=True).stdout.strip()


class Tidy(unittest.TestCase):
    def setUp(self):
        self.t = tempfile.mkdtemp()
        bin_dir = os.path.join(self.t, "bin")
        os.makedirs(bin_dir)
        for name, body in (("gh", FAKE_GH), ("orca", FAKE_ORCA)):
            path = os.path.join(bin_dir, name)
            with open(path, "w") as f:
                f.write(body)
            os.chmod(path, 0o755)
        cfg = os.path.join(self.t, "gitconfig")
        with open(cfg, "w") as f:
            f.write("[user]\n name = Test\n email = test@example.test\n"
                    "[init]\n defaultBranch = main\n")
        self.gh_json = os.path.join(self.t, "prs.json")
        self.orca_json = os.path.join(self.t, "orca.json")
        self.orca_rm = os.path.join(self.t, "orca-rm.txt")
        self.home = os.path.join(self.t, "home")
        self.env = {**os.environ, "HOME": self.home, "PATH": bin_dir + os.pathsep + os.environ["PATH"],
                    "GIT_CONFIG_GLOBAL": cfg, "GIT_CONFIG_NOSYSTEM": "1",
                    "FAKE_GH_JSON": self.gh_json, "FAKE_ORCA_JSON": self.orca_json,
                    "FAKE_ORCA_RM": self.orca_rm, "ORCA_BIN": os.path.join(bin_dir, "orca")}
        os.environ.update({k: self.env[k] for k in ("GIT_CONFIG_GLOBAL", "GIT_CONFIG_NOSYSTEM")})
        self.prs([])
        self.orca([])
        self.origin = os.path.join(self.t, "origin.git")
        self.repo = os.path.join(self.t, "repo")
        git(self.t, "init", "-q", "--bare", "-b", "main", self.origin)
        git(self.t, "clone", "-q", self.origin, self.repo)
        self.commit(self.repo, "start")
        git(self.repo, "push", "-q", "-u", "origin", "main")
        git(self.repo, "remote", "set-head", "origin", "main")

    # helpers
    def commit(self, repo, msg):
        with open(os.path.join(repo, msg.replace(" ", "_") + ".txt"), "w") as f:
            f.write(msg + "\n")
        git(repo, "add", "-A")
        git(repo, "commit", "-q", "-m", msg)
        return git(repo, "rev-parse", "HEAD")

    def prs(self, prs):
        """Write merged PRs for fake gh. A PR without mergeCommit gets the current origin/main
        (or main) commit, which is where squash_merge and child put its work."""
        out = []
        for pr in prs:
            pr = {"baseRefName": "main", **pr}
            if "mergeCommit" not in pr:
                oid = pr.pop("merge") if "merge" in pr else git(self.repo, "rev-parse", "origin/main")
                pr["mergeCommit"] = {"oid": oid}
            out.append(pr)
        with open(self.gh_json, "w") as f:
            json.dump(out, f)

    def race(self, branch, oid, worktree=None):
        """Put the fake git on PATH so `branch` moves to `oid` between the check and the delete."""
        bin_dir = os.path.join(self.t, "racebin")
        os.makedirs(bin_dir, exist_ok=True)
        path = os.path.join(bin_dir, "git")
        with open(path, "w") as f:
            f.write(FAKE_GIT)
        os.chmod(path, 0o755)
        real = subprocess.run(["which", "git"], capture_output=True, text=True).stdout.strip()
        self.env.update({"PATH": bin_dir + os.pathsep + self.env["PATH"], "REAL_GIT": real,
                         "RACE_BRANCH": branch, "RACE_OID": oid, "RACE_REPO": self.repo,
                         "RACE_DIR": os.path.realpath(worktree) if worktree else ""})

    def orca(self, worktrees):
        with open(self.orca_json, "w") as f:
            json.dump({"result": {"worktrees": worktrees}}, f)

    def branches(self):
        return set(git(self.repo, "for-each-ref", "--format=%(refname:short)", "refs/heads/").split())

    def tidy(self, *flags, cwd=None):
        start = time.time()
        res = subprocess.run([sys.executable, SCRIPT, *flags], input=json.dumps({"cwd": cwd or self.repo}),
                             capture_output=True, text=True, env=self.env, timeout=30)
        self.assertEqual(res.returncode, 0, res.stderr)
        self.assertEqual(res.stderr, "")
        self.assertLess(time.time() - start, 20)
        with open(os.path.join(self.home, ".claude/state/session-tidy.log")) as f:
            self.log = f.read()
        return res.stdout

    def squash_merge(self, branch, extra_after=False):
        """Make `branch` with one commit, squash it onto origin/main, record a merged PR."""
        git(self.repo, "checkout", "-q", "-b", branch, "main")
        tip = self.commit(self.repo, f"{branch} work")
        git(self.repo, "checkout", "-q", "main")
        git(self.repo, "merge", "-q", "--squash", branch)
        git(self.repo, "commit", "-q", "-m", f"{branch} (squash)")
        git(self.repo, "push", "-q", "origin", "main")
        if extra_after:
            git(self.repo, "checkout", "-q", branch)
            self.commit(self.repo, f"{branch} after merge")
            git(self.repo, "checkout", "-q", "main")
        return tip

    # step 2: old branches
    def make_branch_cases(self):
        git(self.repo, "checkout", "-q", "-b", "merged")
        self.commit(self.repo, "merged work")
        git(self.repo, "checkout", "-q", "main")
        git(self.repo, "merge", "-q", "--no-ff", "-m", "merge", "merged")
        git(self.repo, "push", "-q", "origin", "main")
        prs = [{"number": 2, "headRefName": "squashed", "headRefOid": self.squash_merge("squashed"),
                "merge": None},
               {"number": 3, "headRefName": "squashed-then-more",
                "headRefOid": self.squash_merge("squashed-then-more", extra_after=True)}]
        prs[0]["merge"] = git(self.repo, "rev-parse", "HEAD~1")  # the squash of "squashed"
        # a stacked PR: merged, at the tip, but into another branch, so its work is not in main
        git(self.repo, "checkout", "-q", "-b", "stacked", "main")
        prs.append({"number": 4, "headRefName": "stacked", "headRefOid": self.commit(self.repo, "stacked work"),
                    "baseRefName": "some-feature"})
        git(self.repo, "checkout", "-q", "main")
        self.prs(prs)
        git(self.repo, "branch", "master")  # merged, but protected by name
        git(self.repo, "checkout", "-q", "-b", "unmerged")
        self.commit(self.repo, "unmerged work")
        git(self.repo, "checkout", "-q", "main")
        git(self.repo, "branch", "in-worktree")
        git(self.repo, "worktree", "add", "-q", os.path.join(self.t, "wt"), "in-worktree")

    def test_branches_merged_go_rest_stay(self):
        self.make_branch_cases()
        self.assertEqual(self.tidy(), "")
        self.assertEqual(self.branches(), {"main", "master", "unmerged", "squashed-then-more", "in-worktree", "stacked"})
        self.assertIn("deleted merged (merged into origin/main: ancestor)", self.log)
        self.assertIn("deleted squashed (merged into origin/main: PR #2)", self.log)
        self.assertIn("keep squashed-then-more: not merged", self.log)
        self.assertIn("keep stacked: not merged", self.log)
        self.assertIn("keep in-worktree: checked out in a worktree", self.log)

    def test_slow_gh_and_orca_stay_inside_the_time_budget(self):
        self.make_branch_cases()
        prs = []
        kids = [self.child(f"slow-{i}", 90, prs, squash=True) for i in range(3)]
        self.prs(prs)
        self.orca([{"id": "parent", "isMainWorktree": True, "path": self.repo}] + kids)
        self.env["FAKE_SLEEP"] = "30"
        start = time.time()
        self.tidy()  # asserts exit 0, no stderr, under 20 s
        self.assertLess(time.time() - start, 18)
        self.assertIn("out of time", self.log)
        self.assertIn("done in", self.log)
        self.assertNotIn("merged", self.branches())
        self.assertIn("squashed", self.branches())  # gh never answered, so no PR proof

    def test_current_branch_stays_even_if_merged(self):
        git(self.repo, "checkout", "-q", "-b", "done-feature")
        self.tidy()
        self.assertIn("done-feature", self.branches())

    def test_dry_run_changes_nothing(self):
        self.make_branch_cases()
        before = self.branches()
        self.tidy("--dry-run")
        self.assertEqual(self.branches(), before)
        self.assertIn("would delete merged (merged: ancestor)", self.log)
        self.assertIn("would delete squashed (merged: PR #2)", self.log)

    def test_merged_pr_whose_merge_commit_is_not_in_base_keeps_branch(self):
        # GitHub says merged, but the merge commit is not in origin/main here (not fetched yet,
        # or merged somewhere else), so the work cannot be shown to be in the base.
        tip = self.squash_merge("pr-not-here")
        self.prs([{"number": 7, "headRefName": "pr-not-here", "headRefOid": tip, "merge": tip}])
        self.tidy()
        self.assertIn("pr-not-here", self.branches())
        self.assertIn("keep pr-not-here: not merged", self.log)

    def test_pr_without_merge_commit_keeps_branch(self):
        tip = self.squash_merge("pr-no-oid")
        self.prs([{"number": 8, "headRefName": "pr-no-oid", "headRefOid": tip, "mergeCommit": None}])
        self.tidy()
        self.assertIn("pr-no-oid", self.branches())

    def test_branch_that_moves_after_the_check_survives(self):
        tip = self.squash_merge("moving")
        self.prs([{"number": 9, "headRefName": "moving", "headRefOid": tip}])
        git(self.repo, "checkout", "-q", "moving")
        new = self.commit(self.repo, "moving new work")
        git(self.repo, "checkout", "-q", "main")
        git(self.repo, "update-ref", "refs/heads/moving", tip)
        self.race("moving", new)
        self.tidy()
        self.assertIn("moving", self.branches())
        self.assertEqual(git(self.repo, "rev-parse", "moving"), new)
        self.assertIn("keep moving: it moved since the check", self.log)

    # step 3: catch up with GitHub
    def other_clone_pushes(self, n=1):
        other = os.path.join(self.t, "other")
        if not os.path.isdir(other):
            git(self.t, "clone", "-q", self.origin, other)
        for i in range(n):
            self.commit(other, f"remote change {time.time()} {i}")
        git(other, "push", "-q", "origin", "main")
        return git(other, "rev-parse", "HEAD")

    def test_behind_and_clean_fast_forwards(self):
        remote_head = self.other_clone_pushes(3)
        self.assertEqual(self.tidy(), "")
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), remote_head)
        self.assertIn("fast-forwarded main by 3 commit(s) from origin/main", self.log)

    def test_behind_dry_run_does_not_fetch_or_move(self):
        head = git(self.repo, "rev-parse", "HEAD")
        self.other_clone_pushes(1)
        git(self.repo, "fetch", "-q")
        self.tidy("--dry-run")
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), head)
        self.assertIn("would fast-forward main by 1 commit(s)", self.log)

    def test_behind_and_dirty_is_left_alone(self):
        head = git(self.repo, "rev-parse", "HEAD")
        self.other_clone_pushes(1)
        with open(os.path.join(self.repo, "start.txt"), "a") as f:
            f.write("local edit\n")
        self.assertEqual(self.tidy(), "")
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), head)
        self.assertIn("has changed files; left alone", self.log)

    def test_fast_forward_never_overwrites_an_ignored_local_file(self):
        with open(os.path.join(self.repo, ".git/info/exclude"), "a") as f:
            f.write("local.env\n")
        with open(os.path.join(self.repo, "local.env"), "w") as f:
            f.write("mine\n")
        other = os.path.join(self.t, "other")
        git(self.t, "clone", "-q", self.origin, other)
        with open(os.path.join(other, "local.env"), "w") as f:
            f.write("theirs\n")
        git(other, "add", "local.env")
        git(other, "commit", "-q", "-m", "track local.env")
        git(other, "push", "-q", "origin", "main")
        head = git(self.repo, "rev-parse", "HEAD")
        self.tidy()
        with open(os.path.join(self.repo, "local.env")) as f:
            self.assertEqual(f.read(), "mine\n")
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), head)
        self.assertIn("fast-forward of main failed", self.log)

    def test_diverged_prints_one_line_and_changes_nothing(self):
        self.other_clone_pushes(3)
        local = [self.commit(self.repo, "local a"), self.commit(self.repo, "local b")][-1]
        out = self.tidy()
        self.assertEqual(out, "Git: main is 3 behind and 2 ahead of origin/main; sync before starting work.\n")
        self.assertEqual(git(self.repo, "rev-parse", "HEAD"), local)

    def test_not_a_repo_and_bad_input_never_fail(self):
        plain = os.path.join(self.t, "plain")
        os.makedirs(plain)
        self.assertEqual(self.tidy(cwd=plain), "")
        res = subprocess.run([sys.executable, SCRIPT], input="not json", capture_output=True,
                             text=True, env=self.env, timeout=30)
        self.assertEqual((res.returncode, res.stdout, res.stderr), (0, "", ""))

    # step 1: Orca copies
    def child(self, name, idle_min, prs, squash=False, unmerged=False, dirty=False, extra=False,
              merge_elsewhere=False):
        path = os.path.join(self.t, "copies", name)
        git(self.repo, "worktree", "add", "-q", "-b", name, path, "main")
        tip = self.commit(path, f"{name} work")
        if squash:
            git(self.repo, "merge", "-q", "--squash", name)
            git(self.repo, "commit", "-q", "-m", f"{name} (squash)")
            prs.append({"number": len(prs) + 10, "headRefName": name, "headRefOid": tip,
                        "merge": tip if merge_elsewhere else git(self.repo, "rev-parse", "main")})
        elif not unmerged:
            git(self.repo, "merge", "-q", "--no-ff", "-m", "merge", name)
        if extra:
            self.commit(path, f"{name} after merge")
        if dirty:
            with open(os.path.join(path, "scratch.txt"), "w") as f:
                f.write("unsaved\n")
        return {"id": f"id-{name}", "parentWorktreeId": "parent", "displayName": name,
                "path": path, "branch": f"refs/heads/{name}", "baseRef": "main",
                "lastActivityAt": (time.time() - idle_min * 60) * 1000}

    def test_orca_sweep_removes_only_finished_copies(self):
        prs = []
        kids = [self.child("c-merged", 90, prs), self.child("c-squashed", 90, prs, squash=True),
                self.child("c-squash-more", 90, prs, squash=True, extra=True),
                self.child("c-unmerged", 90, prs, unmerged=True),
                self.child("c-dirty", 90, prs, dirty=True), self.child("c-recent", 5, prs)]
        self.prs(prs)
        self.orca([{"id": "parent", "isMainWorktree": True, "path": self.repo,
                    "branch": "refs/heads/main"}] + kids)
        self.tidy("--dry-run")
        self.assertFalse(os.path.exists(self.orca_rm))
        self.assertIn("orca: would remove c-squashed", self.log)
        self.tidy()
        with open(self.orca_rm) as f:
            removed = f.read()
        self.assertIn("id:id-c-merged", removed)
        self.assertIn("id:id-c-squashed", removed)
        for kept in ("c-squash-more", "c-unmerged", "c-dirty", "c-recent"):
            self.assertNotIn(f"id-{kept} ", removed + " ")
        self.assertIn("orca: keep c-dirty: 1 unsaved file(s)", self.log)

    def test_orca_sweep_keeps_copy_whose_pr_merge_commit_is_not_in_base(self):
        prs = []
        kids = [self.child("c-elsewhere", 90, prs, squash=True, merge_elsewhere=True)]
        self.prs(prs)
        self.orca([{"id": "parent", "isMainWorktree": True, "path": self.repo}] + kids)
        self.tidy()
        self.assertFalse(os.path.exists(self.orca_rm))
        self.assertIn("orca: keep c-elsewhere: c-elsewhere is not merged", self.log)

    def test_orca_sweep_removes_copy_whose_tip_is_inside_a_merged_pr(self):
        # The main chat ships c-built from c-built-pr, one commit on top, so the PR's head is
        # not c-built's tip but c-built's tip is one of the PR's commits.
        prs = []
        kids = [self.child("c-built", 90, prs, unmerged=True),
                self.child("c-other", 90, prs, unmerged=True)]
        tip = git(self.repo, "rev-parse", "c-built")
        git(self.repo, "branch", "c-built-pr", "c-built")
        git(self.repo, "checkout", "-q", "c-built-pr")
        head = self.commit(self.repo, "c-built-pr fixups")
        git(self.repo, "checkout", "-q", "main")
        git(self.repo, "merge", "-q", "--squash", "c-built-pr")
        git(self.repo, "commit", "-q", "-m", "c-built-pr (squash)")
        self.prs([{"number": 503, "headRefName": "c-built-pr", "headRefOid": head,
                   "merge": git(self.repo, "rev-parse", "main"),
                   "commits": [{"oid": tip}, {"oid": head}]}])
        self.orca([{"id": "parent", "isMainWorktree": True, "path": self.repo}] + kids)
        self.tidy("--dry-run")
        self.assertIn("orca: would remove c-built (c-built, merged: tip in merged PR #503)", self.log)
        self.tidy()
        with open(self.orca_rm) as f:
            removed = f.read()
        self.assertIn("id:id-c-built ", removed + " ")
        self.assertNotIn("id-c-other", removed)
        self.assertIn("orca: keep c-other: c-other is not merged", self.log)

    def test_orca_sweep_skips_copy_that_moved_after_the_check(self):
        prs = []
        kids = [self.child("c-moving", 90, prs)]
        path = kids[0]["path"]
        tip = git(path, "rev-parse", "HEAD")
        new = self.commit(path, "c-moving new work")
        git(path, "reset", "-q", "--hard", tip)
        self.prs(prs)
        self.orca([{"id": "parent", "isMainWorktree": True, "path": self.repo}] + kids)
        self.race("c-moving", new, worktree=path)
        self.tidy()
        self.assertFalse(os.path.exists(self.orca_rm))
        self.assertIn("orca: keep c-moving: c-moving moved since it was checked", self.log)


if __name__ == "__main__":
    unittest.main()
