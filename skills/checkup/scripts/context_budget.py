#!/usr/bin/env python3
"""context_budget.py — how many bytes CLAUDE.md drags into every single session.

CLAUDE.md's @import lines are unconditional: whatever they name is loaded before the
user has typed anything, on a backend task as much as a design one. Nothing measured
that until 2026-08-18, when the GUI half of the slop list turned out to be 10,120 bytes
that most sessions never consult.

Reports the number and the per-file breakdown. It sets no ceiling and fails nothing —
a threshold nobody measured is exactly the invented number this repo's first rule bans.
When a real limit is known, write it down in docs/BORROWED.md's sibling policy and
enforce that value; do not bury one in this file.

Writes nothing. Exit code 0 unless CLAUDE.md itself is unreadable.
"""

import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
ENTRY = os.path.join(ROOT, "CLAUDE.md")


def imports_of(path):
    """@import lines only. A pointer inside prose is read on demand and costs nothing."""
    out = []
    with open(path) as fh:
        for line in fh:
            s = line.strip()
            if s.startswith("@") and not s.startswith("@@"):
                out.append(s[1:].split()[0])
    return out


def main():
    if not os.path.exists(ENTRY):
        sys.exit(f"context_budget: no CLAUDE.md at {ENTRY}")

    rows = [("CLAUDE.md", os.path.getsize(ENTRY), "entry point")]
    missing = []
    seen = {"CLAUDE.md"}
    queue = [(ENTRY, i) for i in imports_of(ENTRY)]

    while queue:
        parent, rel = queue.pop(0)
        target = os.path.normpath(os.path.join(os.path.dirname(parent), rel))
        name = os.path.relpath(target, ROOT)
        if name in seen:
            continue
        seen.add(name)
        if not os.path.exists(target):
            missing.append((name, os.path.relpath(parent, ROOT)))
            continue
        rows.append((name, os.path.getsize(target), "imported"))
        # Imports nest: an imported file's own @imports load too.
        queue.extend((target, i) for i in imports_of(target))

    total = sum(size for _, size, _ in rows)
    print("| File | Bytes | Share | Role |")
    print("|---|---|---|---|")
    for name, size, role in sorted(rows, key=lambda r: -r[1]):
        print(f"| {name} | {size:,} | {round(100 * size / total)}% | {role} |")
    print(f"| **total loaded every session** | **{total:,}** | 100% | |")

    for name, parent in missing:
        print(f"| {name} | unknown | unknown | **BROKEN IMPORT — named by {parent}, not on disk** |")

    if missing:
        print()
        print(f"{len(missing)} import(s) name a file that does not exist. An @import that cannot "
              "resolve loads nothing and says nothing — the rules in it are simply absent.")


if __name__ == "__main__":
    main()
