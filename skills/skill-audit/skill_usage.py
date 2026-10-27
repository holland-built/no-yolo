#!/usr/bin/env python3
"""List every skill Claude Code and Codex can load, and count how often each was used.

Read-only. Prints JSON to stdout. Usage counts come from session logs, so they cover only
what the logs still hold. Run: python3 skill_usage.py [--days N] > usage.json
"""
import json, os, re, sys, glob
from collections import defaultdict
from concurrent.futures import ProcessPoolExecutor

HOME = os.path.expanduser("~")
CLAUDE_LOGS = [f"{HOME}/.claude/projects", f"{HOME}/.claude-work/projects"]
CODEX_LOGS = f"{HOME}/.codex/sessions"
SKILL_RE = re.compile(r"skills/([A-Za-z0-9_.-]+)/SKILL\.md")
SEARCH_RE = re.compile(r"\b(rg|grep|find|fd|ls|glob)\b")
CMD_RE = re.compile(r"<command-name>/([A-Za-z0-9_.:-]+)</command-name>")


def frontmatter(path):
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return {}, 0
    desc = ""
    m = re.search(r"^description:\s*(.*?)(?=^\w[\w-]*:|^---)", text, re.S | re.M)
    if m:
        desc = " ".join(m.group(1).split()).strip("|>'\" ")
    return {"description": desc}, len(text.split())


def skill_entry(name, source, folder):
    real = os.path.realpath(folder)
    meta, words = frontmatter(os.path.join(real, "SKILL.md"))
    files = [f for f in glob.glob(os.path.join(real, "**", "*"), recursive=True)
             if os.path.isfile(f) and not f.endswith("SKILL.md") and "/." not in f[len(real):]]
    scripts = [os.path.relpath(f, real) for f in files
               if f.endswith((".py", ".sh", ".js", ".ts", ".mjs"))]
    return {"name": name, "source": source, "path": real,
            "linked_from": folder if os.path.islink(folder) else None,
            "description": meta.get("description", ""),
            "description_words": len(meta.get("description", "").split()),
            "skill_md_words": words, "extra_files": len(files), "scripts": scripts[:20],
            "script_count": len(scripts)}


def inventory():
    skills, seen, broken = [], set(), []
    for source, root in [("claude", f"{HOME}/.claude/skills"),
                         ("shared", f"{HOME}/.agents/skills"),
                         ("codex", f"{HOME}/.codex/skills")]:
        for folder in sorted(glob.glob(f"{root}/*")):  # "*" so dead links show up too
            if not (os.path.isdir(folder) or os.path.islink(folder)):
                continue
            if not os.path.exists(os.path.join(folder, "SKILL.md")):
                if os.path.islink(folder) or os.path.islink(os.path.join(folder, "SKILL.md")):
                    broken.append({"name": os.path.basename(folder), "source": source, "path": folder,
                                   "points_to": os.path.realpath(os.path.join(folder, "SKILL.md"))})
                continue
            real = os.path.realpath(folder)
            name = os.path.basename(folder)
            if real in seen:  # same skill reached through a link: note it, count once
                for s in skills:
                    if s["path"] == real:
                        s.setdefault("also_in", []).append(source)
                continue
            seen.add(real)
            skills.append(skill_entry(name, source, folder))
    # plugin skills: only plugins switched on in settings.json
    try:
        enabled = {k for k, v in json.load(open(f"{HOME}/.claude/settings.json"))
                   .get("enabledPlugins", {}).items() if v}
        installed = json.load(open(f"{HOME}/.claude/plugins/installed_plugins.json")).get("plugins", {})
    except (OSError, ValueError):
        enabled, installed = set(), {}
    for plugin, installs in installed.items():
        if plugin not in enabled or not installs:
            continue
        base = installs[-1].get("installPath", "")
        short = plugin.split("@")[0]
        for folder in sorted(glob.glob(f"{base}/skills/*/")):
            folder = folder.rstrip("/")
            if os.path.exists(os.path.join(folder, "SKILL.md")):
                e = skill_entry(f"{short}:{os.path.basename(folder)}", f"plugin {plugin}", folder)
                skills.append(e)
    return skills, broken


def scan_claude(path):
    """Return {(skill, day): set(ids)} for one Claude Code log file."""
    hits, events = defaultdict(set), []
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                if '"name":"Skill"' not in line and "<command-name>/" not in line:
                    continue
                try:
                    d = json.loads(line)
                except ValueError:
                    continue
                ts = d.get("timestamp") or ""
                msg = d.get("message") or {}
                content = msg.get("content")
                if d.get("type") == "assistant" and isinstance(content, list):
                    for c in content:
                        if isinstance(c, dict) and c.get("type") == "tool_use" and c.get("name") == "Skill":
                            sk = (c.get("input") or {}).get("skill", "")
                            if sk:
                                events.append((sk, ts, "tool", c.get("id") or d.get("uuid")))
                elif d.get("type") == "user":
                    text = content if isinstance(content, str) else json.dumps(content)
                    for sk in CMD_RE.findall(text):
                        events.append((sk, ts, "cmd", "cmd:" + (d.get("uuid") or "")))
    except OSError:
        pass
    # A typed /skill can also show up as a Skill tool call moments later: count that once.
    events.sort(key=lambda e: e[1])
    last_cmd = {}
    for sk, ts, kind, uid in events:
        if kind == "cmd":
            last_cmd[sk] = ts
        elif sk in last_cmd and seconds_between(last_cmd.pop(sk), ts) <= 120:
            continue
        hits[(sk, ts[:10])].add(uid)
    return hits


def seconds_between(a, b):
    from datetime import datetime
    try:
        f = lambda t: datetime.fromisoformat(t.replace("Z", "+00:00"))
        return abs((f(b) - f(a)).total_seconds())
    except ValueError:
        return 1e9


def scan_codex(path):
    hits = defaultdict(set)
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                if "SKILL.md" not in line or '"response_item"' not in line:
                    continue
                try:
                    d = json.loads(line)
                except ValueError:
                    continue
                p = d.get("payload") or {}
                if p.get("type") not in ("function_call", "custom_tool_call", "local_shell_call"):
                    continue
                args = json.dumps(p.get("arguments") or p.get("input") or p.get("action") or "")
                if SEARCH_RE.search(args):  # a search that names SKILL.md is not a use
                    continue
                day = (d.get("timestamp") or "")[:10]
                for sk in set(SKILL_RE.findall(args)):
                    hits[(sk, day)].add(p.get("call_id") or p.get("id") or line[:80])
    except OSError:
        pass
    return hits


def merge(results):
    total = defaultdict(set)
    for r in results:
        for k, v in r.items():
            total[k] |= v
    by_skill = defaultdict(lambda: defaultdict(int))
    for (sk, day), ids in total.items():
        by_skill[sk][day] += len(ids)
    return by_skill


def main():
    claude_files = [f for root in CLAUDE_LOGS for f in glob.glob(f"{root}/**/*.jsonl", recursive=True)]
    codex_files = glob.glob(f"{CODEX_LOGS}/**/*.jsonl", recursive=True)
    with ProcessPoolExecutor() as ex:
        claude = merge(ex.map(scan_claude, claude_files, chunksize=20))
        codex = merge(ex.map(scan_codex, codex_files, chunksize=20))
    skills, broken = inventory()
    names = {s["name"] for s in skills}
    plain = {s["name"] for s in skills if not s["source"].startswith("plugin")}
    for s in skills:
        short = s["name"].split(":")[-1]
        is_plugin = s["source"].startswith("plugin")
        # a plugin skill's bare name counts only when no skill of the user's own shares it
        keys = {s["name"]} | ({short} if is_plugin and short not in plain else set())
        days = defaultdict(int)
        for k in keys:
            for d, n in claude.get(k, {}).items():
                days[d] += n
        cdays = codex.get(short, {}) if (not is_plugin or short not in plain) else {}
        s["claude_uses"] = sum(days.values())
        s["codex_uses"] = sum(cdays.values())
        alldays = sorted(set(days) | set(cdays))
        s["first_used"] = alldays[0] if alldays else None
        s["last_used"] = alldays[-1] if alldays else None
        s["uses_by_day"] = {d: days.get(d, 0) + cdays.get(d, 0) for d in alldays}
    unknown = sorted(k for k in claude if k not in names and k.split(":")[-1] not in names)
    out = {"skills": skills, "broken_links": broken,
           "log_files": {"claude": len(claude_files), "codex": len(codex_files)},
           "other_commands_seen": unknown[:80]}
    json.dump(out, sys.stdout, indent=1)


if __name__ == "__main__":
    main()
