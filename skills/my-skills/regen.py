#!/usr/bin/env python3
"""Regenerate skills/my-skills/RENDERED.md and RENDERED_FAST.md from the
pipe-delimited catalog sources (CATEGORIES.md, TAGLINES.md,
TAGLINES_SHORT.md, WHEN_TO_USE.md, WHY_TO_USE.md).

Run this after editing any of the five source files. Never hand-edit
RENDERED.md or RENDERED_FAST.md directly — they are derived output.

Modes:
    (no args)  regenerate both RENDERED files
    --check    render in memory and compare to what's on disk. Exit 1 if either
               is stale. Writes NOTHING — a check must not mutate what it checks.

Why --check exists: editing a source and re-locking the catalog WITHOUT regen
left verify.sh fully green while RENDERED.md was stale. The catalog lock hashes
the SOURCES, not this derived output, so it cannot see that gap. verify.sh calls
--check so the gap cannot ship.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
MISSING_MARK = "⚠️ missing"
EMDASH = "—"


def parse_pipe_file(path: Path) -> dict:
    """name -> value, skipping blank lines and #-comment lines."""
    result = {}
    if not path.exists():
        return result
    for line in path.read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        name, _, value = line.partition("|")
        result[name.strip()] = value.strip()
    return result


def parse_categories(path: Path) -> list:
    """Ordered list of (section, [names])."""
    sections = []
    current_names = None
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("## "):
            current_names = []
            sections.append((stripped[3:], current_names))
        elif current_names is not None:
            current_names.append(stripped)
    return sections


def build_rendered(sections, taglines, when_to_use, why_to_use) -> str:
    blocks = []
    header = "| Skill | What it does | When to use | Why vs manual |\n| --- | --- | --- | --- |"
    for section, names in sections:
        rows = []
        for name in names:
            tagline = taglines.get(name, MISSING_MARK)
            when = when_to_use.get(name, EMDASH)
            why = why_to_use.get(name, EMDASH)
            rows.append(f"| {name} | {tagline} | {when} | {why} |")
        block = f"## {section}\n\n{header}\n" + "\n".join(rows)
        blocks.append(block)
    return "\n\n".join(blocks) + "\n"


def parse_argument_hint(skill_md: Path) -> str:
    """Extract the argument-hint: value from a SKILL.md frontmatter block."""
    in_frontmatter = False
    for line in skill_md.read_text().splitlines():
        if line.strip() == "---":
            if in_frontmatter:
                break
            in_frontmatter = True
            continue
        if in_frontmatter and line.startswith("argument-hint:"):
            return line.split(":", 1)[1].strip().strip('"')
    return ""


def build_flags_section(sections) -> str:
    """'## Flags & arguments' table — one row per skill with a non-empty
    argument-hint in its SKILL.md frontmatter, alphabetical by skill name."""
    rows = []
    for _section, names in sections:
        for name in names:
            skill_md = HERE.parent / name / "SKILL.md"
            if not skill_md.exists():
                continue
            hint = parse_argument_hint(skill_md)
            if not hint:
                continue
            rows.append((name, hint))
    rows.sort(key=lambda r: r[0])
    header = "## Flags & arguments\n\n| Skill | Arguments & flags |\n| --- | --- |"
    body = "\n".join(f"| {name} | `{hint.replace('|', '\\|')}` |" for name, hint in rows)
    return f"{header}\n{body}\n"


def build_rendered_fast(sections, taglines_short) -> str:
    names = [name for section, section_names in sections
             if not section.startswith("Helpers")
             for name in section_names]
    header = "| Skill | What it does | Skill | What it does |\n| --- | --- | --- | --- |"
    rows = []
    for i in range(0, len(names), 2):
        name_a = names[i]
        tag_a = taglines_short.get(name_a, MISSING_MARK)
        if i + 1 < len(names):
            name_b = names[i + 1]
            tag_b = taglines_short.get(name_b, MISSING_MARK)
        else:
            name_b, tag_b = EMDASH, EMDASH
        rows.append(f"| {name_a} | {tag_a} | {name_b} | {tag_b} |")
    return header + "\n" + "\n".join(rows) + "\n"


def main():
    categories = parse_categories(HERE / "CATEGORIES.md")
    taglines = parse_pipe_file(HERE / "TAGLINES.md")
    taglines_short = parse_pipe_file(HERE / "TAGLINES_SHORT.md")
    when_to_use = parse_pipe_file(HERE / "WHEN_TO_USE.md")
    why_to_use = parse_pipe_file(HERE / "WHY_TO_USE.md")

    flags_section = build_flags_section(categories)
    rendered = build_rendered(categories, taglines, when_to_use, why_to_use)
    rendered += "\n" + flags_section
    rendered_fast = build_rendered_fast(categories, taglines_short)
    flags_doc = (
        "# Flags & arguments — every skill\n\n"
        "<!-- GENERATED by skills/my-skills/regen.py from each SKILL.md's "
        "argument-hint. Do NOT hand-edit — edit the skill's frontmatter and "
        "re-run regen. -->\n\n"
        "Every argument and flag each skill accepts, straight from the skill "
        "files themselves. Typing the command in Claude Code shows the same "
        "hint inline.\n\n"
        + flags_section.split("\n", 1)[1].lstrip("\n")
    )

    targets = [(HERE / "RENDERED.md", rendered),
               (HERE / "RENDERED_FAST.md", rendered_fast),
               (HERE.parent.parent / "docs" / "FLAGS.md", flags_doc)]

    if "--check" in sys.argv:
        stale = [p.name for p, want in targets
                 if not p.exists() or p.read_text() != want]
        if stale:
            print("STALE (a source changed but regen never ran): " + ", ".join(stale))
            print("fix: python3 skills/my-skills/regen.py")
            return 1
        print(f"rendered menus: current ({len(targets)} files)")
        return 0

    for p, want in targets:
        p.write_text(want)
    return 0


if __name__ == "__main__":
    sys.exit(main())
