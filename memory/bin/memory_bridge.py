#!/usr/bin/env python3
"""memory_bridge — auto-promote high-confidence ECC instincts into the curated fact store.

Reads global-scope instincts via the ECC instinct-cli (export --scope global
--min-confidence THRESHOLD) and materializes each as a tier:user curated fact.

Conflict guard (anti-drift): if a candidate conflicts with an existing ACTIVE fact
(same type + near-identical subject), it is written with status: needs-review and a
`conflicts-with` note instead of overwriting. Non-conflicting candidates land active.

Idempotent: a fact already derived from an instinct id (and unchanged) is skipped.
Default dry-run; pass --apply to write. Threshold via --min-confidence (default 0.8).
"""
import sys, os, re, glob, subprocess, pathlib, datetime

HOME = pathlib.Path.home()
FACTS = HOME / ".claude/memory/facts"
CLI = HOME / ".claude/plugins/marketplaces/ecc/skills/continuous-learning-v2/scripts/instinct-cli.py"
APPLY = "--apply" in sys.argv
TODAY = datetime.date.today().isoformat()
def argval(flag, default):
    return sys.argv[sys.argv.index(flag)+1] if flag in sys.argv else default
MIN_CONF = float(argval("--min-confidence", "0.8"))

def slug(s):
    return re.sub(r"-+", "-", re.sub(r"[^a-z0-9]+", "-", s.lower())).strip("-")[:48]

def parse_export(text):
    blocks, cur, body, in_fm = [], None, [], False
    for line in text.splitlines():
        if line.startswith("#"):  # export header comments
            continue
        if line == "---":
            if cur is None:
                cur, body, in_fm = {}, [], True
            elif in_fm:
                in_fm = False
            else:  # closing of a block's body via next '---'
                cur["content"] = "\n".join(body).strip(); blocks.append(cur)
                cur, body, in_fm = {}, [], True
            continue
        if cur is not None and in_fm:
            km = re.match(r"^([a-z_]+):\s*(.*)$", line)
            if km: cur[km.group(1)] = km.group(2).strip().strip('"')
        elif cur is not None:
            body.append(line)
    if cur is not None:
        cur["content"] = "\n".join(body).strip(); blocks.append(cur)
    return [b for b in blocks if b.get("id")]

def existing_facts():
    out = []
    for p in glob.glob(str(FACTS / "*.md")):
        t = pathlib.Path(p).read_text(encoding="utf-8")
        fm = dict(re.findall(r"^([a-z-]+):\s*(.+)$", t.split('---')[1], re.M)) if '---' in t else {}
        fm["_name"] = (re.search(r"^name:\s*(.+)$", t, re.M) or [None, ""])[1] if "name:" in t else ""
        fm["_path"] = p; out.append(fm)
    return out

def conflicts(cand_name, cand_type, existing):
    key = re.sub(r"[^a-z ]", "", cand_name.lower())
    for f in existing:
        if f.get("type") == cand_type and f.get("status") == "active":
            ek = re.sub(r"[^a-z ]", "", f.get("name","").lower())
            if ek and (ek in key or key in ek): return f
    return None

# ---- get instincts ----
if not CLI.exists():
    # ECC marketplace uninstalled — auto-capture promotion is optional, not a
    # pipeline failure. Curated facts still compile; reinstall ecc to resume.
    print(f"promote skipped — instinct-cli not installed ({CLI})"); sys.exit(0)
res = subprocess.run([sys.executable, str(CLI), "export", "--scope", "global",
                      "--min-confidence", str(MIN_CONF)],
                     capture_output=True, text=True)
out = res.stdout
if "No instincts" in out or not out.strip():
    print(f"No global instincts at confidence >= {MIN_CONF} yet — nothing to promote. "
          f"(Observer is running; instincts accrue over analysis cycles.)")
    sys.exit(0)

instincts = parse_export(out)
existing = existing_facts()
print(f"{'APPLY' if APPLY else 'DRY-RUN'} — {len(instincts)} candidate instinct(s) >= {MIN_CONF}")
FACTS.mkdir(parents=True, exist_ok=True)

for ins in instincts:
    iid = ins["id"]; conf = ins.get("confidence", "0.8")
    domain = ins.get("domain", "workflow"); trigger = ins.get("trigger", iid)
    fid = "auto-" + slug(f"{domain}-{iid}")
    name = f"[auto] {trigger}"[:80]
    desc = (ins.get("content","").splitlines() or [trigger])[0][:200]
    fpath = FACTS / f"{fid}.md"
    # idempotency: skip if already materialized
    if fpath.exists():
        print(f"  SKIP (exists): {fid}"); continue
    conflict = conflicts(name, "pattern", existing)
    status = "needs-review" if conflict else "active"
    note = f"\nconflicts-with: {pathlib.Path(conflict['_path']).stem}" if conflict else ""
    fm = (f"---\nid: {fid}\ntier: user\ntype: pattern\nname: {name}\n"
          f"description: {desc}\nstatus: {status}\ncaptured: {TODAY}\nupdated: {TODAY}\n"
          f"confidence: {conf}\nprovenance:\n  - source: ecc-instinct\n    instinct_id: {iid}\n"
          f"    date: {TODAY}\nsupersedes: []\nsuperseded-by: null{note}\n---\n\n"
          f"{ins.get('content','').strip()}\n\n*Auto-promoted from ECC instinct `{iid}` "
          f"(domain: {domain}, confidence {conf}).*\n")
    tag = "NEEDS-REVIEW (conflict)" if conflict else "promote->active"
    print(f"  {tag}: {fid}" + (f"  (vs {pathlib.Path(conflict['_path']).stem})" if conflict else ""))
    if APPLY: fpath.write_text(fm, encoding="utf-8")

print("Done." + ("" if APPLY else "  (dry-run — re-run with --apply)"))
