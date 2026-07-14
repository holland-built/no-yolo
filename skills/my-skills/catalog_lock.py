#!/usr/bin/env python3
"""Detect catalog drift MECHANICALLY instead of asking an LLM.

Records a sha256 of each skill's SKILL.md frontmatter `description` (the
source of truth) and of each catalog row that describes that skill, as of
the last verification. Mirrors the shape of the root skills-lock.json:
{"version": 1, "skills": {...}}.

This tool detects CHANGE, not correctness. A row that was always wrong and
has never been edited will NOT be flagged until a baseline verification
sweep (a human or agent checking every row against SKILL.md, then running
--relock) blesses it as current. After that, any further edit to either
side — the SKILL.md description or the catalog row — trips a mismatch.

Modes:
    --check   (default) compare current hashes to the lock, report drift,
              exit 1 on any mismatch/addition/removal, exit 0 if all match.
    --relock  recompute everything and overwrite the lock file, exit 0.
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path


HERE = Path(__file__).parent
REPO_ROOT = HERE.parent.parent
LOCK_PATH = HERE / "catalog-lock.json"

PIPE_FILES = [
    "STORIES.md",
    "TAGLINES.md",
    "TAGLINES_SHORT.md",
    "WHEN_TO_USE.md",
    "WHY_TO_USE.md",
]
TRIGGERS_FILE = "docs/SKILL_TRIGGERS.md"


def sha256(text: str) -> str:
    return hashlib.sha256(text.encode()).hexdigest()


def tracked_skill_names() -> list:
    """Skill names with a git-tracked SKILL.md, via `git ls-files`."""
    out = subprocess.run(
        ["git", "ls-files", "skills/*/SKILL.md"],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    names = []
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        # skills/<name>/SKILL.md
        parts = line.split("/")
        if len(parts) >= 3:
            names.append(parts[1])
    return sorted(set(names))


def desc_sha(name: str) -> str:
    """sha256 of the SKILL.md frontmatter `description` field.

    Deliberately line-based, NOT yaml.safe_load: 7 of 27 descriptions contain an
    unquoted ": " (e.g. "Full feature pipeline: evidence -> plan"), which YAML reads
    as a mapping and rejects. Claude Code parses these leniently, so we match it:
    take everything after the first `description:` to end of line. Single-line only,
    which holds for every tracked skill -- a block scalar (`description: >`) raises.
    """
    path = REPO_ROOT / "skills" / name / "SKILL.md"
    lines = path.read_text().splitlines()
    if not lines or lines[0].strip() != "---":
        raise ValueError(f"malformed frontmatter in {path}: no opening ---")
    description = None
    for line in lines[1:]:
        if line.strip() == "---":
            break
        if line.startswith("description:"):
            description = line.split(":", 1)[1].strip()
            if description in (">", "|", ">-", "|-"):
                raise ValueError(
                    f"{path}: block-scalar description not supported -- "
                    "hash would silently cover only the first line"
                )
            break
    if description is None:
        raise ValueError(f"{path}: no `description:` in frontmatter")
    return sha256(description)


def parse_pipe_file(relpath: str) -> dict:
    """my-skills/<relpath> -> {name: row_sha}. Ignores blank/#/section lines."""
    path = HERE / relpath
    result = {}
    if not path.exists():
        return result
    for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.rstrip("\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.count("|") == 0:
            raise ValueError(f"{relpath}:{lineno}: no pipe in row: {line!r}")
        name, _, value = line.partition("|")
        name = name.strip()
        if name.startswith("rel:") or name.startswith("bolt:"):
            continue
        result[name] = sha256(value.strip())
    return result


def parse_triggers_file() -> dict:
    """docs/SKILL_TRIGGERS.md -> {name: row_sha}, from `- **name** — rest`."""
    path = REPO_ROOT / TRIGGERS_FILE
    result = {}
    if not path.exists():
        return result
    for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.rstrip("\n")
        if not line.startswith("- **"):
            continue
        rest = line[len("- **"):]
        if "**" not in rest:
            raise ValueError(f"{TRIGGERS_FILE}:{lineno}: unclosed ** in row: {line!r}")
        name, _, tail = rest.partition("**")
        name = name.strip()
        tail = tail.strip()
        if tail.startswith("—"):
            tail = tail[1:].strip()
        elif tail.startswith("-"):
            tail = tail[1:].strip()
        result[name] = sha256(tail)
    return result


def compute_current() -> dict:
    """{name: {"descSha": ..., "rows": {relpath: sha}}} for every tracked skill."""
    names = tracked_skill_names()
    row_sources = {}
    for relpath in PIPE_FILES:
        row_sources[f"skills/my-skills/{relpath}"] = parse_pipe_file(relpath)
    row_sources[TRIGGERS_FILE] = parse_triggers_file()

    current = {}
    for name in names:
        rows = {}
        for relpath, mapping in row_sources.items():
            if name in mapping:
                rows[relpath] = mapping[name]
        current[name] = {"descSha": desc_sha(name), "rows": rows}
    return current


def load_lock() -> dict:
    if not LOCK_PATH.exists():
        return None
    return json.loads(LOCK_PATH.read_text())


def write_lock(current: dict) -> None:
    data = {"version": 1, "skills": current}
    LOCK_PATH.write_text(json.dumps(data, sort_keys=True, indent=2) + "\n")


def check() -> int:
    lock = load_lock()
    if lock is None:
        print(
            "catalog lock: no lock file found at "
            f"{LOCK_PATH}. Verify each skill's catalog rows against its "
            "SKILL.md description, then run --relock."
        )
        return 1

    current = compute_current()
    locked = lock.get("skills", {})

    problems = []

    for name in sorted(set(current) | set(locked)):
        cur = current.get(name)
        old = locked.get(name)

        if cur is None:
            problems.append(f"REMOVED: {name}")
            continue
        if old is None:
            problems.append(f"UNLOCKED: {name} — never verified")
            continue

        if cur["descSha"] != old.get("descSha"):
            relpaths = sorted(cur["rows"])
            problems.append(
                f"TRUTH CHANGED: {name} — SKILL.md description edited; "
                f"re-verify its rows: {relpaths}"
            )

        cur_rows = cur["rows"]
        old_rows = old.get("rows", {})
        for relpath in sorted(set(cur_rows) | set(old_rows)):
            if relpath in cur_rows and relpath not in old_rows:
                problems.append(f"ROW ADDED: {name} @ {relpath}")
            elif relpath not in cur_rows and relpath in old_rows:
                problems.append(f"ROW REMOVED: {name} @ {relpath}")
            elif cur_rows[relpath] != old_rows[relpath]:
                problems.append(
                    f"ROW CHANGED: {name} @ {relpath} — catalog edited; "
                    "re-verify against SKILL.md"
                )

    if problems:
        for p in problems:
            print(p)
        return 1

    print(f"catalog lock: current ({len(current)} skills)")
    return 0


def relock() -> int:
    old_lock = load_lock()
    old_skills = old_lock.get("skills", {}) if old_lock else {}
    current = compute_current()

    added = sorted(set(current) - set(old_skills))
    removed = sorted(set(old_skills) - set(current))
    changed = sorted(
        name
        for name in set(current) & set(old_skills)
        if current[name] != old_skills[name]
    )

    write_lock(current)

    if not old_skills:
        print(f"catalog lock: seeded {len(current)} skills")
    else:
        print(f"catalog lock: relocked ({len(current)} skills)")
        if added:
            print(f"  added: {added}")
        if removed:
            print(f"  removed: {removed}")
        if changed:
            print(f"  changed: {changed}")
        if not (added or removed or changed):
            print("  no changes")
    return 0


def main() -> int:
    args = sys.argv[1:]
    if args and args[0] == "--relock":
        return relock()
    if not args or args[0] == "--check":
        return check()
    print(f"unknown argument: {args[0]!r} (use --check or --relock)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
