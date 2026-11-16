#!/usr/bin/env python3
"""Remove finished Orca builder copies (child worktrees) that are safe to delete.

Orca closes a finished builder's tab on its own but never deletes its worktree, so copies
pile up in the sidebar whenever the managing chat closes before its Done step. launchd runs
this every 15 minutes (~/Library/LaunchAgents/com.user.orca-sweep.plist).

A child worktree is removed only when all of these hold, so unmerged or unsaved work is
never lost and a builder that is still working is never pulled out from under it:
  - its branch has no commits missing from the branch it was cut from (baseRef)
  - `git status --porcelain` in it is empty
  - Orca saw no activity in it for MIN_IDLE_MIN minutes
Everything else is left and logged with the reason.

Usage: orca-sweep.py [--dry-run]
       orca-sweep.py --install   (copy to ~/.claude/tools and run every 15 minutes, macOS)
"""
import json
import subprocess
import sys
import time
from pathlib import Path

ORCA = "/Applications/Orca.app/Contents/Resources/bin/orca"
LOG = Path.home() / ".claude/state/orca-sweep.log"
MIN_IDLE_MIN = 60
DRY = "--dry-run" in sys.argv


def log(msg):
    line = f"{time.strftime('%Y-%m-%dT%H:%M:%S')} {msg}"
    print(line)
    with LOG.open("a") as f:
        f.write(line + "\n")


def run(args, cwd=None):
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=120)


def main():
    res = run([ORCA, "worktree", "list", "--json"])
    if res.returncode != 0:
        log(f"skip: orca not reachable ({res.stderr.strip()[:120]})")
        return
    data = json.loads(res.stdout)
    items = data.get("result", data)
    if isinstance(items, dict):
        items = items.get("worktrees", [])
    by_id = {w["id"]: w for w in items}

    for w in items:
        parent_id = w.get("parentWorktreeId")
        if not parent_id or w.get("isMainWorktree"):
            continue
        name = w.get("displayName")
        path = w.get("path")
        branch = (w.get("branch") or "").removeprefix("refs/heads/")
        base = w.get("baseRef")
        parent = by_id.get(parent_id)
        if not (path and branch and base and parent and Path(path).is_dir()):
            log(f"keep {name}: missing path, branch, base or parent")
            continue

        idle_min = (time.time() * 1000 - (w.get("lastActivityAt") or 0)) / 60000
        if idle_min < MIN_IDLE_MIN:
            continue  # still recent; checked again next run

        ahead = run(["git", "rev-list", "--count", f"{base}..{branch}"], cwd=parent["path"])
        if ahead.returncode != 0:
            log(f"keep {name}: could not compare {branch} with {base}")
            continue
        if ahead.stdout.strip() != "0":
            log(f"keep {name}: {ahead.stdout.strip()} commit(s) not merged into {base}")
            continue

        dirty = run(["git", "status", "--porcelain"], cwd=path)
        if dirty.returncode != 0 or dirty.stdout.strip():
            n = len(dirty.stdout.strip().splitlines())
            log(f"keep {name}: {n} unsaved file(s)")
            continue

        if DRY:
            log(f"would remove {name} ({branch})")
            continue
        rm = run([ORCA, "worktree", "rm", "--worktree", f"id:{w['id']}", "--delete-branch"])
        if rm.returncode == 0:
            log(f"removed {name} ({branch}, merged into {base})")
        else:
            log(f"keep {name}: rm failed ({rm.stderr.strip()[:160]})")


PLIST = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.user.orca-sweep</string>
  <key>ProgramArguments</key><array><string>/usr/bin/python3</string><string>{script}</string></array>
  <key>StartInterval</key><integer>900</integer>
  <key>StandardErrorPath</key><string>{err}</string>
</dict></plist>
"""


def install():
    import os
    import shutil
    dest = Path.home() / ".claude/tools/orca-sweep.py"
    dest.parent.mkdir(parents=True, exist_ok=True)
    LOG.parent.mkdir(parents=True, exist_ok=True)
    if Path(__file__).resolve() != dest.resolve():
        shutil.copy2(__file__, dest)
    plist = Path.home() / "Library/LaunchAgents/com.user.orca-sweep.plist"
    plist.parent.mkdir(parents=True, exist_ok=True)
    plist.write_text(PLIST.format(script=dest, err=LOG.with_suffix(".err")))
    domain = f"gui/{os.getuid()}"
    run(["launchctl", "bootout", f"{domain}/com.user.orca-sweep"])
    res = run(["launchctl", "bootstrap", domain, str(plist)])
    print("installed: runs every 15 minutes" if res.returncode == 0 else f"failed: {res.stderr.strip()}")


if __name__ == "__main__":
    if "--install" in sys.argv:
        install()
    else:
        LOG.parent.mkdir(parents=True, exist_ok=True)
        main()
