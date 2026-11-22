#!/usr/bin/env python3
"""Weekly: move the skills to the newest safe modern-web-guidance version.

Launchd runs this once a week on macOS. A release is taken only when it is at least
a week old, has no install scripts, still honors DISABLE_TELEMETRY, and answers a real search.
Anything else leaves the skills on the version they have, and the log says why.
"""
import datetime
import json
import os
import re
import subprocess
import sys
import tempfile
import tarfile
from pathlib import Path

PACKAGE = "modern-web-guidance"
ROOT = Path.home() / ".claude"
SKILLS = ["skills/build/SKILL.md", "skills/improve/SKILL.md", "skills/site-design/SKILL.md",
          "skills/fix/SKILL.md", "CLAUDE.md"]
LOG = ROOT / "state/web-guidance-update.log"
MIN_AGE_DAYS = 7
PIN = re.compile(re.escape(PACKAGE) + r"@\d+\.\d+\.\d+")
INSTALL_SCRIPTS = {"preinstall", "install", "postinstall"}


def log(message):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as file:
        file.write(f"{datetime.datetime.now().isoformat(timespec='seconds')} {message}\n")


def run(*args, cwd=None, env=None):
    return subprocess.run(args, cwd=cwd, env=env, capture_output=True, text=True, timeout=180, check=True).stdout


def why_unsafe(version, info):
    published = datetime.datetime.fromisoformat(info["time"][version].replace("Z", "+00:00"))
    age = datetime.datetime.now(datetime.timezone.utc) - published
    if age.days < MIN_AGE_DAYS:
        return f"only {age.days} days old"
    with tempfile.TemporaryDirectory() as folder:
        name = run("npm", "pack", f"{PACKAGE}@{version}", "--ignore-scripts", "--silent", cwd=folder).strip()
        with tarfile.open(Path(folder) / name) as archive:
            manifest = json.load(archive.extractfile("package/package.json"))
            tool = archive.extractfile("package/skills/modern-web-guidance/modern-web.mjs").read()
        if INSTALL_SCRIPTS & set(manifest.get("scripts") or {}):
            return "it has install scripts"
        if b"DISABLE_TELEMETRY" not in tool:
            return "it no longer has the tracking off switch"
        env = {**os.environ, "DISABLE_TELEMETRY": "1"}
        found = run("npx", "-y", f"{PACKAGE}@{version}", "search", "responsive data table", cwd=folder, env=env)
        if not json.loads(found):
            return "its search returned nothing"
    return None


def is_own_git_repo():
    """True only when ~/.claude is itself a repo's top folder, not a folder inside another repo."""
    done = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=ROOT, capture_output=True,
                          text=True, timeout=30)
    return done.returncode == 0 and Path(done.stdout.strip()).resolve() == ROOT.resolve()


def main():
    if sys.platform != "darwin":
        print("macOS only: weekly updates run through launchd, so nothing was changed.")
        return
    info = json.loads(run("npm", "view", PACKAGE, "dist-tags", "time", "--json"))
    latest = info["dist-tags"]["latest"]
    present = [skill for skill in SKILLS if (ROOT / skill).exists()]
    paths = [ROOT / skill for skill in present]
    pins = {match for path in paths for match in PIN.findall(path.read_text(encoding="utf-8"))}
    if pins == {f"{PACKAGE}@{latest}"}:
        log(f"already on {latest}")
        return
    reason = why_unsafe(latest, info)
    if reason:
        log(f"kept current version, {latest} skipped: {reason}")
        return
    tracked = is_own_git_repo()
    if tracked and run("git", "status", "--porcelain", "--", *present, cwd=ROOT).strip():
        log(f"kept current version, {latest} waits: the skill files have unsaved edits")
        return
    for path in paths:
        text = path.read_text(encoding="utf-8")
        path.write_text(PIN.sub(f"{PACKAGE}@{latest}", text), encoding="utf-8")
    if tracked:
        message = f"build, improve, site-design: update {PACKAGE} to {latest}"
        run("git", "commit", "-q", "-m", message, "--", *present, cwd=ROOT)
    log(f"updated to {latest}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:  # A failed week changes nothing and tries again next week.
        log(f"failed: {error!r}"[:300])
