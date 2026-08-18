#!/usr/bin/env python3
"""design_doors.py — has a second design door appeared?

`docs/DESIGN_SURFACES.md` records the decision that `/design` is the entry point and everything
else design-related is reference material. That decision decays silently: an installer adds a
skill, a plugin gets enabled, a CLI upgrade ships a new bundled one, and nothing anywhere says
a rival is back. Five design skills accumulated here that way and none was ever deliberately
used.

This enumerates the routes a design surface can arrive through and compares what it finds
against the allowlist in that file. It reports; it never removes anything — something installed
a rival on purpose, possibly the owner.

A route that cannot be enumerated prints CANNOT CHECK with its reason and is never counted as
zero rivals. "I could not look" and "I looked and it was clean" are different sentences.

Writes nothing. Exit 0 unless DESIGN_SURFACES.md is unreadable.
"""

import json
import os
import re
import subprocess
import sys

ROOT = os.environ.get("CHECKUP_ROOT") or os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
SURFACES = os.path.join(ROOT, "docs", "DESIGN_SURFACES.md")

# A surface is a design surface if its name or description would plausibly answer
# "redesign this page". Deliberately broad — a false positive costs one line in a report,
# a false negative is a rival nobody sees.
DESIGN_WORDS = re.compile(
    r"\b(design|ui|ux|interface|visual|layout|typograph|colou?r|palette|animation|motion|"
    r"mockup|wireframe|frontend|css|chart|dashboard|aesthetic|brand|styling)\b", re.I)


def cell(t):
    return str(t).replace("|", "\\|").replace("\n", " ").strip() or "unknown"


def frontmatter(path):
    fm, seen = [], 0
    try:
        with open(path, errors="replace") as fh:
            for line in fh:
                if line.strip() == "---":
                    seen += 1
                    if seen == 2:
                        break
                    continue
                if seen == 1:
                    fm.append(line)
    except OSError:
        return None
    return "".join(fm)


def roster():
    """Read the roster table out of DESIGN_SURFACES.md: surface -> verdict.

    The verdict is a judgement a person made once. This script never re-derives it — an
    earlier version tried to classify by keyword and was wrong on nine surfaces out of nine,
    because `eli5`, `xcheck`, `build` and `debate` all discuss interfaces without being one.
    All the machine does is notice what is NEW and what has CHANGED underneath the roster.
    """
    if not os.path.exists(SURFACES):
        sys.exit(f"design_doors: {SURFACES} not found — the roster IS the check")
    verdicts = {}
    for line in open(SURFACES).read().splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 4:
            continue
        m = re.match(r"^`([^`]+)`$", cells[0])
        if not m:
            continue
        v = cells[2].replace("*", "").strip().lower()
        if v.startswith("door"):
            verdicts[m.group(1)] = "door"
        elif v == "reference":
            verdicts[m.group(1)] = "reference"
        elif v.startswith("not a surface"):
            verdicts[m.group(1)] = "not a surface"
    if not verdicts:
        sys.exit("design_doors: no roster rows parsed from DESIGN_SURFACES.md — refusing to "
                 "report every surface as unclassified")
    return verdicts


def rows():
    verdicts = roster()
    out = []
    seen = set()

    def report(name, route, note, invocable=True):
        """One row. UNCLASSIFIED = new since a person last looked. RIVAL REAPPEARED = the
        roster says reference, but the thing is model-invocable again."""
        seen.add(name)
        v = verdicts.get(name)
        if v is None:
            out.append((name, route, "UNCLASSIFIED", note + " — classify it in DESIGN_SURFACES.md"))
        elif v == "reference" and invocable:
            out.append((name, route, "RIVAL REAPPEARED",
                        note + " — roster says reference; it lost disable-model-invocation"))
        elif v == "door":
            out.append((name, route, "door", note))
        # `reference` that is correctly non-invocable, and `not a surface`, are silent.
        # A check that prints twenty healthy rows buries the one that matters.

    # Routes 1 and 2 — anything under skills/, own or symlinked. Model-invocable is the
    # property that matters: user-invocable only controls whether a human can type /name.
    skills_dir = os.path.join(ROOT, "skills")
    if not os.path.isdir(skills_dir):
        out.append(("skills/", "1+2", "CANNOT CHECK", "no skills/ directory"))
    else:
        for name in sorted(os.listdir(skills_dir)):
            path = os.path.join(skills_dir, name, "SKILL.md")
            if not os.path.exists(path):
                continue
            fm = frontmatter(path)
            if fm is None:
                out.append((name, "1+2", "CANNOT CHECK", "SKILL.md unreadable"))
                continue
            invocable = not re.search(r"^disable-model-invocation:\s*true", fm, re.M)
            known = name in verdicts
            # Unknown skills are only worth a row if they look design-shaped at all; known
            # ones are always checked, because a demotion silently coming undone is the point.
            if not known and not DESIGN_WORDS.search(name + " " + fm):
                continue
            kind = "symlinked" if os.path.islink(os.path.join(skills_dir, name)) else "own"
            state = "model-invocable" if invocable else "reference-only"
            report(name, "1+2", f"{kind} skill, {state}", invocable=invocable)

    # Route 3 — enabled plugins.
    settings = os.path.join(ROOT, "settings.json")
    if not os.path.exists(settings):
        out.append(("enabledPlugins", "3", "CANNOT CHECK", "no settings.json"))
    else:
        try:
            enabled = json.load(open(settings)).get("enabledPlugins", {})
        except (ValueError, OSError) as e:
            out.append(("enabledPlugins", "3", "CANNOT CHECK", f"settings.json unreadable ({e})"))
            enabled = None
        if enabled is not None:
            for spec, on in sorted(enabled.items()):
                if not on:
                    continue
                plugin = spec.split("@")[0]
                marketplace = spec.split("@")[-1]
                mp = os.path.join(ROOT, "plugins", "marketplaces", marketplace)
                hits = []
                for dirpath, _, files in os.walk(mp):
                    if "SKILL.md" in files:
                        sk = os.path.basename(dirpath)
                        fm = frontmatter(os.path.join(dirpath, "SKILL.md")) or ""
                        if DESIGN_WORDS.search(sk + " " + fm):
                            hits.append(sk)
                for sk in sorted(set(hits)):
                    report(f"{plugin}:{sk}", "3", f"enabled plugin from {marketplace}")

    # Route 4 — cloned but NOT enabled. The one that gets forgotten: one settings entry from
    # being a door, and invisible in any running session.
    mroot = os.path.join(ROOT, "plugins", "marketplaces")
    if not os.path.isdir(mroot):
        out.append(("plugins/marketplaces", "4", "CANNOT CHECK",
                    "not on disk — gitignored, absent on a fresh clone"))
    else:
        try:
            enabled_mps = {s.split("@")[-1] for s, on
                           in json.load(open(settings)).get("enabledPlugins", {}).items() if on}
        except Exception:
            enabled_mps = set()
        dormant = []
        for mp in sorted(os.listdir(mroot)):
            if mp in enabled_mps or not os.path.isdir(os.path.join(mroot, mp)):
                continue
            for dirpath, _, files in os.walk(os.path.join(mroot, mp)):
                if "SKILL.md" in files:
                    sk = os.path.basename(dirpath)
                    fm = frontmatter(os.path.join(dirpath, "SKILL.md")) or ""
                    if DESIGN_WORDS.search(sk + " " + fm):
                        dormant.append(f"{mp}/{sk}")
        for d in sorted(set(dormant)):
            if d in verdicts:
                continue     # known dormant, recorded as such — silent
            out.append((d, "4", "UNCLASSIFIED",
                        "cloned, not enabled — one settings entry from a door; "
                        "classify it in DESIGN_SURFACES.md"))

    # Route 5 — slash commands.
    cmds = os.path.join(ROOT, "commands")
    if os.path.isdir(cmds):
        for f in sorted(os.listdir(cmds)):
            if f.endswith(".md") and DESIGN_WORDS.search(f):
                report(f[:-3], "5", "slash command in commands/")

    # Route 6 — agents.
    agents = os.path.join(ROOT, "agents")
    if os.path.isdir(agents):
        for f in sorted(os.listdir(agents)):
            if not f.endswith(".md"):
                continue
            try:
                head = open(os.path.join(agents, f), errors="replace").read(2000)
            except OSError:
                out.append((f, "6", "CANNOT CHECK", "agent file unreadable"))
                continue
            if DESIGN_WORDS.search(f + " " + head):
                report(f[:-3], "6", "agent")

    # Route 7 — bundled into the CLI. Not this repo's to change; the point is to notice when
    # an upgrade adds one, so the version is reported alongside.
    code, ver, _ = 1, "", ""
    try:
        p = subprocess.run(["claude", "--version"], capture_output=True, text=True, timeout=30)
        code, ver = p.returncode, p.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        pass
    if code != 0 or not ver:
        out.append(("bundled skills", "7", "CANNOT CHECK",
                    "claude --version did not answer; cannot tell which build is installed"))
    else:
        out.append(("bundled skills", "7", "NOT OURS",
                    f"compiled into {ver} — see DESIGN_SURFACES.md route 7. Re-read the list "
                    "when this version changes"))

    return out, verdicts


def main():
    out, verdicts = rows()
    print("| Surface | Route | Status | Note |")
    print("|---|---|---|---|")
    for name, route, status, note in out:
        print(f"| {cell(name)} | {cell(route)} | {cell(status)} | {cell(note)} |")
    rivals = sum(1 for r in out if r[2] == "RIVAL REAPPEARED")
    unclass = sum(1 for r in out if r[2] == "UNCLASSIFIED")
    blind = sum(1 for r in out if r[2] == "CANNOT CHECK")
    refs = sum(1 for v in verdicts.values() if v == "reference")
    print(f"| **{rivals} rival(s) reappeared, {unclass} unclassified** | | | "
          f"{refs} reference surfaces held; {blind} route(s) unreadable; "
          f"{len(verdicts)} on the roster |")


if __name__ == "__main__":
    main()
