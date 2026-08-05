#!/usr/bin/env python3
"""Generate MAP.md — one page listing everything installed in ~/.claude.

Everything here is measured from disk and from session transcripts. Nothing is
hand-maintained, so it cannot go stale: re-run the script instead of editing MAP.md.

    python3 ~/.claude/bin/build-map.py
"""
import collections
import glob
import json
import os
import re
import sys

ROOT = os.path.expanduser("~/.claude")
OUT = os.path.join(ROOT, "MAP.md")

# Skills that duplicate something Claude Code ships with.
NATIVE_OVERLAP = {
    "health": "/review + /security-review",
    "plan": "plan mode",
    "lockstep": "plan mode",
    "diagnose": "partly — plan mode + normal debugging",
}


def count_uses():
    """Real invocations only: a Skill tool_use, or a slash command the user typed.

    Every skill's description is injected into every session, so a plain text
    search returns thousands of false hits. Only these two signals count.
    """
    skill, cmd, agent = (collections.Counter() for _ in range(3))
    seen = set()
    pattern = re.compile(r"<command-name>\s*/?([\w:-]+)\s*</command-name>")
    files = glob.glob(os.path.join(ROOT, "projects", "**", "*.jsonl"), recursive=True)
    for path in files:
        try:
            with open(path, errors="ignore") as fh:
                for line in fh:
                    if '"Skill"' not in line and "<command-name>" not in line \
                            and "subagent_type" not in line:
                        continue
                    try:
                        rec = json.loads(line)
                    except ValueError:
                        continue
                    kind = rec.get("type")
                    uuid = rec.get("uuid")
                    content = (rec.get("message") or {}).get("content")
                    if kind == "assistant" and isinstance(content, list):
                        for i, block in enumerate(content):
                            if not isinstance(block, dict) or block.get("type") != "tool_use":
                                continue
                            data = block.get("input") or {}
                            if block.get("name") == "Skill" and data.get("skill"):
                                key = (uuid, i, "s")
                                if key not in seen:
                                    seen.add(key)
                                    skill[data["skill"]] += 1
                            elif block.get("name") in ("Task", "Agent") and data.get("subagent_type"):
                                key = (uuid, i, "a")
                                if key not in seen:
                                    seen.add(key)
                                    agent[data["subagent_type"]] += 1
                    elif kind == "user" and rec.get("toolUseResult") is None:
                        texts = []
                        if isinstance(content, str):
                            texts = [content]
                        elif isinstance(content, list):
                            texts = [b.get("text", "") for b in content
                                     if isinstance(b, dict) and b.get("type") == "text"]
                        for i, text in enumerate(texts):
                            for name in pattern.findall(text or ""):
                                key = (uuid, i, name)
                                if key not in seen:
                                    seen.add(key)
                                    cmd[name] += 1
        except OSError:
            continue
    return skill, cmd, agent, len(files)


def frontmatter(path):
    """Return the YAML frontmatter as a dict of raw strings. Tolerates bad YAML."""
    out = {}
    try:
        with open(path, errors="ignore") as fh:
            if fh.readline().strip() != "---":
                return out
            for line in fh:
                if line.strip() == "---":
                    break
                match = re.match(r"^([a-zA-Z_-]+):\s*(.*)$", line)
                if match:
                    out[match.group(1)] = match.group(2).strip().strip('"\'')
    except OSError:
        pass
    return out


def skills(uses):
    rows = []
    base = os.path.join(ROOT, "skills")
    for name in sorted(os.listdir(base)):
        path = os.path.join(base, name)
        skill_md = os.path.join(path, "SKILL.md")
        if not os.path.exists(skill_md):
            continue
        meta = frontmatter(skill_md)
        if os.path.islink(path):
            origin = "third-party"
        else:
            origin = "yours"
        if meta.get("disable-model-invocation") == "true":
            kind = "reference only"
        elif meta.get("user-invocable") == "true":
            kind = "command"
        else:
            kind = "auto-triggered"
        rows.append((name, uses.get(name, 0), origin, kind,
                     NATIVE_OVERLAP.get(name, "")))
    return rows


def agents(uses):
    rows = []
    base = os.path.join(ROOT, "agents")
    if not os.path.isdir(base):
        return rows
    for fn in sorted(os.listdir(base)):
        if not fn.endswith(".md"):
            continue
        meta = frontmatter(os.path.join(base, fn))
        name = meta.get("name", fn[:-3])
        rows.append((name, uses.get(name, 0), meta.get("model", "inherit"),
                     meta.get("tools", "all")))
    return rows


# node-shim.sh only re-execs the script that follows it — never the real hook.
WRAPPERS = {"node-shim.sh"}
SCRIPT_RE = re.compile(r"[\w./$%{}-]+\.(?:js|sh|py)")


def hook_target(cmd):
    """(script, owner) for one hook command.

    Three shapes live in settings.json and the last token is wrong for all of them:
      bash .../node-shim.sh .../slop-guard.js SessionStart   -> last token is an argument
      if [ -f '.../claude-hook.sh' ] ...; then ...; fi        -> last token is `fi`
      [ -n "$SUPACODE_SURFACE_ID" ] && { ... }                -> no script file at all
    """
    scripts = [os.path.basename(m) for m in SCRIPT_RE.findall(cmd or "")]
    scripts = [s for s in scripts if s not in WRAPPERS]
    if not scripts:
        return "(inline shell)", "Supacode"
    mine = [s for s in scripts if os.path.exists(os.path.join(ROOT, "hooks", s))]
    if mine:
        return mine[0], "yours"
    if "/.orca/" in cmd:
        return scripts[0], "Orca"
    return scripts[0], "other"


def hooks():
    """Map each registered hook to its event. Unregistered scripts are listed too."""
    rows = []
    registered = set()
    try:
        with open(os.path.join(ROOT, "settings.json")) as fh:
            for event, matchers in (json.load(fh).get("hooks") or {}).items():
                for matcher in matchers:
                    for hook in matcher.get("hooks", []):
                        script, owner = hook_target(hook.get("command", ""))
                        registered.add(script)
                        rows.append((event, script, owner))
    except (OSError, ValueError):
        pass
    extra = []
    base = os.path.join(ROOT, "hooks")
    if os.path.isdir(base):
        for fn in sorted(os.listdir(base)):
            if fn.endswith((".sh", ".js", ".py")) and fn not in registered \
                    and fn not in WRAPPERS:
                extra.append(fn)
    return rows, extra


def table(header, rows):
    if not rows:
        return "_none_\n"
    out = ["| " + " | ".join(header) + " |",
           "|" + "|".join(["---"] * len(header)) + "|"]
    for row in rows:
        out.append("| " + " | ".join(str(c) if c != "" else "—" for c in row) + " |")
    return "\n".join(out) + "\n"


def main():
    stamp = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    skill_uses, cmd_uses, agent_uses, scanned = count_uses()
    combined = collections.Counter(skill_uses) + collections.Counter(cmd_uses)

    srows = skills(combined)
    arows = agents(agent_uses)
    hrows, unregistered = hooks()

    docs = sorted(glob.glob(os.path.join(ROOT, "docs", "*.md")))
    facts = sorted(glob.glob(os.path.join(ROOT, "memory", "facts", "*.md")))

    try:
        with open(os.path.join(ROOT, "plugins", "installed_plugins.json")) as fh:
            plugins = sorted(json.load(fh).get("plugins", {}))
    except (OSError, ValueError):
        plugins = []

    total = len(srows) + len(arows) + len(hrows) + len(docs) + len(facts) + len(plugins)
    used = sum(1 for r in srows if r[1] > 0)

    parts = [
        "# MAP — everything installed in ~/.claude\n",
        f"Generated by `bin/build-map.py` on {stamp}. **Do not edit by hand** — "
        f"re-run the script.\nUsage counts are real invocations only, measured "
        f"across {scanned:,} session files.\n",
        f"**{total} pieces total.** {len(srows)} skills ({used} ever used), "
        f"{len(arows)} agents, {len(hrows)} hooks, {len(docs)} rule docs, "
        f"{len(facts)} memory facts, {len(plugins)} plugins.\n",
        "\n## Skills — things you type\n",
        table(["Skill", "Uses", "Whose", "Kind", "Claude already has"],
              sorted(srows, key=lambda r: -r[1])),
        "\n## Agents — specialists that get handed a job\n",
        table(["Agent", "Uses", "Model", "Tools"], sorted(arows, key=lambda r: -r[1])),
        "\n## Hooks — scripts that fire on their own\n",
        table(["When", "Script", "Whose"], hrows),
    ]
    if unregistered:
        parts.append("\nScripts present but not wired to any event (called by "
                     "other tools): " + ", ".join(f"`{s}`" for s in unregistered) + "\n")
    parts += [
        "\n## Rule docs — markdown Claude reads for instructions\n",
        table(["Doc", "Lines"],
              [(os.path.basename(d), sum(1 for _ in open(d, errors="ignore")))
               for d in docs]),
        "\n## Memory facts — your saved preferences\n",
        table(["Fact"], [(os.path.basename(f)[:-3],) for f in facts]),
        "\n## Plugins\n",
        table(["Plugin"], [(p,) for p in plugins]),
        "\n## Outside connections (MCP servers)\n",
        "Live services Claude can call. These are configured by the Claude desktop "
        "app and Orca, **not** by files in `~/.claude`, so this script cannot list "
        "them reliably. Run `/mcp` in a session to see the current set.\n",
    ]

    with open(OUT, "w") as fh:
        fh.write("".join(parts))
    print(f"wrote {OUT}  ({total} pieces, {scanned:,} session files scanned)")


if __name__ == "__main__":
    main()
