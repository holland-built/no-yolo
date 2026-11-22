#!/usr/bin/env python3
"""Prepare a risky-change review with Open Code Review. Usage: ocr-review.py <base-branch>

Prints a folder holding files.txt (every file the reviewer must cover) and rules.json (the bug
rules for each). The tool runs with the network blocked, so no code can leave this computer, and
Claude does the review on the subscription. Machine-built files are left out because they waste
tokens. Add your own with a `built: <glob>` line in ~/.claude/risky-extra.txt.

The network block needs macOS. Anywhere else the tool is never run, and the review is done by hand.
"""
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

NO_NETWORK = ["sandbox-exec", "-p", "(version 1)(allow default)(deny network*)"]
BUILT = "**/dist/**,**/.next/**,**/build/**,**/*.min.js,**/*.map,**/package-lock.json"


EXTRA_FILE = Path.home() / ".claude/risky-extra.txt"


def built_patterns():
    try:
        lines = EXTRA_FILE.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError):
        return BUILT
    extra = [l.split(":", 1)[1].strip() for l in lines if l.strip().startswith("built:")]
    return ",".join([BUILT, *[e for e in extra if e]])


def ocr(*args):
    return subprocess.run([*NO_NETWORK, "ocr", "delegate", *args], capture_output=True, text=True,
                          timeout=120, check=True).stdout


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    if sys.platform != "darwin" or not shutil.which("sandbox-exec"):
        print("macOS only: the network block is unavailable here, so the review tool was not run. "
              "Review every changed file by hand.")
        return
    if not shutil.which("ocr"):
        print("Open Code Review is not installed, so the tool was not run. "
              "Review every changed file by hand.")
        return
    base = sys.argv[1]
    preview = json.loads(ocr("preview", "--format", "json", "--from", base, "--to", "HEAD",
                             "--exclude", built_patterns()))
    files = [f["path"] if isinstance(f, dict) else f for f in preview["reviewable_files"]]
    if not files:
        sys.exit("No reviewable files in this change.")
    rules = ocr("rule", "--format", "json", "--from", base, "--to", "HEAD", *files)
    folder = Path(tempfile.mkdtemp(prefix="risky-review-"))
    (folder / "files.txt").write_text("\n".join(files) + "\n", encoding="utf-8")
    (folder / "rules.json").write_text(rules, encoding="utf-8")
    print(f"{folder} ({len(files)} files)")


if __name__ == "__main__":
    main()
