#!/usr/bin/env python3
"""Give a new Orca workspace the private files its project's Main folder has.

A workspace is a git copy, so files git ignores (keys, .env files, local settings) are left out,
and a chat there cannot reach the services Main can. On SessionStart inside a workspace, copy
each such file from Main when the workspace lacks it. Never overwrites, never blocks a chat.
"""
import re
import shutil
import subprocess
from pathlib import Path

PRIVATE = re.compile(r"(^\.env(\..+)?$|_env$|^config\.env$|secret|credential|\.local\.json$|\.tfvars$)",
                     re.IGNORECASE)


def git(*args, cwd):
    return subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True,
                          timeout=10, check=True).stdout.strip()


def main():
    here = Path(git("rev-parse", "--show-toplevel", cwd=Path.cwd()))
    main_dir = Path(git("rev-parse", "--path-format=absolute", "--git-common-dir", cwd=here)).parent
    if here == main_dir:
        return
    ignored = git("ls-files", "--others", "--ignored", "--exclude-standard", "--directory", cwd=main_dir)
    copied = []
    for name in ignored.splitlines():
        source = main_dir / name
        if name.endswith("/") or name.endswith(".bak") or not PRIVATE.search(source.name):
            continue
        target = here / name
        # Copy only what this workspace's git also ignores; otherwise a commit here could take the secret.
        still_private = subprocess.run(["git", "check-ignore", "-q", "--no-index", name], cwd=here,
                                       timeout=10).returncode == 0
        if source.is_file() and not target.exists() and still_private:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            copied.append(name)
    if copied:
        print("Copied from the Main folder: " + ", ".join(copied))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
