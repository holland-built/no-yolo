# Skill Relationships — what each skill calls + what that does

| Skill | Calls / Invokes | What that does | When to use | How to use | Why to use |
|---|---|---|---|---|---|
| code-health | **fallow**, trim-review, trim-audit, trim-debt, improve | Phase 0: diff review → Phase 1: static analysis → Phase 2: YAGNI → Phase 3: optimization | Before cleanup, after sprint | `/code-health` | Orchestrates all 4 tools in sequence so you don't have to run them manually |
| code-review | trim-review, **gh api**, CODE_REVIEW.md | 3-pass diff review: correctness → over-engineering → Karpathy filters | Before merging | `/code-review` | Runs trim-review automatically — catches deletions, not just additions |
| build | plan, tdd, code-review, code-health, **Playwright**, **graphify**, Opus+Sonnet agents | 7-phase feature pipeline with hard gates | Starting a new feature | `/build [feature]` | Chains every quality gate automatically — you can't skip TDD or proof |
| design-audit | Lazyweb MCP, shadcn/ui MCP, Taste/Swiss/UIwiki sub-skills, /code-health | screenshot + 5 parallel lenses → violations table + top-10, light+dark | UI feels off, want a diagnosis | `/design-audit [surface]` | Five independent lenses catch what one reviewer misses — read-only, zero risk |
| design-full | /design-audit, /debate, Lazyweb (lite --fast / deep full), shadcn/ui MCP, Sonnet agents ×7 (--fast) / Opus agents ×7 (full), /build | Always nukes tokens: detects stack → injects fresh palette → bans current colors. --fast: 7 variants pick gate; full: audit → debate → 7 Opus → plan → build | Any UI redesign — always starts completely fresh | `/design-full --fast [surface]` or `/design-full [surface]` | Nuke is always on — agents never default to your old colors |
| design-fix | Sonnet agents ×7, Chrome (headless) | 7 structural + wild variants for one component, light+dark each, locked tokens | One component feels wrong | `/design-fix [change]` | Respects current tokens — surgical, not nuclear |
| token-hunt | Lazyweb MCP, Chrome (headless), /design-full (--steal) | finds 5 reference sites matching design intent → extracts CSS tokens from each → user picks → outputs stolen-tokens.md | Want to base a redesign on a real site's look | `/token-hunt [site or intent]` | Steals real tokens instead of inventing a palette — feeds design-full --steal |
| graphify | **graphify** CLI (Python), general-purpose subagents, **Whisper** | corpus → knowledge graph + query/path/explain | Exploring unfamiliar code | `/graphify` | Subagents query the graph in parallel — faster than sequential file reads |
| drawio-skill | **draw.io** CLI, **Graphviz**, 9 Python scripts (autolayout / import-extractors / shapesearch / repair) | diagram generation + export (PNG/SVG/PDF) | Documenting architecture | `/drawio-skill [describe it]` | Python scripts handle autolayout — you don't hand-place nodes |
| video-to-kb | /watch, **Groq Whisper** (groq_quota.py) | video → Obsidian KB ingest (raw → wiki) | Good talk to preserve | `/video-to-kb [URL]` | Whisper is cheap and fast — a 1hr talk transcribes in ~2 min |
| tdd | test command, diagnose (on confusing RED) | vertical-slice red-green-refactor | Bug fixes, new features | `/tdd [what to build]` | Escalates to diagnose automatically when RED is confusing — no manual pivot |
| diagnose | Opus agents ×6 (--debate only) | Solo: 6-phase root-cause debugging; --debate: 6 Opus personas → contradiction map → diagnosis | Stuck on a bug, or multiple competing theories | `/diagnose [bug]` or `/diagnose --debate [bug]` | Solo stops guess-and-check; debate surfaces the theory you missed |
| plan | AskUserQuestion | one-at-a-time planning interview | Fuzzy requirements | `/plan [plan]` | Structured questioning forces edge cases before any code |
| improve | Explore + general-purpose agents | read-only audit → plan files (never implements) | Pre-cleanup audit | `/improve` | Explore agents parallelize the codebase survey |
| trim | — (leaf) | lazy-mode enforcer (YAGNI → stdlib → native → one-liner) | About to over-engineer | `/trim [describe it]` | Leaf — no deps, always available |
| trim-audit | — (leaf) | whole-repo over-engineering hunt | Major cleanup | `/trim-audit` | Leaf — no deps, always available |
| trim-debt | — (leaf) | harvest `trim:` comments into debt ledger | Tracking shortcuts | `/trim-debt` | Leaf — no deps, always available |
| trim-review | — (leaf) | diff review: what to delete | PR too big | `/trim-review` | Leaf — no deps, always available |
| trim-help | — (leaf) | quick-reference card for the trim pack | Forgot a command | `/trim-help` | Leaf — no deps, always available |
| my-skills | — | this inventory + relationship tool | Forgot what skills exist | `/my-skills` | Single command to map everything |
| my-md | — (leaf) | list global ~/.claude/ docs + project MD files | New to project | `/my-md` | Leaf — no deps, always available |
| whats-next | — (leaf, read-only) | scans brainstorms/ + git status → in-flight list OR clean-slate menu | Session start | `/whats-next` | Leaf — no deps, always available |

