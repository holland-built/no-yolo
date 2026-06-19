# no-yolo

This is my personal setup for Claude Code, saved as files you can copy. It includes the rules Claude reads at the start of every session, a set of custom commands ("skills"), helper agents, automation scripts, and a memory system that remembers my preferences. Fork it and you get a working setup right away.

---

## What this is

Claude Code is a command-line tool where you talk to Claude to write and edit code. It reads a folder called `~/.claude/` every time it starts. This repo *is* that folder, saved in git. Here's what's inside:

- The whole `~/.claude/` folder, tracked in git — everything Claude Code reads on every session
- A set of rules Claude reads at the start of every session (`CLAUDE.md` plus a few topic files). These enforce strict habits that make Claude actually useful: think and plan before writing code, only change the exact lines you asked for, and use the expensive model to plan while a cheaper model does the typing
- 16 custom commands, plus 7 more borrowed from plugins (run `/my-skills` to see the real, up-to-date count)
- Definitions for helper agents, custom slash commands, and automation scripts
- A memory system that learns your preferences over time. The easy way: just say "remember that I prefer X" and Claude saves it for you automatically. The power-user way: edit small note files in `memory/facts/` and run `/memory-compile` — useful when you want your preferences committed to git so they sync to all your machines

---

## Prerequisites

Things you need installed before this setup works. The command after each one checks whether you already have it:

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) itself: `claude --version`. Claude Code is a command-line tool for talking to Claude to write and edit code. You can find it at [claude.ai/code](https://claude.ai/code) or install it from the docs.
- The GitHub command-line tool, signed in: `gh auth status`
- Node.js available in your terminal (the automation scripts need it): `node --version`
- (Note: `~` in all paths below means your home directory — `/Users/yourname` on Mac)
- uv (Python tool runner — needed for graphify): check with `uv --version`, install at https://docs.astral.sh/uv/
- git

---

## Install on a new machine

### Option A — Make this repo your ~/.claude folder directly (best for a fresh machine)

```bash
mv ~/.claude ~/.claude.bak 2>/dev/null || true
gh repo clone holland-built/no-yolo ~/.claude
```

### Option B — Clone it somewhere else and just read it for reference

```bash
gh repo clone holland-built/no-yolo ~/claude-config
```

### After cloning

Two modes. Pick one:

```bash
bash ~/.claude/setup.sh           # full install — tools, CLI plugins, skill symlinks
bash ~/.claude/setup.sh --md-only # rules only — no tools needed, skill triggers stripped from CLAUDE.md
```

**Full install** steps through tools (fallow, graphify, gh, Graphviz) and plugin skills (ponytail, improve), then tells you which two plugins to add inside Claude Code.

**MD-only** skips all tool installs. It runs a Python script that reads your current `CLAUDE.md` and dynamically removes every skill trigger block and the memory import — so the rules work out of the box with no dead-end references. Dynamic means it stays correct if you add or remove skills later.

Full install details:

```bash
# 1. Copy the settings template, then edit your copy
cp ~/.claude/settings.example.json ~/.claude/settings.json
# In settings.json: fix the node path and add your own MCP servers

# 2. Make the automation scripts runnable
chmod +x ~/.claude/hooks/*.sh

# 3. Install fallow — scans your code for dead code, duplicates, and security issues.
#    Used by /code-health. Skip if you don't plan to use that command.
npm install -g fallow

# 4. Install graphify — maps your whole codebase into a searchable graph.
#    Instead of Claude reading every file on every question, it reads the graph once.
#    Saves money and time on large projects. Skip if your projects are small.
uv tool install graphify

# 5. Install the borrowed plugin commands — simplicity checker and improvement planner.
#    ponytail: flags code that's more complicated than it needs to be
#    improve: surveys your whole codebase and writes a prioritized cleanup list
npx skills@latest add DietrichGebert/ponytail
npx skills@latest add shadcn/improve

```

**Step 6 — plugin skills** (these commands run *inside Claude Code*, not in the terminal):

| Plugin | What it adds | Command to install |
|---|---|---|
| Impeccable | Magazine-style design theme (optional) | `/plugin marketplace add impeccable` |
| Caveman | Makes Claude reply in fewer words (optional) | `/plugin marketplace add JuliusBrussee/caveman` |

**After installing, verify it worked:** open Claude Code and run `/my-skills` — you should see a table of commands. If the table appears, the setup is complete.

### Outside tools you may need

Some commands call other programs on your computer. Install whichever ones you plan to use:

| Tool | Why you'd want it | Used by | Install |
|---|---|---|---|
| [gh (GitHub CLI)](https://cli.github.com/) | Lets Claude push code, open pull requests, and read GitHub issues on your behalf | `code-review` | `brew install gh && gh auth login` |
| [Graphviz](https://graphviz.org/) | Draws the actual diagram files that `drawio-skill` creates | `drawio-skill` | `brew install graphviz` |
| [draw.io](https://www.drawio.com/) CLI | Opens and exports the diagrams drawio-skill makes | `drawio-skill` | `brew install --cask drawio` |
| [Groq Whisper](https://console.groq.com/) | Turns speech into text — needed to transcribe YouTube videos or voice notes | `video-to-kb`, `graphify` | Get a free API key at console.groq.com, then set `GROQ_API_KEY` in your shell |
| [Chrome](https://www.google.com/chrome/) (headless) | Lets Claude take screenshots of mockups and web pages without you opening a browser | `quick-design`, `forge` | Already on most machines; or `brew install --cask google-chrome` |
| [Playwright](https://playwright.dev/) | Lets Claude actually click around in a browser to test your web app | `forge` | Add the `playwright` MCP server to `settings.json` — see MCP note below |
| shadcn MCP | Lets Claude look up shadcn component docs and add components to your project | `ui-ux` | Add the `shadcn` MCP server to `settings.json` |

> **What's an MCP server?** MCP (Model Context Protocol) is a standard for giving Claude extra tools — like the ability to control a browser or search a codebase. You connect one by adding a config block to `settings.json`. See the [Claude MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp) for how.

### Environment variables

These are secret keys and paths you save in your shell profile (`~/.zshrc` or `~/.bash_profile`) so the tools can find them:

| Variable | Used by | Notes |
|---|---|---|
| `GROQ_API_KEY` | `video-to-kb`, `graphify` | For Groq Whisper, which turns audio into text — get a key at [console.groq.com](https://console.groq.com/) |
| `OBSIDIAN_VAULT` | `video-to-kb` | Where your Obsidian vault lives — Obsidian is a local notes app (obsidian.md). video-to-kb files research notes here so you can ask Claude about them later. Defaults to `~/Documents/Obsidian` if you don't set it |

```bash
export GROQ_API_KEY=your_key_here
export OBSIDIAN_VAULT="$HOME/path/to/your/vault"
```

> ⚠️ **Security note:** `settings.json` lets Claude run `Bash(security find-generic-password *)` and `Bash(sshpass *)` without asking you first. The first one can read any password saved in the macOS Keychain; the second can type SSH passwords for you. Before using this setup on a machine you share with others, tighten these patterns so they only match the specific things you intend.

---

## Directory layout

What each file and folder is for:

| Path | Purpose |
|---|---|
| `CLAUDE.md` | The main rules file Claude reads first. It only holds pointers — it loads memory and sends Claude to the right topic file |
| `CORE_RULES.md` | The 5 core working rules — pulled in by CLAUDE.md |
| `PLANNING.md` | Rules for how to plan work |
| `TESTING.md` | Rules for how to test |
| `SUBAGENTS.md` | How and when to hand work off to helper agents |
| `CONTEXT.md` | Rules for keeping Claude's working memory clean |
| `SKILLS.md` | Rules for using skills and plugins |
| `CODE_REVIEW.md` | Rules for reviewing code |
| `UI_MOCKUPS.md` | Rules for designing screens before building them |
| `SKILL_RECOMMENDATIONS.md` | A wishlist of new commands to maybe add (just notes, not turned on) |
| `memory/` | Where your saved preferences live — `facts/` is the real source, `CLAUDE.generated.md` is the compiled result. See `MEMORY.md` |
| `skills/` | 16 commands plus 7 shortcuts to borrowed ones — see the list below |
| `agents/` | Definitions for helper agents |
| `commands/` | Custom slash commands |
| `hooks/` | Automation scripts: caveman mode (terse replies), a session-reflect step, and the status line. See `HOOKS.md` |
| `settings.example.json` | A starter settings file with no secrets — copy it to `settings.json` and fill in your own |

---

## Skills inventory

A "skill" is a custom command you trigger with a slash, like `/code-review`. Here's everything available.

### Commands in this setup

| Skill | What it does |
|---|---|
| `code-health` | A 4-step checkup of your code: review the changes, run static analysis, look for over-complication, then suggest a cleanup plan |
| `code-review` | Reviews a pull request or a set of changes: first for bugs, then for over-complication, then for unrelated edits that shouldn't be there |
| `diagnose` | A 6-step way to find the real cause of a bug — when you're stuck, it walks you through it step by step |
| `drawio-skill` | Draws diagrams (architecture, flowcharts, database tables, UML). Saves them as PNG, SVG, or PDF |
| `forge` | Builds a whole feature start to finish: gather requirements, plan it, mock up the screens, write tests first, build it, then prove it works |
| `graphify` | Builds a knowledge graph of your codebase once, then answers questions like "what calls this function?" from the graph instead of re-reading every file — saves tokens on large codebases and gives faster, more complete answers |
| `grill-me` | Interviews you before any code gets written — one question at a time until every tricky case is sorted out |
| `my-md` | Lists every markdown file — both the global `~/.claude/` docs and the ones in your current project |
| `my-skills` | This very list. Shows the commands I wrote and the borrowed ones, plus how they connect and what they depend on |
| `quick-design` | Makes 3 quick screen mockups using your project's real colors and fonts — a safe one, a modern one, and a bold one — and opens them in Chrome |
| `tdd` | Keeps you honest about test-driven development: write a failing test, make it pass, clean up, repeat |
| `ui-ux` | Design know-how: 161 color palettes, 57 font pairings, 99 design guidelines, 25 chart types |
| `ui-wild` | A bold redesign: 10 designer "personalities" compete, a judge throws out the generic ones, and you pick the winner |
| `video-to-kb` | Transcribes a YouTube video (or any video file) using Groq Whisper, then saves the transcript and a structured summary into your Obsidian notes folder — useful for researching topics from YouTube before asking Claude to help you apply what you learned |
| `whats-next` | Looks at what you've got in progress (notes, git changes) and either shows unfinished work or a menu of things to start |
| `eli5` | Explains any command, plan, file, or decision in plain English before you commit to it |

### Borrowed commands

These come from other people's plugins. One install command gets you all 5 ponytail commands.

| Skill | What it does | Install |
|---|---|---|
| `ponytail` + 4 sub-commands | Push for the simplest thing that works, scan for over-complication, gather TODO notes, review changes for deletions, quick reference card — one install gets all five | `npx skills@latest add DietrichGebert/ponytail` |
| `improve` | Surveys a codebase and writes a ranked improvement plan — never changes anything itself | `npx skills@latest add shadcn/improve` |
| `impeccable` | A magazine-style design look — warm cream and burnt orange — for building screens | `/plugin marketplace add impeccable` (run inside Claude Code) |

---

## The CLAUDE.md instruction chain

`CLAUDE.md` is the first file Claude reads, and by its own rule it holds *only* pointers — nothing else. All it contains is references to other files and the trigger words for each command.

- `@CORE_RULES.md` — the 5 core rules (plan first; keep it simple; only touch what you were asked to; aim at a clear goal; use the expensive model to plan and the cheaper one to type)
- `@memory/CLAUDE.generated.md` — your compiled preferences from `memory/facts/`
- It sends Claude to the right file by topic: Planning → `PLANNING.md`, Testing → `TESTING.md`, screens → `UI_MOCKUPS.md`, and so on
- Command triggers — each command gets its own `# name` block with the plain-English phrases that turn it on

Never put real content straight into `CLAUDE.md` — always put it in the right topic file and point to it.

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

## Set up a new project

After cloning this repo, do this in each new project folder you work in:

```bash
# Create the folders Claude looks for
mkdir -p brainstorms   # where plans and research notes get saved
```

Then copy your settings template once:
```bash
cp ~/.claude/settings.example.json ~/.claude/settings.json
```

Open `settings.json` and make two changes:
1. Fix the Node.js path — replace the path in `"command"` lines with the output of `which node`
2. Add any MCP servers you want (see below)

**Adding an MCP server** (this is how you give Claude extra abilities):

Find the `"mcpServers"` section in `settings.json` (or add it if missing) and add a block like this:

```json
"mcpServers": {
  "playwright": {
    "command": "npx",
    "args": ["-y", "@playwright/mcp@latest"]
  }
}
```

Each MCP server is a tool Claude gets access to. The [Claude MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp) have a list of available ones. Common ones:
- `playwright` — control a real browser (test your web app, take screenshots)
- `shadcn` — look up and add UI components
- `github` — read and write GitHub issues and pull requests

You don't need any MCP servers to start. Add them when a skill asks for one.

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

3. Add a trigger block to `CLAUDE.md`:

```markdown
# <name>
- **<name>** (`~/.claude/skills/<name>/SKILL.md`) - one-line description. Trigger: `/<name>`
When the user types `/<name>`, invoke the Skill tool with `skill: "<name>"` before doing anything else.
```

4. If your command calls other commands or outside tools, note it in `skills/my-skills/RELATIONSHIPS.md`.

5. Commit it, then pull it down on your other machines.

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
3. Commit both files:
   ```bash
   git add memory/facts/ memory/CLAUDE.generated.md
   git commit -m "remember: I prefer pnpm"
   git push
   ```
4. Pull on your other machines — your preferences are now everywhere

Never hand-edit `memory/CLAUDE.generated.md` directly — it gets overwritten every time you compile.

---

## What's excluded

Some things are deliberately left out of this repo, and why:

| Excluded | Reason |
|---|---|
| `settings.json` | Specific to your machine — has your Node.js path and any MCP servers you added. Use `settings.example.json` as a starting point, then copy and edit it (step 1 of "Full install details" above). Never commit this file — it may contain API keys |
| `plugins/` | Third-party marketplaces; each lives in its own repo |
| Plugin shortcuts (`ponytail*/`, `improve`, `impeccable`, etc.) | Symlinks (shortcuts) pointing to `~/.agents/skills/` where plugins install to. Clone them via the install commands above — they won't be in the repo itself |
| `cache/`, `sessions/`, `history.jsonl`, logs | Temporary runtime files — not part of the configuration |
