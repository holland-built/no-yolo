#!/usr/bin/env python3
"""Keep skill descriptions short after updates, without losing what the update brought in.

Updates bring back each skill's long upstream description, and Claude Code's skill list cuts
long descriptions. short_descriptions.json holds, per skill, the short version and a
fingerprint of the upstream text it was written from. For each skill:

- description already short: nothing to do.
- upstream text is the one the short version was written from: put the short version back.
- upstream text is new: leave it, and report it, so a fresh short version gets written from
  the latest text instead of an old one hiding it.

Usage:
  python3 apply_descriptions.py            apply, report every change
  python3 apply_descriptions.py --check    report only, change nothing
  python3 apply_descriptions.py --quiet    print only skills whose upstream changed (startup hook)
  python3 apply_descriptions.py --set NAME "short text"
                                           save a new short version written from the current
                                           upstream description, and apply it
"""
import hashlib, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
STORE = os.path.join(HERE, "short_descriptions.json")
SKILLS = os.path.expanduser("~/.claude/skills")


def norm(s):
    return " ".join(s.split())


def fingerprint(s):
    return hashlib.sha256(norm(s).encode()).hexdigest()[:16]


def read_desc(path):
    """Return (text, frontmatter match, description match, description value) or None."""
    text = open(path).read()
    m = re.match(r"---\n(.*?)\n---", text, re.S)
    if not m:
        return None
    fm = m.group(1)
    dm = re.search(r"^description:(.*?)(?=^[A-Za-z][\w-]*:|\Z)", fm, re.S | re.M)
    if not dm:
        return None
    raw = dm.group(1).strip()
    # strip YAML block markers and quotes to compare plain text
    raw = re.sub(r"^[>|][-+]?\s*", "", raw)
    if raw[:1] in "\"'" and raw[-1:] == raw[:1]:
        try:
            raw = json.loads(raw) if raw[0] == '"' else raw[1:-1]
        except ValueError:
            raw = raw[1:-1]
    return text, m, dm, norm(raw)


def write_desc(path, text, m, dm, desc):
    fm = m.group(1)
    line = "description: " + json.dumps(desc, ensure_ascii=False) + "\n"
    fm2 = (fm[: dm.start()] + line + fm[dm.end():]).rstrip("\n")
    open(path, "w").write("---\n" + fm2 + "\n---" + text[m.end():])


def skill_path(name):
    return os.path.realpath(os.path.join(SKILLS, name, "SKILL.md"))


def main():
    args = sys.argv[1:]
    store = json.load(open(STORE))

    if args[:1] == ["--set"]:
        name, short = args[1], norm(args[2])
        got = read_desc(skill_path(name))
        if not got:
            sys.exit(f"cannot read {name}")
        text, m, dm, cur = got
        entry = store.get(name, {})
        # the current text is the upstream one unless it is already our short version
        if cur != norm(entry.get("short", "")):
            entry["upstream"] = fingerprint(cur)
        entry["short"] = short
        store[name] = entry
        json.dump(store, open(STORE, "w"), indent=2, ensure_ascii=False)
        open(STORE, "a").write("\n")
        write_desc(skill_path(name), text, m, dm, short)
        print(f"saved and applied  {name}")
        return

    check, quiet = "--check" in args, "--quiet" in args
    changed_upstream = []
    for name, entry in store.items():
        if name.startswith("_"):
            continue
        path = skill_path(name)
        got = os.path.exists(path) and read_desc(path)
        if not got:
            if not quiet:
                print(f"missing  {name}")
            continue
        text, m, dm, cur = got
        if cur == norm(entry["short"]):
            continue
        if entry.get("upstream") == fingerprint(cur):
            if not check:
                write_desc(path, text, m, dm, entry["short"])
            if not quiet:
                print(f"{'would shorten' if check else 'shortened'}  {name}")
        else:
            changed_upstream.append((name, cur))

    if changed_upstream:
        if quiet:
            names = ", ".join(n for n, _ in changed_upstream)
            print(f"Skill descriptions changed upstream and need a new short version: {names}. "
                  f"See 'Short descriptions' in ~/.claude/skills/skill-audit/SKILL.md.")
        else:
            for name, cur in changed_upstream:
                print(f"upstream changed  {name}\n    new text: {cur}")


if __name__ == "__main__":
    main()
