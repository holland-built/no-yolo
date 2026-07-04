# no-yolo

My personal Claude Code setup, saved in git. Fork it and you get a working setup in minutes — slash commands, strict coding habits, and a memory system that learns your preferences.

---

## What this is

Claude Code is a command-line tool where you talk to Claude to write and edit code. It reads a folder called `~/.claude/` every time it starts. This repo *is* that folder, saved in git. Here's what's inside:

- **Rules** Claude reads at the start of every session. Enforces strict habits: plan before coding, only touch the exact lines you asked for, use the right model for the right job.
- **30 custom commands**, plus 7 borrowed from plugins — type `/name` to run one, like `/review` or `/build`. Run `/my-skills` for the full list.
- **Memory** that learns your preferences. Say "remember that I prefer X" and Claude saves it automatically — carries forward to every future session.

---

## Prerequisites

| Tool | Required? | Check | Install |
|---|---|---|---|
| [Claude Code](https://claude.ai/code) | Required | `claude --version` | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |
| **git** | Required | `git --version` | Pre-installed on Mac; Linux: `sudo apt install git` |
| **Node.js** | Required | `node --version` | [nodejs.org](https://nodejs.org/) |
| **gh** (GitHub CLI) | Optional — needed for `/release` | `gh auth status` | `brew install gh && gh auth login` |

`~` in all paths means your home directory — Mac: `/Users/<username>`, Linux: `/home/<username>`.


---

## Install on a new machine

### Step 1 — Clone the repo

```bash
mv ~/.claude ~/.claude.bak 2>/dev/null || true
git clone https://github.com/holland-built/no-yolo.git ~/.claude
```

> The `mv` line backs up any existing `~/.claude` folder before overwriting it. If you don't have one, the `|| true` makes it skip silently.

**Just want to read it before committing?** Clone it somewhere else first:

```bash
git clone https://github.com/holland-built/no-yolo.git ~/claude-config
```

### Step 2 — Run setup.sh

`setup.sh` is an automated install script that sets up everything this repo needs. It is safe to re-run — it skips any step that is already done.

```bash
bash ~/.claude/setup.sh           # full install (recommended for most people)
bash ~/.claude/setup.sh --md-only # rules only — no tools installed
```

**What setup.sh does, step by step:**

| Step | What it does | Notes |
|------|-------------|-------|
| 1. settings.json | Copies `settings.example.json` → `settings.json`. Skips if you already have one. Prints a reminder to edit the Node.js path and add your MCP servers | Required — Claude Code won't load without it |
| 2. Hook permissions | Runs `chmod +x` on all `hooks/*.sh` so the automation scripts can execute | Required |
| 3. CLI tools | Checks for `fallow`, `gh`, and `Graphviz`. Installs fallow if missing; prints the install command for anything else it can't auto-install | Optional — only needed if you use those specific skills |
| 4. Plugin skills (terminal) | Installs `trim` and `improve` via `npx skills@latest add` | Optional — skip if you don't need those commands |
| 5. Plugin skills (Claude Code) | Lists already-installed Claude Code plugins, or prints the commands to run inside Claude Code to install the recommended ones | Informational only — you run these inside Claude Code, not here |
| 6. Environment variables | Prints the `export` lines to copy into your `~/.zshrc` or `~/.bash_profile` | Optional — only needed for `video-to-kb` |

**--md-only mode** does steps 1 and 2 only, then runs a Python script that strips every skill trigger block out of `CLAUDE.md`. Use this if you want the rules but not the full toolchain — Claude won't reference skills that aren't installed, so nothing breaks. The strip is dynamic: it reads the current file, so it stays correct even if you add or remove skills later.

**Started with --md-only and want tools later?** Just re-run: `bash ~/.claude/setup.sh` — it skips anything already installed.

### Step 3 — Two optional plugins inside Claude Code

After setup.sh finishes, open Claude Code and run these if you want them:

| Plugin | What it adds | Command (run inside Claude Code) |
|---|---|---|
| Caveman | Makes Claude reply in fewer words — saves tokens on long sessions | `/plugin marketplace add JuliusBrussee/caveman` |

### Step 4 — Verify

Open Claude Code in any folder and run:

```
/my-skills
```

You should see a table of commands. If the table appears, setup is complete.

### Outside tools some skills need

These are not installed by setup.sh. Install whichever ones match the skills you plan to use:

| Tool | Why you'd want it | Used by | How to install |
|---|---|---|---|
| [gh (GitHub CLI)](https://cli.github.com/) | Lets Claude push code, open pull requests, and read GitHub issues | `review`, `ship` | `brew install gh && gh auth login` |
| [Graphviz](https://graphviz.org/) | Draws diagram files | `drawio-skill` | `brew install graphviz` |
| [draw.io](https://www.drawio.com/) CLI | Opens and exports diagrams | `drawio-skill` | `brew install --cask drawio` |
| [Groq Whisper](https://console.groq.com/) | Transcribes a YouTube video and saves a structured wiki page into your Obsidian vault | `video-to-kb` | Get a free API key at console.groq.com, then add `export GROQ_API_KEY=your_key` to `~/.zshrc` |
| [Chrome](https://www.google.com/chrome/) (headless) | Takes screenshots of mockups without opening a browser window | `design`, `build` | Already on most machines; or `brew install --cask google-chrome` |
| [Playwright](https://playwright.dev/) | Lets Claude click around in a browser to test your web app | `build` | Add the `playwright` MCP server to `settings.json` — see MCP note below |
| [shadcn/ui MCP](https://ui.shadcn.com/docs/mcp) | Gives Claude full context on shadcn/ui components for design mockups | `design` | `pnpm dlx shadcn@latest mcp init --client claude` (or `npx shadcn@latest mcp init --client claude`) |
| [Lazyweb](https://github.com/aboul3ata/lazyweb-skill) | Real app screenshots + A/B test evidence — 12 design research skills | `design-audit`, `design` | `curl -fsSL https://www.lazyweb.com/install.sh \| bash` |

> **What's an MCP server?** MCP (Model Context Protocol) is a standard for giving Claude extra tools — like the ability to control a browser or search a codebase. You wire one up by adding a config block to `settings.json`. See the [Claude MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp) for how.

> ⚠️ **Security note:** The example `settings.json` allows broad bash commands (`curl`, `docker`, `kill`) and wildcarded filesystem MCP access. It also sets `skipDangerousModePermissionPrompt: false` — change this to `true` in your personal `settings.json` only if you want Claude to skip confirmation prompts. On a shared or sensitive machine, narrow the `Bash(...)` allow-patterns to what you actually need.

---

## Set up a new project

No per-project setup required — skills that need a `brainstorms/` folder create it automatically.

The one thing you may want to add: **MCP servers**. These give Claude extra abilities. Add them to the `"mcpServers"` section of `~/.claude/settings.json`:

```json
"mcpServers": {
  "playwright": {
    "command": "npx",
    "args": ["-y", "@playwright/mcp@latest"]
  }
}
```

Common one: `playwright` (browser control for `/build`). You don't need any to start — add when a skill asks for one. Full list in the [Claude MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp).

---

## Directory layout

What each file and folder is for:

| Path | Purpose |
|---|---|
| `CLAUDE.md` | The main rules file Claude reads first. It only holds pointers — loads memory and sends Claude to the right topic file |
| `docs/CORE_RULES.md` | The 5 core working rules — pulled in by CLAUDE.md |
| `docs/PLANNING.md` | Rules for how to plan work |
| `docs/TESTING.md` | Rules for how to test |
| `docs/SUBAGENTS.md` | How and when to hand work off to helper agents |
| `docs/CONTEXT.md` | Rules for keeping Claude's working memory clean |
| `docs/SKILLS.md` | Rules for using skills and plugins |
| `docs/CODE_REVIEW.md` | Rules for reviewing code |
| `docs/UI_MOCKUPS.md` | Rules for designing screens before building them |
| `docs/DAILY_CHANGELOG.md` | Public changelog — `/release` appends a dated entry here before pushing |
| `docs/NO_YOLO.md` | How to author a new skill — the checklist |
| `docs/MEMORY.md` | Docs for the memory system |
| `docs/SKILL_TRIGGERS.md` | Trigger rules for every skill — CLAUDE.md points here |
| `memory/` | Saved preferences — `facts/` is source of truth, `CLAUDE.generated.md` is compiled result |
| `skills/` | Your skills plus symlinks to borrowed ones |
| `hooks/` | Automation scripts: caveman mode, session-reflect, status line |
| `settings.example.json` | Starter settings with no secrets — `setup.sh` copies this to `settings.json` automatically |

---

## Skills inventory

A "skill" is a custom command you trigger with a slash, like `/review`. Here's everything available.

### Frontend design — audit and build

Two skills cover the full frontend design workflow. Design tokens (`DESIGN.md` / `design-system/MASTER.md` / CSS) are always read as **context, not constraint** — a redesign can propose replacing them entirely.

| Command | Depth | What it does | Gates |
|---|---|---|---|
| `/design-audit` | read-only | 5 lenses in parallel (taste, Swiss design, UI rules, accessibility, CSS health), then a second agent challenges every Critical finding before it sticks. Ranked violations table, worst first. Say "fix it" and it hands off to `/impeccable` | none |
| `/design` | mockups + full pipeline | Starts from a brand seed, fans out 7 Opus mockups each locked to a different paradigm, kills the generic ones with a slop validator, hard-stops on a pick. Then writes an Opus plan and Sonnet builds it. `--apply-spec [DESIGN.md]` swaps an existing app onto a spec's tokens instead | Nothing builds until you pick a mockup |

`/design-audit` findings can feed directly into a `/design` fix pass. Both skills always show light + dark mode.

### Commands in this setup

| Skill | What it does | Modes & flags |
|---|---|---|
| `/review` | One mode, always thorough: reviews the diff AND the whole codebase — correctness bugs, over-engineering, Karpathy surgical filter, fallow + trim + improve, secret scan and antislop on any `.md` changes. Max effort, every time. One ranked findings list, one approve-all, then fixes everything approved | `--auto` (skip the approval gate, unattended) |
| `/diagnose` | A 6-step way to find the real cause of a bug. Add `--debate` and 6 Opus personas each argue a competing root-cause theory — contradiction map, most likely cause with file:line, one concrete next step | `--debate` (6-persona Opus mode) |
| `/drawio-skill` | Draws diagrams (architecture, flowcharts, database tables, UML). Saves them as PNG, SVG, or PDF | — |
| `/build` | Builds a whole feature start to finish: gather evidence, plan with Opus, approve, then automatically runs a UI mockup gate (slop-filtered, requires approval) before writing any code — tests first, build with Sonnet, then prove it works | — |
| `/plan` | Interviews you before any code gets written — one question at a time until every tricky case is sorted out. On agreement, routes the sharpened result to `/build`, `/design`, or whichever skill fits | — |
| `/my-md` | Lists every markdown file — both the global `~/.claude/` docs and the ones in your current project | — |
| `/my-skills` | This very list. Default view is a dense 2-skill-per-row table with 2-5 word summaries — fits one screen | `deep` (full sentences + relationships + bolt-ons) |
| `/lockstep` | Told "don't code yet" and had it ignored a few messages later? This makes it physical — a `PreToolUse` hook blocks every Edit/Write/NotebookEdit outright until you say go | `on` / `off` |
| `/video-to-kb` | *(Optional — requires Obsidian + Groq API key)* Watch a YouTube video and get a structured wiki page injected into your Obsidian vault automatically — transcript, summary, key claims | — |
| `/whats-next` | Reads session task queue (`~/.claude/.pending-tasks.md`) and runs next task; creative project-specific suggestions when queue is empty | — |
| `/debate` | Your product team argues the decision — Senior Dev, Junior Dev, Sales Engineer, DevOps, Sales Leader, Eng Leader — then maps contradictions, synthesizes a briefing, and ends with one clear YES/NO/CONDITIONAL verdict | — |
| `/eli5` | Explains any command, plan, file, or decision in plain English before you commit to it | — |
| `/prompt-scan` | Reads all system prompt files plus current model release notes and appends a dated snapshot to `learnings.md`. Required before `/better_prompt`. A SessionStart hook offers to re-run it when the active model differs from the last scan | — |
| `/better_prompt` | Reads `learnings.md`, diagnoses a rough prompt for missing target/scope/criterion, rewrites it with all three plus the right skill route. Requires `/prompt-scan` to have run first | — |
| `/last-30` | Pulls the last 30 days of signal from GitHub, HN, YouTube, and X — trending repos, top discussions, recent talks. Filters out old results | — |
| `/md-check` | Lists every `~/.claude/` doc with its size, flags anything over 200 lines, and spots two files saying the same thing so you can merge them | `--pre FILENAME` (check before creating) · `--drift` (check description staleness) |
| `/md-fix` | Audits your docs then APPLIES the fixes md-check only reports — dedupe repeated rules, merge overlapping files, trim oversize, correct stale descriptions — behind one approve-all gate | `--auto` (skip the gate) |
| `/release` | The one context-aware publish command for any repo — reads the repo-root `SHIP.md` and pushes to the right environment (dev/staging/prod). No `SHIP.md`? It stops and helps you build one before anything ships | `[env]` `--auto` |
| `/skill-audit` | Audits your skill library across 4 dimensions: bucket fit, component gaps, missing verifiers, and trigger condition quality. Writes a full report. Also builds new verifiers and surfaces gotcha gaps on demand | `--audit` · `--build-verifier <skill>` · `--gotchas` |
| `/update` | Checks if your setup is out of date, shows a plain-English summary of what changed, and lets you apply updates, roll back, or restore a removed skill | `preview` · `full` · `rules` · `rollback` · `restore NAME` |
| `/ingest-docs` | Converts PDFs/decks/docs you drop in `docs/raw/` into dense context files Claude reads at runtime — dedupes against what's already there, tracks changes in a manifest | — |
| `/remember-that` | Saves a decision or preference from the conversation as a fact file so future sessions know about it. No-args scans the conversation and proposes what's worth keeping | — |

**Hidden from `/my-skills` but still real commands** — kept because each retains a use case its replacement doesn't cover:

| Skill | What it does | Why hidden |
|---|---|---|
| `/antislop` | Paste any text and get a violations table — forbidden words, filler openers, em-dash spam, GUI clichés. CLEAN or SLOP-DETECTED verdict. Diagnosis only | Auto-runs inside `/review` and `/release` — standalone still useful for arbitrary text outside a git diff |
| `/tdd` | Writes a failing test first, then makes it pass — one behavior at a time | `/build` step 4 runs the identical loop automatically — standalone still useful without the full `/build` pipeline |

`supacode-cli` isn't a typed command — it auto-activates only inside a Supacode terminal session, driving tabs/worktrees/surfaces via the `supacode` CLI.

### Borrowed commands

These come from other people's plugins. One install command gets you all 6 trim commands.

| Skill | What it does | Install |
|---|---|---|
| `/trim` + 5 sub-commands | Push for the simplest thing that works, scan for over-complication, gather TODO notes, review changes for deletions, quick reference card — one install gets all six | `npx skills@latest add holland-built/trim` |
| `/improve` | Surveys a codebase and writes a ranked improvement plan — never changes anything itself | `npx skills@latest add shadcn/improve` |

---

## Model guidance

There are three Claude models. They cost different amounts and are good at different things:

> **Haiku** — tests, small edits, simple mechanical tasks (cheapest)
>
> **Sonnet** — most coding, reviews, and builds (the everyday default)
>
> **Opus** — planning, big architecture decisions, hard analysis (most capable)

**The rule: let Opus do the planning and Sonnet do the building. Never plan on the fly without a plan first.**

---

## Keeping your setup up to date

Open Claude Code in any folder and run:

```
/update
```

That's it. No git knowledge needed. It checks if you're behind, shows what's new and what's being removed — before changing anything.

**What `/update` can do:**

| Command | What happens |
|---|---|
| `/update` | Check if you're behind — shows what's new, what's removed, options menu |
| `/update preview` | Full plain-English changelog, nothing changed yet |
| `/update full` | Pull everything + re-run setup (~30 seconds) |
| `/update rules` | Pull rules only — no tool installs |
| `/update rollback` | Undo the last update, go back to what you had |
| `/update restore <name>` | Bring back a skill that was removed in an update |

**How it works:** `/update` fetches the latest version from GitHub without changing anything, then shows you a plain-English summary: "You'd get 2 new skills, 1 rule changed, 1 skill removed." You decide what to do next.

**If you've customized your clone:** `/update full` is safe — it stashes local changes, applies the update, then restores them. Conflicts are shown explicitly; nothing is lost.

Changes take effect the next time you open Claude Code.

---

## Keeping your fork in sync

If you cloned this repo directly (not as a fork), `/update full` handles everything automatically.

If you **forked** this repo on GitHub, `/update full` handles that too — it detects a fork, adds an `upstream` remote to the original, and rebases your commits on top of the latest changes. Your customizations survive.

**After a successful rebase:** force-push to update your fork: `git push --force origin main`. `/update` will remind you.

---

## Add a new skill

How to add your own command:

1. Make the command's folder:

```bash
mkdir ~/.claude/skills/<name>
# Create ~/.claude/skills/<name>/SKILL.md with this info at the top:
# name, description, user-invocable: true
```

2. Add a one-line summary to `skills/my-skills/TAGLINES.md`:

```
<name>|One sentence — when to use it and what it does.
```

3. Add a trigger block to `docs/SKILL_TRIGGERS.md`:

```markdown
# <name>
- **<name>** (`~/.claude/skills/<name>/SKILL.md`) - one-line description. Trigger: `/<name>`
When the user types `/<name>`, invoke the Skill tool with `skill: "<name>"` before doing anything else.
```

4. Add a story (full description) to `skills/my-skills/STORIES.md`:

```
<name>|When would you reach for this? What does it actually do? What's the payoff?
```

5. Run `/release` to publish. It adds a changelog entry and pushes to git.

See `docs/NO_YOLO.md` for the full authoring checklist.

---

## Update memory preferences

**The easy way — just tell Claude:**

Say things like:
- "Remember that I always want bullet points, not paragraphs"
- "Remember that I use pnpm, not npm"
- "Forget what you saved about X"

Claude saves these automatically. No file editing needed. They stick for the rest of the session and get written to the memory system so they carry forward.

**The committed way — for preferences you want saved in git:**

This syncs preferences across all your machines via the repo.

1. Create or edit a file in `memory/facts/` — name it anything, like `memory/facts/my-preferences.md`
2. Run `/memory-compile` inside Claude Code — this rebuilds one combined file Claude reads on startup
3. Commit `memory/facts/` and `memory/CLAUDE.generated.md` and push
4. Pull on your other machines — preferences are now everywhere

Never hand-edit `memory/CLAUDE.generated.md` directly — it gets overwritten every time you compile.

---

## Caveman mode — shorter replies

Caveman mode makes Claude reply in very short sentences, dropping filler words. Useful when you're in a long session and want to save time and tokens.

**Turn it on** (type inside Claude Code):
```
/caveman lite    # slightly shorter
/caveman full    # terse — fragments OK, articles dropped
/caveman ultra   # bare minimum words
```

**Turn it off:**
```
stop caveman
```

The mode stays on until you turn it off, even across multiple messages. A small indicator in the status bar (bottom of the screen) shows whether it's active.

---

## The status bar (the line at the bottom of Claude Code)

Claude Code shows a status bar at the bottom of the screen. This setup adds extra info to it:

```
~  no-yolo  main  ●  42% ctx  2.1h/5h  18h/7d  [CAVEMAN:full]
```

Reading left to right:
- `~` — your home directory (this is where `~/.claude/` lives)
- `no-yolo` — the current project folder name
- `main` — the current git branch
- `●` — there are uncommitted changes (no dot = clean)
- `42% ctx` — how full Claude's working memory is. Above 60%, run `/compact` to trim it
- `2.1h/5h` — how much of your 5-hour usage limit you've used today
- `18h/7d` — how much of your 7-day usage limit you've used this week
- `[CAVEMAN:full]` — caveman mode is on at "full" level (only shows when active)

The status bar is driven by `hooks/statusline.sh`. It runs after every response. If something looks wrong, check that file.

---

## The CLAUDE.md instruction chain

`CLAUDE.md` is the first file Claude reads, and by its own rule it holds *only* pointers — nothing else. All it contains is references to other files and the trigger words for each command.

- `@docs/CORE_RULES.md` — the 5 core rules (plan first; keep it simple; only touch what you were asked to; aim at a clear goal; use the expensive model to plan and the cheaper one to type)
- `@memory/CLAUDE.generated.md` — your compiled preferences from `memory/facts/`
- It sends Claude to the right file by topic: Planning → `PLANNING.md`, Testing → `TESTING.md`, screens → `UI_MOCKUPS.md`, and so on
- Command triggers — each command gets its own `# name` block with the plain-English phrases that turn it on

Never put real content straight into `CLAUDE.md` — always put it in the right topic file and point to it.

---

## What's excluded

Some things are deliberately left out of this repo, and why:

| Excluded | Reason |
|---|---|
| `settings.json` | Specific to your machine — has your Node.js path and any MCP servers you added. Use `settings.example.json` as a starting point, then copy and edit it (setup.sh step 1). Never commit this file — it may contain API keys |
| `plugins/` | Third-party marketplaces; each lives in its own repo |
| Plugin shortcuts (`trim*/`, `improve`, etc.) | Symlinks (shortcuts) pointing to `~/.agents/skills/` where plugins install to. Clone them via the install commands above — they won't be in the repo itself |
| `.pending-tasks.md` | Session task queue used by `/whats-next` — local only, not shared |
| `learnings.md` | Written by `/prompt-scan` — accumulates model release notes + prompt diagnostics over time. Local only |
| `cache/`, `sessions/`, `history.jsonl`, logs | Temporary runtime files — not part of the configuration |

---

## Uninstall

To remove individual tools installed by setup.sh:

| What to remove | Command |
|---|---|
| fallow | `npm uninstall -g fallow` |
| trim | `npx skills@latest remove holland-built/trim` |
| improve | `npx skills@latest remove shadcn/improve` |
| Claude Code plugins | `/plugin remove <name>` inside Claude Code |

To remove the whole setup (your backup is at `~/.claude.bak` if you used the install command):

```bash
rm -rf ~/.claude
```
