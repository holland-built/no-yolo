code-health|Audit your codebase for dead code, over-engineering, and waste. Good before a big cleanup.
code-review|Review a PR or diff before merging. Catches bugs, bloat, and things to delete.
diagnose|Stuck on a bug? Walks through root-cause analysis step by step until cause is found.
drawio-skill|Generate diagrams — architecture, flowcharts, ER, UML, sequence. Outputs PNG/SVG/PDF.
forge|Build a feature end-to-end: requirements → plan → UI mockup → code → tests → proof it works.
graphify|Ask questions about a codebase. "What calls X?" "What depends on Y?" Uses a knowledge graph.
grill-me|Interview yourself about a plan before writing any code. Forces edge cases and decisions up front.
my-skills|This menu.
tdd|Write a failing test first, then make it pass. Enforces red→green→refactor discipline.
ui-ux|Design help before touching code: color palettes, font pairings, UX guidelines, chart types.
ui-wild|Radical redesign: 10 AI designers compete, a judge kills the generic ones, you pick a winner.
video-to-kb|Turn a YouTube video into a note in your Obsidian knowledge base.
improve|Read-only codebase survey → outputs a prioritized list of improvement plans for you to action.
ponytail|Simplicity enforcer. Forces the laziest solution that works. Deletes abstraction, extra deps, and ceremony.
ponytail-audit|Scan the whole repo for over-engineered code — ranked list of what to simplify or delete.
ponytail-debt|Harvest all shortcuts tagged with "ponytail:" comments into one debt ledger.
ponytail-review|Review a diff and find what to delete, not what to add.
ponytail-help|Quick reference card for all ponytail commands.
my-md|List all markdown files — your global Claude docs and current project artifacts (brainstorms, changelogs).
quick-design|Fast 3-variant mockup generator. Extracts real design tokens, spawns conservative/modern/wild variants in parallel, pops in Chrome. Pick before any code is written.
whats-next|Scans for in-flight work (brainstorms, git, changelog). Shows what's unfinished — or a pick-list of next actions if the slate is clean. Never pushes audit over active work.
impeccable|Editorial-poster design theme — warm cream and burnt orange aesthetic. Use when you want a premium, graphic magazine feel for your UI.
eli5|Explain anything in plain English before you commit to it.
debate|Your product team argues the decision. Six domain personas — Senior Dev, Junior Dev, Sales Engineer, DevOps, Sales Leader, Eng Leader — surface the contradictions, then synthesize and grade their own briefing. Works on architecture, UI/UX, or what to build next. Ends with one clear YES/NO/CONDITIONAL decision, not "it depends."
update|Check if your setup is out of date, preview what changed in plain English, apply full or rules-only updates, rollback, or restore a removed skill.
ship|Quality-gate, changelog, and publish to no-yolo in one command. Warns on slop and bloat, blocks personal-data leaks, then pushes.
plan-feature|Plan a feature before writing any code. Evidence → grill-me interview → Opus plan → approval gate. Produces a handoff file for /build-feature.
build-feature|Build from an approved plan. Reads the handoff file from /plan-feature and runs mockup gate → TDD → build → regression → prove. Won't run without an approved plan.
debug-debate|6 Opus personas argue the root cause of your bug in parallel. Contradiction map, most likely cause with file:line, one concrete next diagnostic step.
last-30|Pull what's actually trending right now — last 30 days only — from GitHub, HN, YouTube, and X. Research starting point, not a final answer.
md-check|Audit your ~/.claude docs for bloat and overlap. Flags files over 200 lines, finds two files saying the same thing, blocks new file creation if a match exists.
antislop|Check any text or UI output for AI-slop tells — filler openers, em-dash spam, gradient heroes, card grids. Violations table + CLEAN/SLOP-DETECTED verdict.
prompt-scan|Scan your system prompt files and current model release notes, write a dated snapshot to learnings.md. Feeds /better_prompt.
better-prompt|Sharpen a rough prompt. Reads learnings.md, diagnoses missing target/scope/criterion, rewrites with all three and the right skill route. Requires /prompt-scan first.
