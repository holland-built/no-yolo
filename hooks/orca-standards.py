#!/usr/bin/env python3
"""Keep every Orca project set up the same way, including projects added later.

Runs on SessionStart. For each git project in Orca:
- New workspaces start from the branch the Main folder is on, so they hold what the user sees in
  Main (Wayfinder's redesign once started from the live branch and missed 387 changes).
- The main workspace is called "Main" when it still carries the folder's own name, so the sidebar
  never shows the same name twice. A name the user chose is left alone.
Private files reach new workspaces through workspace-files.py. Never blocks a chat.
"""
import json
import os
import subprocess


def run(*args):
    return subprocess.run(args, capture_output=True, text=True, timeout=15).stdout


def orca(*args):
    return json.loads(run("orca", *args, "--json"))["result"]


def main():
    repos = orca("repo", "list")["repos"]
    mains = {w["path"]: w for w in orca("worktree", "list")["worktrees"] if w["isMainWorktree"]}
    for repo in repos:
        path = repo["path"]
        if repo.get("kind") != "git" or not os.path.isdir(path):
            continue
        branch = run("git", "-C", path, "branch", "--show-current").strip()
        if branch and repo.get("worktreeBaseRef") != branch:
            run("orca", "repo", "set-base-ref", "--repo", f"id:{repo['id']}", "--ref", branch, "--json")
        main_row = mains.get(path)
        if main_row and main_row["displayName"] in (os.path.basename(path), repo["displayName"]):
            run("orca", "worktree", "set", "--worktree", f"id:{main_row['id']}", "--display-name", "Main", "--json")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
