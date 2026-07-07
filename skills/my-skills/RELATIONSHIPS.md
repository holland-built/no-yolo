# Skill Relationships — what each skill calls + what that does

| Skill | Calls / Invokes | What that does | When to use | How to use | Why to use |
|---|---|---|---|---|---|
| review | **fallow**, trim-review, trim, improve | diff review + full codebase health pass (fallow + trim + improve), one ranked list, one approve-all gate | Before merging, or a cleanup pass | `/review` | Replaces the old code-review/code-health split with one routed command |
| build | plan, tdd, review, **Playwright**, **graphify** (optional), Opus+Sonnet agents | 7-phase feature pipeline with hard gates | Starting a new feature | `/build [feature]` | Chains every quality gate automatically — you can't skip TDD or proof |
| design | vendored taste-skill, **emil-design-eng** (motion only), slop validator, Chrome (headless) | fresh generation: brand seed → 10 Opus mockups → validator → pick → Opus plan → Sonnet build | Starting a new design or full redesign | `/design [text/URL/screenshot]` | Never preserves the existing design — every mockup is clean-sheet |
| design-audit | Lazyweb MCP, shadcn/ui MCP, Taste/Swiss/UIwiki sub-skills, **review-animations** (motion only) | screenshot + 5 parallel lenses → violations table + top-10, light+dark | UI feels off, want a diagnosis | `/design-audit [surface]` | Five independent lenses catch what one reviewer misses — read-only, zero risk |
| emil-design-eng | — (leaf, plugin) | Vaul/Sonner-author UI-polish and animation-taste rules | Invoked automatically by design/design-audit when motion is in scope | auto-invoked | Right easing/timing/shadows — the details agents usually miss |
| animation-vocabulary | — (leaf, plugin) | reverse-lookup: vague motion description → exact term | Want the right word to prompt an AI or designer | auto-invoked or by name | Precise language gets a better result than a vague one |
| review-animations | — (leaf, plugin) | strict critique of animation/motion code | Invoked automatically by design-audit's Taste lens on motion surfaces | auto-invoked | Approval earned, not assumed |
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

