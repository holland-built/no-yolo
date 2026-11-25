#!/usr/bin/env python3
"""Keep every Orca project set up the same way, including projects added later.

Runs on SessionStart. For each git or folder project in Orca:
- New workspaces start from the branch the Main folder is on, so they hold what the user sees in
  Main (a redesign once started from the live branch and missed 387 changes).
- Every row says which project it belongs to, because Orca's phone app lists rows without the
  project heading, and 14 rows called "Main" could not be told apart (user's pick, 2026-11-25):
  the main row takes the project's short name ("Wayfinder", "HA · Automations"), and each other
  row the user made gets the short name in front ("HA · Dashboards"). A main-row name the user
  chose is left alone; helpers under a parent row and test copies in temporary folders keep theirs.
Private files reach new workspaces through workspace-files.py. Never blocks a chat.
"""
import json
import os
import subprocess

# Short names the user picked; any other project uses its own name.
SHORT = {"Home Assistant": "HA", "Infoblox MCP": "MCP", "Shared PPTX": "Decks", "free": "Free",
         "Axur SE Report": "Axur", "Holland Hub": "Hub", ".claude": "Claude setup"}
# What the main row is for, when the project also has rows for other areas.
MAIN_JOB = {"Home Assistant": "Automations"}
SEP = " · "
TEMP = ("/private/tmp/", "/tmp/", "/private/var/folders/")


def run(*args):
    return subprocess.run(args, capture_output=True, text=True, timeout=15).stdout


def orca(*args):
    return json.loads(run("orca", *args, "--json"))["result"]


def rename(row, name):
    if row["displayName"] != name:
        run("orca", "worktree", "set", "--worktree", f"id:{row['id']}", "--display-name", name, "--json")


def main():
    repos = orca("repo", "list")["repos"]
    rows = orca("worktree", "list")["worktrees"]
    for repo in repos:
        path, name = repo["path"], repo["displayName"]
        if not os.path.isdir(path):
            continue
        if repo.get("kind") == "git":
            branch = run("git", "-C", path, "branch", "--show-current").strip()
            if branch and repo.get("worktreeBaseRef") != branch:
                run("orca", "repo", "set-base-ref", "--repo", f"id:{repo['id']}", "--ref", branch, "--json")
        short = SHORT.get(name, name)
        for row in (r for r in rows if r.get("repoId") == repo["id"]):
            current = row["displayName"]
            if row["isMainWorktree"]:
                if current in (os.path.basename(path), name, "Main", "master"):
                    rename(row, short + SEP + MAIN_JOB[name] if name in MAIN_JOB else short)
            elif not row.get("parentWorktreeId") and not row["path"].startswith(TEMP) \
                    and not current.startswith(short + SEP):
                rename(row, short + SEP + current.split("/")[-1])


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
