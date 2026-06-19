#!/usr/bin/env python3
"""memory_compile — regenerate compiled views from the curated fact store.

Pipeline: parse facts -> lint -> (abort on unresolved conflicts) -> regenerate
CLAUDE.generated.md (global tier:user) + per-project MEMORY.md (only for projects
that have adopted a memory/facts/ subdir) -> write compile-manifest.json.

Truth = facts/*.md. Views = generated. Never hand-edit a generated file.
"""
import sys, os, re, json, hashlib, glob, datetime, pathlib

HOME = pathlib.Path.home()
MEM = HOME / ".claude/memory"
GLOBAL_FACTS = MEM / "facts"
PROJ = HOME / ".claude/projects"
GEN = MEM / "CLAUDE.generated.md"
MANIFEST = MEM / "compile-manifest.json"
MAX_LINES = 120
REQUIRED = ["id", "tier", "type", "status"]

def parse_frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.S)
    if not m: return None, text
    fm, body = {}, m.group(2)
    cur_list = None
    for line in m.group(1).splitlines():
        if re.match(r"^\s+-\s", line) or (cur_list and line.startswith("    ")):
            fm.setdefault(cur_list, []).append(line.strip())
            continue
        km = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if km:
            k, v = km.group(1), km.group(2).strip()
            if v == "":
                cur_list = k; fm.setdefault(k, [])
            else:
                cur_list = None; fm[k] = v
    return fm, body

def load(path):
    fm, body = parse_frontmatter(pathlib.Path(path).read_text(encoding="utf-8"))
    if fm is None: return None
    fm["_path"] = str(path); fm["_body"] = body.strip()
    return fm

def load_dir(d):
    out = []
    for p in sorted(glob.glob(str(d / "*.md"))):
        if pathlib.Path(p).name in ("MEMORY.md", "SCHEMA.md"): continue
        f = load(p)
        if f: out.append(f)
    return out

# ---- gather ----
global_facts = load_dir(GLOBAL_FACTS)
# project facts: only memory/facts/ subdirs (adopted convention)
project_facts = {}
for fd in glob.glob(str(PROJ / "*/memory/facts")):
    slug = pathlib.Path(fd).parts[-3]
    project_facts[slug] = load_dir(pathlib.Path(fd))

# ---- LINT (Part E) ----
errors, warnings = [], []
def subj_key(f):  # crude subject signature for conflict heuristic
    return (f.get("type"), re.sub(r"[^a-z ]", "", f.get("name","").lower()))

all_active = [f for f in global_facts if f.get("status") == "active"]
# schema drift
for f in global_facts + [x for v in project_facts.values() for x in v]:
    miss = [k for k in REQUIRED if k not in f]
    if miss: warnings.append(f"schema-drift: {pathlib.Path(f['_path']).name} missing {miss}")
# needs-review = unresolved conflict -> abort
for f in global_facts:
    if f.get("status") == "needs-review":
        errors.append(f"needs-review (unconfirmed conflict): {f['id']} — confirm supersede or drop before compile")
# direct-conflict heuristic: two active facts, same type, near-identical name, different id
seen = {}
for f in all_active:
    k = subj_key(f)
    if k in seen and seen[k]["id"] != f["id"]:
        warnings.append(f"possible-duplicate: {seen[k]['id']} ~ {f['id']} (same type+name)")
    seen[k] = f
# orphan/stale: project fact referencing a path that no longer exists
for slug, facts in project_facts.items():
    for f in facts:
        for mref in re.findall(r"`(/[^`]+)`", f.get("_body","")):
            if mref.startswith("/Users/") and not os.path.exists(mref):
                warnings.append(f"stale-path: {f['id']} references missing {mref}")

LINT_ONLY = "--lint" in sys.argv
print("LINT:")
for w in warnings: print(f"  WARN  {w}")
for e in errors: print(f"  ERROR {e}")
if not warnings and not errors: print("  clean")
if errors:
    print("\nABORT: unresolved conflicts — resolve before compiling.")
    sys.exit(2)
if LINT_ONLY: sys.exit(0)

# ---- COMPILE global view ----
TYPE_ORDER = ["user", "feedback", "pattern", "reference", "project"]
TYPE_HDR = {"user":"Identity & Hard Preferences","feedback":"Working Preferences",
            "pattern":"Patterns","reference":"Reference","project":"Project"}
groups = {}
for f in all_active:
    if f.get("tier") != "user": continue
    groups.setdefault(f.get("type","feedback"), []).append(f)

lines = ["<!-- GENERATED FROM ~/.claude/memory/facts/ — DO NOT EDIT. Run /memory-compile. -->",
         f"<!-- compiled {datetime.date.today().isoformat()} -->",
         "# Learned Preferences (compiled from curated memory)",
         "",
         "Compiled from the fact store. Each line links its source fact.",
         ""]
for t in TYPE_ORDER:
    if t not in groups: continue
    lines.append(f"## {TYPE_HDR.get(t,t)}")
    for f in sorted(groups[t], key=lambda x: x["id"]):
        rel = "memory/facts/" + pathlib.Path(f["_path"]).name
        lines.append(f"- **{f.get('name', f['id'])}** — {f.get('description','').strip()} ([{f['id']}]({rel}))")
    lines.append("")
if len(lines) > MAX_LINES:
    lines = lines[:MAX_LINES] + [f"- … ({len(all_active)} active facts total; view truncated — see memory/facts/)"]

if "--dry-run" in sys.argv:
    print("\n--- CLAUDE.generated.md (dry-run) ---")
    print("\n".join(lines))
else:
    GEN.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"\nWROTE {GEN}  ({len(lines)} lines)")

# ---- per-project views (dormant unless facts/ adopted) ----
for slug, facts in project_facts.items():
    active = [f for f in facts if f.get("status") == "active"]
    if not active: continue
    mp = PROJ / slug / "memory" / "MEMORY.md"
    pl = ["<!-- GENERATED FROM memory/facts/ — DO NOT EDIT. Run /memory-compile. -->",
          f"# {slug} — memory index", ""]
    for f in sorted(active, key=lambda x: x["id"]):
        pl.append(f"- **{f.get('name',f['id'])}** — {f.get('description','')} (facts/{pathlib.Path(f['_path']).name})")
    if "--dry-run" not in sys.argv:
        mp.write_text("\n".join(pl) + "\n", encoding="utf-8")
        print(f"WROTE {mp}")

# ---- manifest ----
def sha(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()[:12]
manifest = {"compiled": datetime.datetime.now().isoformat(timespec="seconds"),
            "global_facts": {f["id"]: sha(f["_path"]) for f in global_facts},
            "active_count": len(all_active),
            "warnings": warnings}
if "--dry-run" not in sys.argv:
    MANIFEST.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"WROTE {MANIFEST}")
