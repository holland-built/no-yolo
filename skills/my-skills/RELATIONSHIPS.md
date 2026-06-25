# Skill Relationships — what each skill calls + what that does

| Skill | Calls / Invokes | What that does | When to use | How to use | Why to use |
|---|---|---|---|---|---|
| code-health | **fallow**, trim-review, trim-audit, trim-debt, improve | Phase 0: diff review → Phase 1: static analysis → Phase 2: YAGNI → Phase 3: optimization | Before cleanup, after sprint | `/code-health` | Orchestrates all 4 tools in sequence so you don't have to run them manually |
| code-review | trim-review, **gh api**, CODE_REVIEW.md | 3-pass diff review: correctness → over-engineering → Karpathy filters | Before merging | `/code-review` | Runs trim-review automatically — catches deletions, not just additions |
| build | plan, tdd, ui-ux, code-review, code-health, **Playwright**, **graphify**, Opus+Sonnet agents | 7-phase feature pipeline with hard gates | Starting a new feature | `/build [feature]` | Chains every quality gate automatically — you can't skip TDD or proof |
| design-audit | Lazyweb MCP, Interface Design MCP, Taste/Swiss/UIwiki sub-skills, /code-health | screenshot + 5 parallel lenses → violations table + top-10 | UI feels off, want a diagnosis | `/design-audit [surface]` | Five independent lenses catch what one reviewer misses — read-only, zero risk |
| design-fast | Lazyweb lite, Design+Refine MCP, Sonnet agents ×7, **Chrome** (headless) | token extract → 7 parallel mockups → slop judge → browser view | Want to see directions fast | `/design-fast [surface]` | 7 agents run in parallel — all variants ready at once, slop judge kills generic ones |
| design-full | /design-audit, /debate, Lazyweb deep, Interface Design MCP, Design+Refine MCP, Opus agents ×7, /build, Magic MCP | full pipeline: audit → direction → 7 Opus mockups → plan → build | Redesign you intend to ship | `/design-full [surface]` | Four hard gates — nothing builds until you approve a mockup |
| graphify | **graphify** CLI (Python), general-purpose subagents, **Whisper** | corpus → knowledge graph + query/path/explain | Exploring unfamiliar code | `/graphify` | Subagents query the graph in parallel — faster than sequential file reads |
| drawio-skill | **draw.io** CLI, **Graphviz**, 9 Python scripts (autolayout / import-extractors / shapesearch / repair) | diagram generation + export (PNG/SVG/PDF) | Documenting architecture | `/drawio-skill [describe it]` | Python scripts handle autolayout — you don't hand-place nodes |
| video-to-kb | /watch, **Groq Whisper** (groq_quota.py) | video → Obsidian KB ingest (raw → wiki) | Good talk to preserve | `/video-to-kb [URL]` | Whisper is cheap and fast — a 1hr talk transcribes in ~2 min |
| tdd | test command, diagnose (on confusing RED) | vertical-slice red-green-refactor | Bug fixes, new features | `/tdd [what to build]` | Escalates to diagnose automatically when RED is confusing — no manual pivot |
| diagnose | — | 6-phase root-cause debugging | Stuck on a bug | `/diagnose [describe it]` | Systematic evidence chain — stops the guess-and-check spiral |
| plan | AskUserQuestion | one-at-a-time planning interview | Fuzzy requirements | `/plan [plan]` | Structured questioning forces edge cases before any code |
| ui-ux | search.py / core.py / design_system.py (Python), *shadcn MCP* | design intelligence library (161 palettes, 99 UX rules) | Pre-code design decisions | `/ui-ux [design problem]` | Python scripts query a real design corpus — not LLM guessing |
| improve | Explore + general-purpose agents | read-only audit → plan files (never implements) | Pre-cleanup audit | `/improve` | Explore agents parallelize the codebase survey |
| trim | — (leaf) | lazy-mode enforcer (YAGNI → stdlib → native → one-liner) | About to over-engineer | `/trim [describe it]` | Leaf — no deps, always available |
| trim-audit | — (leaf) | whole-repo over-engineering hunt | Major cleanup | `/trim-audit` | Leaf — no deps, always available |
| trim-debt | — (leaf) | harvest `trim:` comments into debt ledger | Tracking shortcuts | `/trim-debt` | Leaf — no deps, always available |
| trim-review | — (leaf) | diff review: what to delete | PR too big | `/trim-review` | Leaf — no deps, always available |
| trim-help | — (leaf) | quick-reference card for the trim pack | Forgot a command | `/trim-help` | Leaf — no deps, always available |
| my-skills | — | this inventory + relationship tool | Forgot what skills exist | `/my-skills` | Single command to map everything |
| my-md | — (leaf) | list global ~/.claude/ docs + project MD files | New to project | `/my-md` | Leaf — no deps, always available |
| whats-next | — (leaf, read-only) | scans brainstorms/ + git status → in-flight list OR clean-slate menu | Session start | `/whats-next` | Leaf — no deps, always available |

