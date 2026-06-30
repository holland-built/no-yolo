## Design

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| design | Fresh UI generation: 7 Opus mockups → slop gate → plan → build. Never patches. | Starting a new design or full redesign — want truly fresh, not an incremental patch | 7 distinct paradigms at once + slop validator kills the generic — one pick becomes a full build plan |
| design-audit | Read-only design audit → ranked violations + top-10 fixes. | Any UI that feels off — get a ranked list of what's wrong before changing anything | Five independent lenses + real-world references catch what one reviewer misses — read-only, zero risk |
| impeccable | Full-app polish loop: audit 5 lenses → fix Critical/High → verify. Repeats until clean. | App works but looks rough — need systematic visual polish across the whole codebase | Loop catches regressions after each fix. Manual polish misses cross-file consistency |

## Build & Plan

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| build | Full feature pipeline: plan → UI → code → tests → proof. | Starting any non-trivial feature from scratch | Nothing ships without a plan, tests, and proof. No more "works on my machine" done claims |
| plan | Interview yourself about a plan before writing code. | Fuzzy requirements, multiple valid approaches | First-attempt success jumps from ~70% to ~90% when decisions are front-loaded |
| tdd | Failing test first, then make it pass. Red→green discipline. | Bug fixes, new features, anywhere tests matter | The RED test is proof you actually fixed it. Without it you're asserting, not proving |

## Research

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| last-30 | Trending now (last 30 days) from GitHub, HN, YouTube, X. | Starting research on a topic and want signal from the past month, not all-time rankings | GitHub stars and HN posts from 3 years ago are noise. Last 30 days is actual traction |
| video-to-kb | Turn a YouTube video into a searchable KB note. | Good talk or tutorial worth keeping permanently | Talks are perishable. One command turns them into permanent, searchable KB nodes |
| ingest-docs | Convert PDFs/PPTX/DOCX/images in docs/raw/ → searchable .md context files. | Got new reference docs, specs, or training materials to feed into a project's context | Raw PDFs are invisible to Claude. Converts once, tracks changes, no re-ingestion overhead |

## Quality

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| code-review | Review a diff before merging. Catches bugs and bloat. | Before merging any non-trivial change | Catches what you're blind to after writing it. Karpathy filter hunts code that shouldn't exist |
| code-health | Audit for dead code, over-engineering, and waste. | Before a big refactor or after a long sprint | Finds real waste fast — most codebases have 20-30% deletable code |
| diagnose | Root-cause analysis: solo 6-phase or --debate for 6 Opus personas. | Stuck on a bug > 20 min — solo for systematic, --debate when multiple plausible theories | Solo: forces systematic evidence-gathering. --debate: six theories surface the one you missed |
| antislop | Check text/UI for AI-slop tells. Violations table + verdict. | Before shipping any user-facing text or README — or when output feels generic | AI writing has 25 known tell patterns. This catches them before they reach users |

## Prompts & AI

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| eli5 | Explain anything in plain English before you commit to it. | Before running anything you are not 100% sure about | Stops you from agreeing to something you did not actually understand |
| debate | 6 product-team personas argue your decision → YES/NO/CONDITIONAL. | Before committing to an architecture, UI/UX direction, or what-to-build-next call. When you want the whole team — dev, ops, and sales — stress-testing it, not validating it. | Because no single role sees the whole picture. Six product-team lenses — code, ops, and revenue — surface the contradictions and the one question you haven't asked yet. |
| better-prompt | Sharpen a rough prompt with target + scope + criterion. | When a prompt keeps returning shallow or off-target results | A prompt with a named target + scope + success criterion returns 3x better results |
| prompt-scan | Scan prompt files + model release notes → learnings.md. | After a new Claude model ships, or first-time setup before using /better-prompt | Without a learnings snapshot, /better-prompt rewrites blindly. This gives it real context |

## Memory & Docs

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| remember-that | Save, extract, delete, move, audit facts across sessions. | End of a session with useful decisions or preferences worth keeping | Preferences decay between sessions. This makes them permanent without manual file editing |
| md-check | Audit ~/.claude docs for bloat, overlap, duplicate rules. | Before adding a new doc, or when ~/.claude notes feel bloated and repetitive | Duplicate rules in two files = the wrong one gets followed. Overlap detection prevents this |
| my-md | List all markdown files — global docs + project artifacts. | New to a project or after a long break | One command to see everything. Prevents losing work to forgotten files |
| drawio-skill | Generate diagrams — flowcharts, architecture, sequence. | Explaining a system or documenting a design | Diagrams that take an hour in Miro take 2 minutes |

## Meta

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| my-skills | This menu. | Forgot what skills exist | You forget you have tools. This is the map |
| whats-next | Shows unfinished work or next-action list. Never static. | Session start — orient before picking what to do | Prevents starting something new while something is already half-done |
| skill-audit | Audit ~/.claude/skills across 4 dimensions; build verifiers, surface gotcha gaps. | Periodically, or when a skill misbehaves — find structural gaps in your skill library | Finds bucket-fit, verifier, and trigger gaps you can't see one skill at a time |
| update | Check, preview, apply, rollback, or restore setup updates. | Before pulling changes to your ~/.claude setup. Also after an update that broke something, or when you want to recover a skill that was removed. | Because pulling blindly can remove things you rely on. See first, then decide. |
| ship | Quality-gate + changelog + publish to no-yolo. One command. | Done editing skills and ready to publish to no-yolo | Leak guard + quality gates run automatically. One command replaces 5 manual steps |
| supacode-cli | Control Supacode worktrees, tabs, and surfaces from the terminal. | Inside a Supacode session and need to manage worktrees or surfaces programmatically | CLI is faster than UI for batch operations on tabs and worktrees |

## Plugins

| Pack | What it does | Entry point | Why vs manual |
| --- | --- | --- | --- |
| trim | Simplicity enforcer — forces laziest solution, audits over-engineering, tracks debt. 7 sub-skills. | /trim-help | Abstracting too early is universal. This actively resists it. |
