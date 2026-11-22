#!/usr/bin/env python3
"""Weekly: move Open Code Review to the newest safe version.

Launchd runs this once a week on macOS. A release is taken only when it is at least a week
old and works with the network blocked. Install scripts stay off, because the package's script
only downloads a program that its platform package already carries. Anything else keeps the
current version, and the log says why.
"""
import datetime
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

PACKAGE = "@alibaba-group/open-code-review"
LOG = Path.home() / ".claude/state/ocr-update.log"
MIN_AGE = datetime.timedelta(days=7)
NO_NETWORK = ["sandbox-exec", "-p", "(version 1)(allow default)(deny network*)"]
INSTALL = ["npm", "install", "--ignore-scripts", "--silent", "--no-audit", "--no-fund", "--save-exact"]


def log(message):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as file:
        file.write(f"{datetime.datetime.now().isoformat(timespec='seconds')} {message}\n")


def run(*args, cwd=None):
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=240, check=True).stdout


def newest_safe():
    times = json.loads(run("npm", "view", PACKAGE, "time", "--json"))
    cutoff = datetime.datetime.now(datetime.timezone.utc) - MIN_AGE
    ready = [v for v, t in times.items() if re.fullmatch(r"\d+\.\d+\.\d+", v)
             and datetime.datetime.fromisoformat(t.replace("Z", "+00:00")) <= cutoff]
    return max(ready, key=lambda v: tuple(int(part) for part in v.split(".")))


def works(version):
    with tempfile.TemporaryDirectory() as folder:
        run(*INSTALL, "--prefix", folder, f"{PACKAGE}@{version}", cwd=folder)
        tool = str(Path(folder) / "node_modules/.bin/ocr")
        repo = Path(folder) / "repo"
        repo.mkdir()
        run("git", "init", "-q", "-b", "main", cwd=repo)
        run("git", "-c", "user.name=t", "-c", "user.email=t@example.com", "commit", "-q", "--allow-empty", "-m", "a", cwd=repo)
        (repo / "a.js").write_text("export const a = 1;\n", encoding="utf-8")
        run("git", "add", ".", cwd=repo)
        run("git", "-c", "user.name=t", "-c", "user.email=t@example.com", "commit", "-q", "-m", "b", cwd=repo)
        preview = json.loads(run(*NO_NETWORK, tool, "delegate", "preview", "--format", "json", "--from", "HEAD~1", "--to", "HEAD", cwd=repo))
        return bool(preview["reviewable_files"])


def main():
    if sys.platform != "darwin" or not shutil.which("sandbox-exec"):
        print("macOS only: this updater needs the macOS network block, so nothing was changed.")
        return
    if not shutil.which("ocr"):
        log("skipped: Open Code Review is not installed")
        return
    current = run("ocr", "--version").split()[1].lstrip("v")
    version = newest_safe()
    if tuple(map(int, version.split("."))) <= tuple(map(int, current.split("."))):
        log(f"already on {current}")
        return
    if not works(version):
        log(f"kept {current}, {version} skipped: its file check found nothing")
        return
    run(*INSTALL, "-g", f"{PACKAGE}@{version}")
    log(f"updated to {version}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:  # A failed week changes nothing and tries again next week.
        log(f"failed: {error!r}"[:300])
