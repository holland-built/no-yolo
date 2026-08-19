#!/usr/bin/env python3
"""borrowed_check.py — drift report for every borrowed third-party source.

Replaces the three-line loop that used to live inline in skills/checkup/SKILL.md,
which had four defects: it looked only at plugins/marketplaces/, it printed NOTHING
for a directory with no .git (so a silent skip read as healthy), it printed a blank
where a commit count belonged, and it had no mechanism at all for a vendored
directory that never was a git checkout.

The contract here is the opposite of that loop: EVERY registered source produces
exactly one row, EVERY row has a value in every cell, and a check that could not run
says so in words. A blank cell is a bug in this script, not a clean result.

Reads docs/BORROWED.md as the registration manifest. Writes nothing.
Exit code is 0 unless the manifest itself is unreadable or malformed — a drifted
source is a finding to report, not a crash.
"""

import hashlib
import json
import os
import re
import subprocess
import sys

# scripts/ -> checkup/ -> skills/ -> repo root. Four levels, not three: this script lives
# one directory deeper than the skill file that calls it.
# CHECKUP_ROOT overrides it so the test suite can point the whole check at a throwaway
# fixture tree. Without that, the failure paths below could only ever be argued about.
ROOT = os.environ.get("CHECKUP_ROOT") or os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
MANIFEST = os.path.join(ROOT, "docs", "BORROWED.md")

COLUMNS = ["Name", "Kind", "Path", "Upstream", "Pinned", "Content hash", "How checked", "Licence"]
METHODS = {"git", "hash", "installer", "url-only"}

# Anything under a declared root that is not in the manifest is reported UNREGISTERED.
# Roots are listed rather than inferred: there is no reliable way to look at a directory
# and know somebody else wrote it.
ROOTS = ["plugins/marketplaces", "skills/design/vendor"]

SKILL_LOCK = os.path.expanduser("~/.agents/.skill-lock.json")


def cell(text):
    """Markdown table cells cannot contain a pipe or a newline. Command output can."""
    return str(text).replace("|", "\\|").replace("\n", " ").replace("\r", " ").strip() or "unknown"


def run(args, cwd=None):
    try:
        p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=60)
        return p.returncode, p.stdout.strip(), p.stderr.strip()
    except FileNotFoundError:
        return 127, "", f"{args[0]} not installed"
    except subprocess.TimeoutExpired:
        return 124, "", "timed out after 60s"


def dir_hash(path):
    """Deterministic hash of a directory's contents.

    Sorted by relative POSIX path, and each file contributes its path AND its bytes, so
    a rename is drift. SOURCE.md is excluded because it is where the hash gets recorded
    and would otherwise change its own answer. Symlinks hash their target string rather
    than being followed, so a repointed link is drift and a broken one is not a crash.
    """
    h = hashlib.sha256()
    entries = []
    for dirpath, dirnames, filenames in os.walk(path):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        for name in filenames:
            if name == "SOURCE.md":
                continue
            full = os.path.join(dirpath, name)
            entries.append((os.path.relpath(full, path).replace(os.sep, "/"), full))
    for rel, full in sorted(entries):
        h.update(rel.encode())
        h.update(b"\0")
        if os.path.islink(full):
            h.update(b"symlink\0" + os.readlink(full).encode())
        else:
            with open(full, "rb") as fh:
                for chunk in iter(lambda: fh.read(65536), b""):
                    h.update(chunk)
        h.update(b"\0")
    return h.hexdigest()


GITHUB = re.compile(r"github\.com[:/]+([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+?)(?:\.git)?/?$")


def github_head(url, pinned):
    """Compare a pinned revision against the upstream default branch, via gh.

    Every failure mode gets its own sentence. Collapsing them into one "no network"
    message would rebuild the exact false-health problem this script exists to fix:
    an unauthenticated gh and a genuinely up-to-date repo would read the same.
    """
    m = GITHUB.search(url or "")
    if not m:
        return "documentation-only, unchecked — not a GitHub URL"
    owner, repo = m.group(1), m.group(2)
    code, out, err = run(["gh", "api", f"repos/{owner}/{repo}/commits/HEAD", "--jq", ".sha"])
    if code == 127:
        return "CANNOT CHECK — gh not installed"
    blob = (out + " " + err).lower()
    if code != 0:
        if "authentication" in blob or "gh auth login" in blob:
            return "CANNOT CHECK — gh not authenticated"
        if "rate limit" in blob:
            return "CANNOT CHECK — GitHub rate limit"
        if "not found" in blob or "404" in blob:
            return f"CANNOT CHECK — repo {owner}/{repo} not found or private"
        if "could not resolve" in blob or "network" in blob or "dial tcp" in blob:
            return "CANNOT CHECK — network error"
        return f"CANNOT CHECK — gh exited {code}: {err[:80] or out[:80]}"
    head = out.strip()
    if not head:
        return "CANNOT CHECK — gh returned no sha"
    if not pinned or pinned == "unknown":
        return f"CANNOT CHECK — no pinned revision recorded (upstream is at {head[:12]})"
    if head.startswith(pinned) or pinned.startswith(head[:12]):
        return "up to date"
    return f"UPSTREAM MOVED — pinned {pinned[:12]}, upstream {head[:12]}"


def check_git(row, path):
    if not os.path.isdir(os.path.join(path, ".git")):
        return "MISSING — manifest says git, no .git on disk", "CANNOT CHECK — not a git checkout"
    code, out, _ = run(["git", "status", "--porcelain"], cwd=path)
    local = "clean" if code == 0 and not out else (
        f"EDITED LOCALLY — {len(out.splitlines())} files" if code == 0 else "unknown — git status failed")

    code, _, _ = run(["git", "rev-parse", "--abbrev-ref", "@{u}"], cwd=path)
    if code != 0:
        rc, remotes, _ = run(["git", "remote"], cwd=path)
        if rc == 0 and remotes:
            return local, "CANNOT CHECK — no tracking branch configured"
        return local, "CANNOT CHECK — no upstream recorded"

    run(["git", "fetch", "-q"], cwd=path)
    code, out, err = run(["git", "rev-list", "--left-right", "--count", "HEAD...@{u}"], cwd=path)
    if code != 0 or not out:
        return local, f"unknown — could not count revisions ({err[:60] or 'no output'})"
    parts = out.split()
    if len(parts) != 2:
        return local, "unknown — unreadable revision count"
    ahead, behind = parts[0], parts[1]
    if ahead == "0" and behind == "0":
        return local, "up to date"
    bits = []
    if behind != "0":
        bits.append(f"{behind} behind")
    if ahead != "0":
        bits.append(f"{ahead} ahead")
    return local, ", ".join(bits)


def check_hash(row, path):
    recorded = row.get("Content hash", "").strip().strip("`")
    if recorded == "machine-managed":
        # Some directories are rewritten by a tool rather than by a person — Claude Code
        # refreshes plugins/marketplaces/ on its own schedule. Hashing one of those compares
        # a person's baseline against a machine's output and is wrong within minutes, so the
        # row would fail forever and teach the reader to ignore it. Recording that it cannot
        # be a baseline is the honest answer; the upstream check below still means something.
        local = "not checked — directory is machine-managed, contents change without a person"
    else:
        actual = dir_hash(path)
        if not recorded or recorded == "unknown":
            local = f"CANNOT CHECK — no content hash recorded (actual is {actual[:12]})"
        elif actual.startswith(recorded) or recorded.startswith(actual[:12]):
            local = f"matches pin ({actual[:12]})"
        else:
            local = f"EDITED LOCALLY — recorded {recorded[:12]}, actual {actual[:12]}"

    upstream = row.get("Upstream", "").strip()
    if not upstream or upstream == "unknown":
        return local, "CANNOT CHECK — no upstream recorded"

    pinned = row.get("Pinned", "").strip().strip("`")
    if pinned.startswith("."):
        # The pin lives in a file inside the directory rather than in this table — the only
        # way to track a self-updating checkout without re-editing the manifest every run.
        pinfile = os.path.join(path, pinned)
        try:
            with open(pinfile) as fh:
                pinned = fh.read().strip()
        except OSError as e:
            return local, f"CANNOT CHECK — pin file {pinned} unreadable ({e.strerror})"
        if not pinned:
            return local, f"CANNOT CHECK — pin file {row['Pinned']} is empty"
    return local, github_head(upstream, pinned)


def installer_summary(locked, links):
    """Compare the lock's names against the symlinks in skills/. Pure, so the failing case
    can be watched with fixture data instead of assumed.

    Two SETS, never two totals. The subtraction this replaced (`len(links) - len(skills)`)
    let a lock entry with no symlink cancel out a symlink with no lock entry, which is not
    a hypothetical: `impeccable` is locked and unlinked, so a real count of 16 unlocked
    symlinks printed as 15. Worse, more lock entries than symlinks drove the number
    negative and the old `> 0` guard then suppressed the line entirely — the report going
    quiet exactly as the problem grew. Both numbers now print unconditionally, including
    the zero state, because "0 unlocked" is a result and a blank line is not.

    Names are the join key because that is what the installer itself uses
    (`skillName in lock.skills` in its cli.mjs). It cannot detect two different upstreams
    sharing one skill name, so the sources are printed alongside for a human to eyeball.
    """
    unlocked = sorted(set(links) - set(locked))
    ghosts = sorted(set(locked) - set(links))
    parts = [f"{len(locked)} locked, {len(links)} symlinks in skills/",
             f"{len(unlocked)} symlink(s) not in the lock file",
             f"{len(ghosts)} lock entr(y/ies) with no symlink"]
    if unlocked:
        parts.append("unlocked: " + ", ".join(unlocked))
    if ghosts:
        parts.append("no symlink: " + ", ".join(ghosts))
    return "; ".join(parts)


def check_installer(row):
    """Installer-managed skills. Per-skill health belongs to the ghost check in Step 5,
    which already owns it; duplicating it here would give two answers to one question.

    There is exactly ONE lock file, always at ~/.agents/.skill-lock.json (or under
    $XDG_STATE_HOME), never one per install root — read from the installer's own
    getSkillLockPath(). Skills land in two roots on this machine, and the root a skill
    lives in has no bearing on whether it is locked.
    """
    if not os.path.exists(SKILL_LOCK):
        return "MISSING — no ~/.agents/.skill-lock.json", "CANNOT CHECK — installer state absent"
    try:
        with open(SKILL_LOCK) as fh:
            skills = json.load(fh).get("skills", {})
    except (ValueError, OSError) as e:
        return f"unknown — skill-lock unreadable ({e})", "CANNOT CHECK — installer state unreadable"
    sources = sorted({(m.get("source", "?") if isinstance(m, dict) else "?") for m in skills.values()})
    links = [d for d in sorted(os.listdir(os.path.join(ROOT, "skills")))
             if os.path.islink(os.path.join(ROOT, "skills", d))]
    local = installer_summary(skills, links) + f"; sources: {', '.join(sources)}"
    return local, ("`npx skills update` iterates the lock's names only — an unlocked "
                   "symlink is skipped in silence, never updated and never reported")


def check_url_only(row):
    upstream = row.get("Upstream", "").strip()
    if not upstream or upstream == "unknown":
        return "no local copy", "CANNOT CHECK — no upstream recorded"
    return "no local copy", github_head(upstream, row.get("Pinned", "").strip().strip("`"))


def parse_manifest():
    """Strict parse. A manifest that cannot be trusted is a hard error, not a warning —
    a half-read manifest would silently drop the sources it failed to read, which is the
    original defect wearing a new hat."""
    if not os.path.exists(MANIFEST):
        sys.exit(f"borrowed_check: manifest not found at {MANIFEST}")
    with open(MANIFEST) as fh:
        lines = fh.read().splitlines()

    header_at = None
    for i, line in enumerate(lines):
        if line.strip().startswith("|") and "Name" in line and "How checked" in line:
            header_at = i
            break
    if header_at is None:
        sys.exit(f"borrowed_check: no manifest table found in {MANIFEST}")

    header = [c.strip() for c in lines[header_at].strip().strip("|").split("|")]
    if header != COLUMNS:
        sys.exit(f"borrowed_check: manifest columns are {header}, expected {COLUMNS}")

    rows = []
    for line in lines[header_at + 2:]:
        if not line.strip().startswith("|"):
            break
        values = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(values) != len(COLUMNS):
            sys.exit(f"borrowed_check: malformed manifest row ({len(values)} cells, expected "
                     f"{len(COLUMNS)}): {line.strip()[:80]}")
        rows.append(dict(zip(COLUMNS, values)))

    names = [r["Name"] for r in rows]
    dupes = sorted({n for n in names if names.count(n) > 1})
    if dupes:
        sys.exit(f"borrowed_check: duplicate manifest entries: {', '.join(dupes)}")
    bad = sorted({r["How checked"] for r in rows} - METHODS)
    if bad:
        sys.exit(f"borrowed_check: unknown check method(s) {bad}; allowed: {sorted(METHODS)}")
    if not rows:
        sys.exit("borrowed_check: manifest table is empty — nothing is being watched")
    return rows


def main():
    rows = parse_manifest()
    print("| Source | Method | Local state | Upstream state |")
    print("|---|---|---|---|")

    registered = set()
    for row in rows:
        method = row["How checked"]
        rel = row["Path"].strip().strip("`")
        path = os.path.join(ROOT, rel) if rel and rel != "—" else ""
        if path:
            registered.add(os.path.normpath(rel))

        if method == "installer":
            local, upstream = check_installer(row)
        elif method == "url-only":
            local, upstream = check_url_only(row)
        elif not os.path.isdir(path):
            local, upstream = "MISSING — in manifest, not on disk", "CANNOT CHECK — nothing on disk"
        elif method == "git":
            local, upstream = check_git(row, path)
        else:
            local, upstream = check_hash(row, path)

        print(f"| {cell(row['Name'])} | {cell(method)} | {cell(local)} | {cell(upstream)} |")

    for root in ROOTS:
        full = os.path.join(ROOT, root)
        if not os.path.isdir(full):
            print(f"| {cell(root)} | root | MISSING — declared root not on disk | "
                  f"CANNOT CHECK — nothing to reconcile |")
            continue
        for name in sorted(os.listdir(full)):
            rel = os.path.normpath(os.path.join(root, name))
            if os.path.isdir(os.path.join(full, name)) and rel not in registered:
                print(f"| {cell(rel)} | none | UNREGISTERED — on disk, not in the manifest | "
                      f"CANNOT CHECK — add it to docs/BORROWED.md |")


if __name__ == "__main__":
    main()
