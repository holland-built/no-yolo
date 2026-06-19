# my-skills pre-baked stories
# Format: key|story text
# Sections 1+2 (your skills + plugin skills): key = skill dir name
# Section 3 (relationships):                 key = rel:skill-name
# Section 4 (bolt-ons):                      key = bolt:tool-name
# Edit this file to update a row. One pipe per line — story text must not contain |

# ── Section 1 — Your skills ──────────────────────────────────────────────────
eli5|Not sure what you're about to do? `/eli5 [skill name, plan, or command]` explains it in plain English — what it does, what actually runs, and anything that could bite you. Like having someone in the room saying "wait, do you actually understand this?"
code-health|Your project collects junk over time. This checks it and shows what's dead, bloated, or wasteful. Run `/code-health` before a big cleanup — most projects have 20-30% you can just delete.
code-review|Before you merge new code, this reads it and catches bugs and bloat you stopped seeing because you wrote it. Run `/code-review` on a diff or PR. Hunts code that shouldn't exist, not just typos.
diagnose|Stuck on a bug for 20+ minutes, poking randomly? `/diagnose [the bug]` walks it step by step until it finds the real cause. Stops the guess-and-check spiral.
drawio-skill|Need a picture of how something works? `/drawio-skill [describe it]` draws it — flowchart, architecture, sequence — and saves a PNG/SVG/PDF. An hour of fiddling becomes two minutes.
forge|Building a feature from scratch? `/forge [feature]` runs the whole pipeline — plan, design, code, tests, proof — with gates you can't skip. Nothing ships half-baked.
graphify|New to a codebase and scared to touch it? `/graphify` lets you ask in plain English "what uses this?" and "what breaks if I change it?" Answers in seconds instead of reading 40 files.
grill-me|Got a fuzzy plan? `/grill-me [plan]` interviews you one question at a time and forces the hard decisions out before you code. First try works far more often (~70% to ~90%).
my-md|Lost track of your notes? `/my-md` lists every markdown file — your global Claude docs plus this project's brainstorms and changelogs. One command, see everything.
my-skills|This menu. `/my-skills` lists every tool you have and what it's for, so you stop forgetting what you built.
quick-design|Changing how something looks? `/quick-design [the UI]` shows three real options — safe, modern, bold — before you write a line of CSS. Pick, then build.
tdd|`/tdd [what to build]` writes a failing test first, then makes it pass. The failing test is your proof you actually fixed it, not just think you did.
ui-ux|Planning a design without touching code? `/ui-ux [problem]` hands you real palettes, font pairs, and layout rules — 161 palettes to pick from, not guesswork.
ui-wild|Design looks generic and needs a real shake-up? `/ui-wild` runs 10 AI designers, a judge kills the boring ones, you pick the winner. Won't look like every other app.
video-to-kb|Watched a great talk worth keeping? `/video-to-kb [YouTube URL]` turns it into a permanent searchable note in your knowledge base. Talks don't get lost.
whats-next|Back after a break and don't know where you left off? `/whats-next` scans your work-in-progress and shows what's unfinished — or a clean menu if nothing's pending.

# ── Section 2 — Plugin skills ─────────────────────────────────────────────────
dispatching-parallel-agents|Got several unrelated jobs? `/dispatching-parallel-agents` runs them all at once instead of one by one, so you wait less.
executing-plans|Already wrote a plan? `/executing-plans` runs it with check-ins along the way, catching it early when reality drifts from the plan. Use in a fresh session.
full-output-enforcement|When the AI gets lazy and writes "..." instead of real code, `/full-output-enforcement` forces the whole thing. Those "..." quietly break files.
impeccable|Want a premium magazine look, not plain default web? `/impeccable` applies a warm cream and burnt-orange editorial style. Gives your UI a real identity.
improve|Want an honest audit before fixing anything? `/improve` surveys the project and hands you a ranked to-do list. Never touches code — pure advice, zero risk.
ponytail|About to overbuild something simple? `/ponytail [what you're building]` forces the laziest thing that actually works — strips out extra layers and ceremony.
ponytail-audit|`/ponytail-audit` scans the whole project for over-engineered code and ranks what to simplify. Finds the clever thing from 6 months ago nobody understands now.
ponytail-debt|Took shortcuts on purpose and tagged them? `/ponytail-debt` gathers them into one list so they don't become forgotten landmines.
ponytail-help|Forgot a ponytail command? `/ponytail-help` is the quick cheat-sheet.
ponytail-review|PR feels too big? `/ponytail-review` reads the diff and tells you what to cut — most tools suggest what to add, this one hunts what to remove.
receiving-code-review|Got review comments? `/receiving-code-review` makes you understand each one before applying it — because reviewer feedback is often wrong.
requesting-code-review|Finished something and want a formal gate before merging? `/requesting-code-review` runs a structured pass and catches what you convinced yourself was fine.
subagent-driven-development|Plan with lots of independent steps? `/subagent-driven-development` splits them across parallel workers — a 10-step job doesn't take 10x as long.
verification-before-completion|About to say "done"? `/verification-before-completion` actually runs the check and shows the output first. "I think it works" isn't proof.
writing-plans|Starting anything non-trivial? `/writing-plans [the task]` turns it into a clear step-by-step plan before you touch code, so the code has a real shape.

# ── Section 3 — Relationships (prefix rel:) ───────────────────────────────────
rel:code-health|Runs four tools in order for you — fallow, then the ponytail checks, then improve — so you don't run each by hand. One command, full cleanup pass.
rel:code-review|Pulls the real diff with gh, then runs ponytail-review on it — so it catches what you deleted, not just what you added.
rel:forge|The big one — calls grill-me, tdd, ui-ux, code-review, code-health, impeccable, and browser tests, with Opus planning and Sonnet building. Chains every quality gate so you can't skip steps.
rel:ui-wild|Feeds real design rules from ui-ux into 10 designers, with a judge to kill the generic ones. Constraints, not random guessing.
rel:graphify|Builds a map of your code, then sends helper agents to query it in parallel — faster than reading files one at a time.
rel:drawio-skill|Uses the draw.io tool plus Graphviz and Python scripts that auto-arrange the boxes, so you place nothing by hand.
rel:video-to-kb|Uses Groq Whisper to transcribe the video cheaply, then files it into your Obsidian notes. A one-hour talk is done in ~2 minutes.
rel:tdd|Runs your test command, and if a failing test is confusing it hands off to diagnose automatically — no manual switch.
rel:diagnose|Stands alone — no setup. Pure step-by-step root-cause debugging.
rel:grill-me|Uses the question-prompt tool to interview you one item at a time — no dependencies.
rel:ui-ux|Backed by Python scripts that search a real design library (161 palettes, 99 UX rules) plus the shadcn component set — not made-up advice.
rel:improve|Sends out explorer agents in parallel to survey the codebase, then writes plan files. Never edits code.
rel:ponytail|Stands alone — no setup. The simplicity enforcer, always available.
rel:ponytail-audit|Stands alone — no setup. Whole-repo over-engineering hunt.
rel:ponytail-debt|Stands alone — no setup. Collects your tagged shortcuts into one ledger.
rel:ponytail-review|Stands alone — no setup. Diff review for what to delete.
rel:ponytail-help|Stands alone — no setup. The ponytail cheat-sheet.
rel:my-skills|Stands alone — no setup. This inventory tool.
rel:my-md|Stands alone — no setup. Lists your markdown files.
rel:quick-design|Runs three designer agents at once and uses headless Chrome to screenshot each mockup, so all three are ready together.
rel:whats-next|Stands alone, read-only. Scans your in-progress work and git status.

# ── Section 4 — Bolt-ons (prefix bolt:) ──────────────────────────────────────
bolt:fallow|Finds code nobody uses — dead leftovers, dupes, junk. code-health runs it before cleanup. Install: `npm install -g fallow`. Free, fast, no AI.
bolt:graphify|Builds a map of your code so you can ask "what uses this?" without reading everything. Used by forge and graphify skill. Install: `uv tool install graphify`.
bolt:gh|GitHub's tool — pulls real PR diffs so code-review reads them without copy-paste. Install: `brew install gh && gh auth login`.
bolt:Chrome|Takes screenshots of mockups so you see them without opening a browser. Used by quick-design and forge. Usually already installed.
bolt:Playwright|Drives a browser to measure layouts and run smoke tests for forge. Add the playwright MCP plugin to settings.json. Gives real proof a layout is right.
bolt:Graphviz|The engine that auto-arranges diagram boxes for drawio-skill. Install: `brew install graphviz`. No hand-placing.
bolt:draw.io|Turns diagram instructions into actual pictures (PNG/SVG/PDF) for drawio-skill. Install: `brew install --cask drawio`.
bolt:Groq Whisper|Transcribes audio and video cheaply for video-to-kb. Set GROQ_API_KEY in your shell. Far cheaper than OpenAI.
bolt:shadcn MCP|A library of ready-made design components that ui-ux pulls from. Add the shadcn plugin to settings.json. Keeps design grounded in real parts.
bolt:impeccable|The editorial cream and burnt-orange theme, used by forge and ui-wild. Run `/impeccable`. Gives the UI a distinct look.
