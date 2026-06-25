# my-skills pre-baked stories
# Format: key|story text
# Sections 1+2 (your skills + plugin skills): key = skill dir name
# Section 3 (relationships):                 key = rel:skill-name
# Section 4 (bolt-ons):                      key = bolt:tool-name
# Edit this file to update a row. One pipe per line — story text must not contain |

# ── Section 1 — Your skills ──────────────────────────────────────────────────
eli5|Not sure what you're about to do? `/eli5 [skill name, plan, or command]` explains it in plain English — what it does, what actually runs, and anything that could bite you. Like having someone in the room saying "wait, do you actually understand this?"
debate|Not sure which option is actually better? `/debate [decision]` convenes your product team — Senior Dev, Junior Dev, Sales Engineer, DevOps, Sales Leader, Eng Leader — each pushing their real-world agenda. It maps where they contradict each other, synthesizes a briefing, then peer-reviews its own findings. Use it for architecture calls, UI/UX choices, or deciding what to build next when you want pushback, not a rubber stamp. It ends with one decisive line — YES, NO, or CONDITIONAL — with the single reason that settles it, so you never walk away with "it depends."
remember-that|Conversation produced a useful decision or preference? `/remember-that` saves it as a typed fact file so future sessions know about it. No-args scans the conversation and proposes what's worth keeping — you approve each one. Also deletes, moves, audits, and recompiles your full memory store.
ship|Done editing your skills and ready to publish? `/ship` runs three warn-only quality passes — flags oversized docs, AI-slop writing, and jargon in your README — writes a dated plain-English changelog entry, then hard-blocks any personal-data leak before committing and pushing to your no-yolo repo. One command from messy working tree to clean public push.
update|Not sure if you should update? `/update` checks if you're behind, shows what's new and what's being removed — before you pull anything. Then `/update full` or `/update rules` applies it. Broke something? `/update rollback` goes back. Miss a deleted skill? `/update restore <name>` brings it back.
code-health|Your project collects junk over time. This checks it and shows what's dead, bloated, or wasteful. Run `/code-health` before a big cleanup — most projects have 20-30% you can just delete.
code-review|Before you merge new code, this reads it and catches bugs and bloat you stopped seeing because you wrote it. Run `/code-review` on a diff or PR. Hunts code that shouldn't exist, not just typos.
diagnose|Stuck on a bug for 20+ minutes, poking randomly? `/diagnose [the bug]` walks it step by step until it finds the real cause. Add `--debate` and 6 Opus personas each argue a competing root-cause theory — you get a contradiction map, the most likely cause with file:line, and one concrete next step. Diagnosis only in both modes.
drawio-skill|Need a picture of how something works? `/drawio-skill [describe it]` draws it — flowchart, architecture, sequence — and saves a PNG/SVG/PDF. An hour of fiddling becomes two minutes.
build|Building a feature from scratch? `/build [feature]` runs the whole pipeline — evidence, Opus plan, approval gate, UI mockup gate, TDD, Sonnet build, regression loop, quality gates, prove. Every gate is hard. Nothing ships half-baked.
last-30|Want to know what's actually gaining traction right now, not what was popular last year? `/last-30 [topic]` pulls the last 30 days of signal from GitHub, Hacker News, YouTube, and X — trending repos, top discussions, recent talks. Filters out old results. Starting point for research, not a final answer.
md-check|Your ~/.claude notes piling up and starting to repeat each other? `/md-check` lists every doc with its size, flags anything over 200 lines, and spots two files saying the same thing so you can merge them. Other skills call it with --pre before creating a new note, so you never end up with two files on one topic.
antislop|Paste any text or UI output and get a table of AI-slop violations — forbidden words, filler openers, em-dash spam, GUI clichés — with excerpts and one-line fixes. CLEAN or SLOP-DETECTED verdict. Diagnosis only, nothing rewritten.
prompt-scan|System prompt files drift — new rules get added, old ones get stale, and /better_prompt needs a reference to work from. `/prompt-scan` reads every global Claude MD file plus the current model's release notes and writes a dated snapshot to learnings.md. Run it once on setup and again whenever a new Claude model ships.
better-prompt|Rough prompts get rough results. `/better_prompt "[your prompt]"` reads your learnings.md, checks if the prompt has a named target, a scope boundary, and a success criterion, then rewrites it with all three plus the right skill route. Shows before/after with rationale. Requires /prompt-scan to have run at least once.
better_prompt|Rough prompts get rough results. `/better_prompt "[your prompt]"` reads your learnings.md, checks if the prompt has a named target, a scope boundary, and a success criterion, then rewrites it with all three plus the right skill route. Shows before/after with rationale. Requires /prompt-scan to have run at least once.
plan|Got a fuzzy plan? `/plan [plan]` interviews you one question at a time and forces the hard decisions out before you code. First try works far more often (~70% to ~90%).
my-md|Lost track of your notes? `/my-md` lists every markdown file — your global Claude docs plus this project's brainstorms and changelogs. One command, see everything.
my-skills|This menu. `/my-skills` lists every tool you have and what it's for, so you stop forgetting what you built.
design-audit|UI feels off but you can't name why? `/design-audit [surface]` screenshots the running app, pulls real-world reference screens, then runs five lenses — taste, Swiss design, UI rules, accessibility, and code health on your CSS — and hands back a ranked table of what's wrong, worst first. Read-only, no gates, no code. Feed the output straight into /design-full.
design-full|Two speeds, one command. `/design-full --fast [surface]` fans out 7 mockups at once — 5 serious redesigns and 2 wild ones — kills the generic ones with a slop judge, opens them in Chrome, hard stop on a pick. No code. Ready to ship? `/design-full [surface]` runs the whole thing — audit, 6-persona debate, 7 Opus mockups, token extraction, Opus plan, chains to /build. Four hard gates, nothing built until you approve a mockup.
tdd|`/tdd [what to build]` writes a failing test first, then makes it pass. The failing test is your proof you actually fixed it, not just think you did.
video-to-kb|Watched a great talk worth keeping? `/video-to-kb [YouTube URL]` turns it into a permanent searchable note in your knowledge base. Talks don't get lost.
whats-next|Back after a break and don't know where you left off? `/whats-next` scans your work-in-progress and shows what's unfinished — or a clean menu if nothing's pending.

# ── Section 2 — Plugin skills ─────────────────────────────────────────────────
improve|Want an honest audit before fixing anything? `/improve` surveys the project and hands you a ranked to-do list. Never touches code — pure advice, zero risk.
trim|About to overbuild something simple? `/trim [what you're building]` forces the laziest thing that actually works — strips out extra layers and ceremony.
trim-audit|`/trim-audit` scans the whole project for over-engineered code and ranks what to simplify. Finds the clever thing from 6 months ago nobody understands now.
trim-debt|Took shortcuts on purpose and tagged them? `/trim-debt` gathers them into one list so they don't become forgotten landmines.
trim-help|Forgot a trim command? `/trim-help` is the quick cheat-sheet.
trim-review|PR feels too big? `/trim-review` reads the diff and tells you what to cut — most tools suggest what to add, this one hunts what to remove.

# ── Section 3 — Relationships (prefix rel:) ───────────────────────────────────
rel:code-health|Runs four tools in order for you — fallow, then the trim checks, then improve — so you don't run each by hand. One command, full cleanup pass.
rel:code-review|Pulls the real diff with gh, then runs trim-review on it — so it catches what you deleted, not just what you added.
rel:build|Full pipeline inline — evidence → plan → Opus plan → approval gate → mockup gate → TDD → Sonnet build → regression → quality gates → prove. Every gate is hard. Opus plans, Sonnet builds, no shortcuts.
rel:diagnose|Solo mode: stands alone — pure step-by-step root-cause debugging. --debate mode: reads the codebase itself before spawning 6 parallel Opus personas. No setup needed beyond a bug description.
rel:last-30|Uses WebSearch and the exa MCP plugin to hit 4 sources in parallel. Requires exa plugin in settings.json for best results.
rel:md-check|Stands alone — pure shell + Read. No setup. Other skills can call it with --pre flag as a pre-creation gate.
rel:ship|Reads ANTISLOP.md for the slop pass, reads DAILY_CHANGELOG.md to append (creates it if missing). Calls same git guards as the old publish-skills. No subagents.
rel:antislop|Reads ANTISLOP.md (writing tells + GUI slop). No subagents, no web calls — pure in-context pattern match.
rel:prompt-scan|Reads 8 system MD files sequentially + WebFetch to Anthropic docs for release notes. Appends to learnings.md without overwriting prior entries — entries compound over time.
rel:better_prompt|Reads learnings.md then rewrite prompt inline. No subagents, no web calls — pure in-context reasoning against the learned rules.
rel:design-audit|Read-only. Calls Lazyweb + Interface Design MCPs for references, runs Taste/Swiss/UIwiki sub-skills (or embedded fallbacks), plus /code-health on CSS. No code, no gates.
rel:design-full|--fast: 7 parallel Sonnet agents + slop judge + headless Chrome + optional Design+Refine MCP. Full: chains /design-audit → /debate → 7 Opus agents → slop judge → token extraction → Opus plan → /build Phase 4. Four hard gates. Uses Lazyweb, Interface Design, and Design+Refine when present.
rel:drawio-skill|Uses the draw.io tool plus Graphviz and Python scripts that auto-arrange the boxes, so you place nothing by hand.
rel:video-to-kb|Uses Groq Whisper to transcribe the video cheaply, then files it into your Obsidian notes. A one-hour talk is done in ~2 minutes.
rel:tdd|Runs your test command, and if a failing test is confusing it hands off to diagnose automatically — no manual switch.
rel:plan|Uses the question-prompt tool to interview you one item at a time — no dependencies.
rel:improve|Sends out explorer agents in parallel to survey the codebase, then writes plan files. Never edits code.
rel:trim|Stands alone — no setup. The simplicity enforcer, always available.
rel:trim-audit|Stands alone — no setup. Whole-repo over-engineering hunt.
rel:trim-debt|Stands alone — no setup. Collects your tagged shortcuts into one ledger.
rel:trim-review|Stands alone — no setup. Diff review for what to delete.
rel:trim-help|Stands alone — no setup. The trim cheat-sheet.
rel:my-skills|Stands alone — no setup. This inventory tool.
rel:my-md|Stands alone — no setup. Lists your markdown files.
rel:whats-next|Stands alone, read-only. Scans your in-progress work and git status.

# ── Section 4 — Bolt-ons (prefix bolt:) ──────────────────────────────────────
bolt:fallow|Finds code nobody uses — dead leftovers, dupes, junk. code-health runs it before cleanup. Install: `npm install -g fallow`. Free, fast, no AI.
bolt:gh|GitHub's tool — pulls real PR diffs so code-review reads them without copy-paste. Install: `brew install gh && gh auth login`.
bolt:Chrome|Takes screenshots of mockups so you see them without opening a browser. Used by design-full (both modes) and build. Usually already installed.
bolt:Playwright|Drives a browser to measure layouts and run smoke tests for build. Add the playwright MCP plugin to settings.json. Gives real proof a layout is right.
bolt:Graphviz|The engine that auto-arranges diagram boxes for drawio-skill. Install: `brew install graphviz`. No hand-placing.
bolt:draw.io|Turns diagram instructions into actual pictures (PNG/SVG/PDF) for drawio-skill. Install: `brew install --cask drawio`.
bolt:Groq Whisper|Transcribes audio and video cheaply for video-to-kb. Set GROQ_API_KEY in your shell. Far cheaper than OpenAI.
skill-audit|Wondering if your skills are well-structured or missing pieces? `/skill-audit` scans your whole library in one pass — buckets every skill into utility/verification/data enrichment/orchestration, flags missing scripts and config files, finds skills that produce output but never check it, and confirms every trigger description is actually a trigger. Writes a full report to brainstorms/. Also builds new verifiers and surfaces gotcha gaps on demand.
