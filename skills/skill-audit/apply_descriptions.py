#!/usr/bin/env python3
"""Put the short descriptions from short_descriptions.json back into each skill's SKILL.md.

Run it after any skill update (`npx skills update -g`, Orca updates, `impeccable update`),
because updates bring back the long upstream description and Claude Code's skill list cuts
long descriptions. Safe to run any time: a skill already matching is left alone.

Usage: python3 apply_descriptions.py [--check]
  --check  report which skills differ, change nothing
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SKILLS = os.path.expanduser("~/.claude/skills")


def main():
    check = "--check" in sys.argv
    wanted = json.load(open(os.path.join(HERE, "short_descriptions.json")))
    changed = missing = 0
    for name, desc in wanted.items():
        if name.startswith("_"):
            continue
        path = os.path.realpath(os.path.join(SKILLS, name, "SKILL.md"))
        if not os.path.exists(path):
            print(f"missing  {name}")
            missing += 1
            continue
        text = open(path).read()
        m = re.match(r"---\n(.*?)\n---", text, re.S)
        if not m:
            print(f"no frontmatter  {name}")
            continue
        fm = m.group(1)
        dm = re.search(r"^description:.*?(?=^[A-Za-z][\w-]*:|\Z)", fm, re.S | re.M)
        if not dm:
            print(f"no description  {name}")
            continue
        new_line = "description: " + json.dumps(desc, ensure_ascii=False) + "\n"
        if dm.group(0).rstrip("\n") == new_line.rstrip("\n"):
            continue
        changed += 1
        print(f"{'differs' if check else 'shortened'}  {name}")
        if not check:
            fm2 = (fm[: dm.start()] + new_line + fm[dm.end():]).rstrip("\n")
            open(path, "w").write("---\n" + fm2 + "\n---" + text[m.end():])
    print(f"{changed} {'differ' if check else 'shortened'}, {missing} missing")


if __name__ == "__main__":
    main()
