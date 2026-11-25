#!/usr/bin/env python3
"""Weekly: move the Codex command-line tool to the newest safe version.

Launchd runs this once a week on macOS. Codex ships about once a week, so an install nobody
updates falls behind fast: one was 15 versions behind by November 2026. A release is taken only
when it is at least MIN_AGE old, so a bad release has time to be pulled, and only when its
`codex --version` works with the network blocked. Install scripts stay off; the package has
none and carries its program in a platform package. Anything else keeps the current version,
and the log says why.

Only the npm copy is updated. The copy inside the ChatGPT app updates with the app.
"""
import datetime
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

PACKAGE = "@openai/codex"
LOG = Path.home() / ".claude/state/codex-update.log"
MIN_AGE = datetime.timedelta(days=3)
NO_NETWORK = ["sandbox-exec", "-p", "(version 1)(allow default)(deny network*)"]
INSTALL = ["npm", "install", "--ignore-scripts", "--silent", "--no-audit", "--no-fund", "--save-exact"]


def log(message):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as file:
        file.write(f"{datetime.datetime.now().isoformat(timespec='seconds')} {message}\n")


def run(*args, cwd=None):
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=240, check=True,
                          stdin=subprocess.DEVNULL).stdout


def parse(version):
    return tuple(int(part) for part in version.split("."))


def newest_safe():
    times = json.loads(run("npm", "view", PACKAGE, "time", "--json"))
    cutoff = datetime.datetime.now(datetime.timezone.utc) - MIN_AGE
    ready = [v for v, t in times.items() if re.fullmatch(r"\d+\.\d+\.\d+", v)
             and datetime.datetime.fromisoformat(t.replace("Z", "+00:00")) <= cutoff]
    return max(ready, key=parse)


def works(version):
    with tempfile.TemporaryDirectory() as folder:
        run(*INSTALL, "--prefix", folder, f"{PACKAGE}@{version}", cwd=folder)
        tool = str(Path(folder) / "node_modules/.bin/codex")
        return version in run(*NO_NETWORK, tool, "--version", cwd=folder)


def npm_codex():
    """The codex program npm installed globally, or None."""
    path = Path(run("npm", "prefix", "-g").strip()) / "bin/codex"
    return path if path.exists() else None


def installed_version(tool):
    return run(str(tool), "--version").split()[-1]


def is_newer(candidate, current):
    """A stable release beats the same numbers with a suffix, such as 0.172.0-alpha.1."""
    base = re.match(r"\d+\.\d+\.\d+", current).group()
    return parse(candidate) > parse(base) or (candidate == base and current != base)


def main():
    if sys.platform != "darwin" or not shutil.which("sandbox-exec"):
        print("macOS only: this updater needs the macOS network block, so nothing was changed.")
        return
    tool = npm_codex()
    if not tool:
        log("skipped: Codex is not installed with npm")
        return
    on_path = shutil.which("codex")
    if on_path and Path(on_path).resolve() != tool.resolve():
        log(f"note: `codex` on PATH is {on_path}, not the npm copy this updates ({tool})")
    current = installed_version(tool)
    version = newest_safe()
    if not is_newer(version, current):
        log(f"already on {current}")
        return
    if not works(version):
        log(f"kept {current}, {version} skipped: its --version check failed")
        return
    try:
        run(*INSTALL, "-g", f"{PACKAGE}@{version}")
        if version not in installed_version(tool):
            raise RuntimeError("the new copy did not report the new version")
    except Exception as error:
        # Put the old version back, so a failed update never leaves Codex broken.
        run(*INSTALL, "-g", f"{PACKAGE}@{current}")
        log(f"kept {current}: installing {version} failed ({error!r})"[:300])
        return
    log(f"updated {current} to {version}")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:  # A failed week changes nothing and tries again next week.
        log(f"failed: {error!r}"[:300])
