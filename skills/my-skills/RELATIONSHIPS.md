# Skill Relationships — what each skill calls + what that does

| Skill | Calls / Invokes | What that does | When to use | How to use | Why to use |
|---|---|---|---|---|---|
| code-health | **fallow**, ponytail-review, ponytail-audit, ponytail-debt, improve | Phase 0: diff review → Phase 1: static analysis → Phase 2: YAGNI → Phase 3: optimization | Before cleanup, after sprint | `/code-health` | Orchestrates all 4 tools in sequence so you don't have to run them manually |
| code-review | ponytail-review, **gh api**, CODE_REVIEW.md | 3-pass diff review: correctness → over-engineering → Karpathy filters | Before merging | `/code-review` | Runs ponytail-review automatically — catches deletions, not just additions |
| forge | grill-me, tdd, ui-ux, code-review, code-health, *impeccable*, **Playwright**, **graphify**, Opus+Sonnet agents | 7-phase feature pipeline with hard gates | Starting a new feature | `/forge [feature]` | Chains every quality gate automatically — you can't skip TDD or proof |
| ui-wild | ui-ux, code-review, *impeccable*, 10 Opus designers + judge + Sonnet builders | radical redesign with anti-slop judge | UI needs real redesign | `/ui-wild` | ui-ux feeds real design constraints to all 10 designers — not random generation |
| graphify | **graphify** CLI (Python), general-purpose subagents, **Whisper** | corpus → knowledge graph + query/path/explain | Exploring unfamiliar code | `/graphify` | Subagents query the graph in parallel — faster than sequential file reads |
| drawio-skill | **draw.io** CLI, **Graphviz**, 9 Python scripts (autolayout / import-extractors / shapesearch / repair) | diagram generation + export (PNG/SVG/PDF) | Documenting architecture | `/drawio-skill [describe it]` | Python scripts handle autolayout — you don't hand-place nodes |
| video-to-kb | /watch, **Groq Whisper** (groq_quota.py) | video → Obsidian KB ingest (raw → wiki) | Good talk to preserve | `/video-to-kb [URL]` | Whisper is cheap and fast — a 1hr talk transcribes in ~2 min |
| tdd | test command, diagnose (on confusing RED) | vertical-slice red-green-refactor | Bug fixes, new features | `/tdd [what to build]` | Escalates to diagnose automatically when RED is confusing — no manual pivot |
| diagnose | — | 6-phase root-cause debugging | Stuck on a bug | `/diagnose [describe it]` | Systematic evidence chain — stops the guess-and-check spiral |
| grill-me | AskUserQuestion | one-at-a-time planning interview | Fuzzy requirements | `/grill-me [plan]` | Structured questioning forces edge cases before any code |
| ui-ux | search.py / core.py / design_system.py (Python), *shadcn MCP* | design intelligence library (161 palettes, 99 UX rules) | Pre-code design decisions | `/ui-ux [design problem]` | Python scripts query a real design corpus — not LLM guessing |
| improve | Explore + general-purpose agents | read-only audit → plan files (never implements) | Pre-cleanup audit | `/improve` | Explore agents parallelize the codebase survey |
| ponytail | — (leaf) | lazy-mode enforcer (YAGNI → stdlib → native → one-liner) | About to over-engineer | `/ponytail [describe it]` | Leaf — no deps, always available |
| ponytail-audit | — (leaf) | whole-repo over-engineering hunt | Major cleanup | `/ponytail-audit` | Leaf — no deps, always available |
| ponytail-debt | — (leaf) | harvest `ponytail:` comments into debt ledger | Tracking shortcuts | `/ponytail-debt` | Leaf — no deps, always available |
| ponytail-review | — (leaf) | diff review: what to delete | PR too big | `/ponytail-review` | Leaf — no deps, always available |
| ponytail-help | — (leaf) | quick-reference card for the ponytail pack | Forgot a command | `/ponytail-help` | Leaf — no deps, always available |
| my-skills | — | this inventory + relationship tool | Forgot what skills exist | `/my-skills` | Single command to map everything |
| my-md | — (leaf) | list global ~/.claude/ docs + project MD files | New to project | `/my-md` | Leaf — no deps, always available |
| quick-design | Sonnet agents ×3, **Chrome** (headless screenshot) | token extract → 3 parallel mockups → pop in browser → approval gate | Any UI change | `/quick-design [describe it]` | 3 agents run in parallel — all 3 variants ready at once |
| whats-next | — (leaf, read-only) | scans brainstorms/ + git status → in-flight list OR clean-slate menu | Session start | `/whats-next` | Leaf — no deps, always available |

