# no-yolo

[![last commit](https://img.shields.io/github/last-commit/holland-built/no-yolo?style=flat-square&label=last%20commit)](https://github.com/holland-built/no-yolo/commits/main)
[![checks](https://img.shields.io/github/actions/workflow/status/holland-built/no-yolo/ci.yml?branch=main&style=flat-square&label=checks)](https://github.com/holland-built/no-yolo/actions)
[![release](https://img.shields.io/github/v/release/holland-built/no-yolo?style=flat-square&label=release)](https://github.com/holland-built/no-yolo/releases/latest)
[![commits](https://img.shields.io/github/commit-activity/t/holland-built/no-yolo?style=flat-square&label=commits)](https://github.com/holland-built/no-yolo/commits/main)
[![licence](https://img.shields.io/github/license/holland-built/no-yolo?style=flat-square&label=licence)](LICENSE)

## What this is

Every time Claude Code starts, it reads a folder in your home directory called `.claude`. That folder is where its rules and its shortcut commands live. This repo **is** that folder, saved so you can copy it onto your machine.

Once you do, Claude Code starts working like this:

- Replies come back in plain words, not jargon.
- Writing and designs get checked so they don't come out looking AI-made.
- Nothing gets built until you have seen a plan and said yes.
- Small jobs go to a cheap AI, hard thinking to the expensive one, so you pay less.
- Research uses the last 30 days, not whatever the AI picked up in training.
- Every time you publish, the files are checked for mistakes and stale text.
- Any kind of project works. The design tools stay quiet unless there is a screen to design.

Copy it to your own GitHub account (that's called a **fork**) and it's yours. Change any file, add your own commands. `/checkup` can still spot in later improvements without wiping what you wrote.

## Install on a new machine

Paste this into a terminal. It saves your existing setup first, then downloads this one.

```bash
mv ~/.claude ~/.claude.bak 2>/dev/null || true   # backs up any existing ~/.claude
git clone https://github.com/holland-built/no-yolo.git ~/.claude
bash ~/.claude/setup.sh
```

Then open Claude Code anywhere and type `/checkup`. If you get a table of commands back, it worked.

For a fuller check, run `bash ~/.claude/verify.sh`. Every row should say PASS. It is the same script the automated checks run.

**Never done anything like this before?** Open Claude Code and say: `walk me through installing this — read ~/.claude/INSTALL.md`. It looks at your computer and explains each step.

**That is the whole install. Everything below is reference — read it when you need it, not before.**

Four words you will see:

| Word | What it means |
|---|---|
| skill | a shortcut command you type, like `/health` |
| plugin | a bundle of extra skills someone else made |
| MCP server | a connection that gives Claude an extra tool, like a web browser |
| hook | a small script that runs by itself at set moments |

`setup.sh` is safe to run again. It skips the steps it already finished and prints what it is doing. One thing to know: the borrowed-skill installs (`npx skills@latest add …`) run every time, and may pull newer versions of those skills.

Two smaller installs:

| Command | What you get |
|---|---|
| `bash ~/.claude/setup.sh --md-only` | The rules only, no tools. Needs python3. It saves your `CLAUDE.md` first, and a later full run puts it back, so this is safe to try. |
| `bash ~/.claude/setup.sh --core-only` | Only this repo's own commands, nothing written by other people. Run plain `setup.sh` later to add the rest. |

**No Codex on your machine?** Fine. The steps that would use it notice it is missing and skip themselves. Nothing errors.

**Read next:** `CLAUDE.md` (the map) → `memory/CLAUDE.generated.md` (the working preferences that load every session) → `/checkup` (every command). Everything else is reached from those three.

## Prerequisites

| Tool | Check you have it | Get it |
|---|---|---|
| [Claude Code](https://claude.ai/code) | `claude --version` | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |
| **git** | `git --version` | Already on a Mac; Linux: `sudo apt install git` |
| **Node.js 20+** | `node --version` | Mac: [nodejs.org](https://nodejs.org/) · Ubuntu: `curl -fsSL https://deb.nodesource.com/setup_22.x \| sudo -E bash - && sudo apt install -y nodejs` (apt's own nodejs is v18 — too old, four add-ons fail) |
| **python3** | `python3 --version` | Already on a Mac; needed for `--md-only`, the plugin list, and the catalog scripts |

`~` means your home folder — on a Mac `/Users/<username>`, on Linux `/home/<username>`.

### Add-ons

Everything here is optional. Install one only when you want the command that uses it.

| Add-on | What it does | Used by | Install |
|---|---|---|---|
| [impeccable](https://github.com/pbakaus/impeccable) | 59 deterministic checks on UI source (no model call, no API key) | `/design`, `/checkup` | Nothing to install — run on demand as `npx -y impeccable detect` (needs Node + network) |
| [Codex plugin](https://github.com/openai/codex-plugin-cc) | Gets a second opinion from OpenAI's Codex | `/xcheck` and others (see note) | `/plugin marketplace add openai/codex-plugin-cc` then `/plugin install codex@openai-codex` |
| [archify](https://github.com/tt-a1i/archify) | Turns a description into a diagram | diagrams | installed by `setup.sh` |
| [fallow](https://www.npmjs.com/package/fallow) | Finds code nothing uses any more | `/health` | installed by `setup.sh` (`npm install -g fallow@2.98.0`) |
| [gh (GitHub CLI)](https://cli.github.com/) | GitHub from the terminal | `/health`, `/release` | Mac: `brew install gh` · Linux: `sudo apt install gh` — then `gh auth login` |
| [Groq Whisper key](https://console.groq.com/) | Turns speech in a video into text | `/watch` | Free API key, then `export GROQ_API_KEY=...` in `~/.zshrc` |
| [Chrome](https://www.google.com/chrome/) | Renders design previews | `/design`, `/build` | Usually already there. Mac: `brew install --cask google-chrome` · Linux: download the `.deb` from the link |
| [Playwright MCP](https://github.com/microsoft/playwright-mcp) | Lets Claude drive a browser | `/build` | Add the `playwright` MCP server to `settings.json` (see below) |
| Firecrawl MCP | Searches and reads web pages | optional | See `docs/MCP_SERVICES.md` |
| [interface-design MCP](https://github.com/Dammyjay93/interface-design) | Remembers past design decisions | `/design` (optional) | Add to `settings.json` under `mcpServers` |
| [design-refine MCP](https://github.com/0xdesign/design-plugin) | Compares design versions side by side | `/design` (optional) | Add to `settings.json` under `mcpServers` |

The install commands show Mac (`brew`). On Linux use your package manager (`sudo apt install gh`) or the vendor's page.

> **More on the Codex add-on.** `/xcheck`, `/health`, `/build`, `/design` and `/design` use it directly. `/build --plan-only`, `/debate` and `/health --debate` use it through their `/xcheck` step. Every one of them skips it quietly if it isn't installed. It needs a ChatGPT login (the free tier works) or an OpenAI API key. `/xcheck` asks for the `gpt-5.6-sol` model, which may need a paid plan; without it, Codex falls back to your default model.

> **MCP servers** give Claude an extra tool. You add one as a block of settings in `settings.json` — see the [Claude MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp).
>
> ⚠️ **Security note.** Claude asks your permission before running most commands. The settings shipped here deliberately do **not** pre-approve five of them: `Bash(curl:*)`, `Bash(env:*)`, `Bash(export:*)`, `Bash(chmod:*)` and `Bash(cat:*)`. Used together, those five are enough to read a password or key off your machine and send it out to someone else, without ever showing you a prompt. Leaving them un-approved means the first time a session wants one, you get asked. `skipAutoPermissionPrompt` is `false` for the same reason — this repo is called no-yolo. Reading `.env` files, which is where passwords and keys usually sit, is blocked as well by `permissions.deny: ["Read(.env)"]`.
>
> **Turning them back on.** On a computer only you use, you can add any of those five back to `permissions.allow` in your own `settings.json` (that file never leaves your machine), and set `skipAutoPermissionPrompt: true`. There is a safer route first: the `fewer-permission-prompts` skill reads what you actually run and writes a narrow approved list from that, instead of approving everything. Only remove the `Read(.env)` block if you understand what it exposes.

### Running two accounts from one setup

Claude Code keeps its login in the config folder, so two accounts need two folders. You cannot
share one. What you *can* share is everything else — and you should, or the two drift apart.

Point each account at its own folder with `CLAUDE_CONFIG_DIR`, as a shell alias:

```sh
alias cc-home='CLAUDE_CONFIG_DIR="$HOME/.claude" claude'
alias cc-work='CLAUDE_CONFIG_DIR="$HOME/.claude-work" claude'
```

Then make the second folder a set of shortcuts back to this one. `~/.claude` is the authority;
the other folder owns only its login, history and sessions:

```sh
cd "$HOME/.claude-work"
for p in skills docs hooks agents commands memory CLAUDE.md settings.json; do
  [ -e "$p" ] && [ ! -L "$p" ] && mv "$p" "$p.replaced-$(date +%F)"
  ln -s "$HOME/.claude/$p" "$p"
done
```

**`settings.json` is the one people miss, and it is the one that bites.** Skills and docs are
usually linked on day one; settings gets copied instead, then edited in one folder and not the
other. On 2026-08-05 that drift left the work folder pointing at five hooks this repo had
deleted — two errors on every session start, `MODULE_NOT_FOUND`, and none of the plain-English
mode, slop guard, format check or approved-command list that the main folder had. Link it, don't
copy it. Anything you genuinely want to differ per account (a pinned model, an extra plugin)
belongs in `~/.claude/settings.json` for both, or in neither.

Because `settings.json` is gitignored, cloning this repo cannot recreate those links for you —
that is why they are written down here.

## Set up a new project

Nothing to do. Skills make their own folders when they need them, like `brainstorms/`. The one thing you might add is an MCP server in `settings.json` under `"mcpServers"`, for example `"playwright": { "command": "npx", "args": ["-y", "@playwright/mcp@latest"] }`. Add one only when a skill asks for it.

## Directory layout

| Path | What it holds |
|---|---|
| `CLAUDE.md` | The main rules file. It holds no rules itself — it points at the others. |
| `docs/CORE_RULES.md` | 8 core rules, rebuilt 2026-08-04 from the survivors of a six-day test that unloaded all 35. Each one names the evidence that earned it back |
| `docs/*.md` | One file per topic (planning, testing, memory, and so on), each pointed at by `CLAUDE.md`. `/checkup` lists them and flags any that nothing reads |
| `memory/` | Things you asked it to remember. `facts/` is the real copy; `CLAUDE.generated.md` is built from it. |
| `skills/` | Your commands, plus links to the borrowed ones |
| `hooks/` | Small scripts that run by themselves: plain English mode, the bottom status bar, the edit blocker |
| `settings.example.json` | Starter settings with no passwords in them. `setup.sh` copies this to `settings.json`. |

## Skills inventory

A skill is a shortcut command you type, like `/health`. There are 18 custom commands, plus 1 utility command (`/memory-compile`, which lives in `commands/`), plus 19 borrowed from other people's repos.

| Skill | What it does | Skill | What it does |
| --- | --- | --- | --- |
| build | Whole job: plan, mockup, build, prove | design | All UI work — 7 modes it picks for you |
| health | Review, diagnose or autonomously fix | checkup | One health pass over your own setup |
| release | Publish, following the repo's SHIP.md | xcheck | Codex second opinion on a plan |
| better-prompt | Sharpen a rough prompt | eli5 | Plain-English table, no jargon |
| whats-next | Shows unfinished work | debate | 7-persona decision debate |
| lockstep | Hard block on file edits | remember-that | Save facts across sessions |
| watch | Ask a video questions, or file it | ingest-docs | PDFs and decks to context files |
| last-30 | What gained traction this month | dep-audit | npm supply-chain risk audit |
| route-map | Proves every page's content | — | — |

The borrowed 19 are not commands you type — they are reference text and behaviours the 18 read. `/design` reads the eight design and animation ones; `/health` invokes the ponytail set and `improve`; `archify`, `resolving-merge-conflicts`, `computer-use` and `orca-cli` stand alone. They live in `~/.agents/skills/`, installed by `npx skills`, so removing them is that tool's job and not a matter of deleting a file here.


## Model guidance

Claude comes in three sizes and they cost different amounts. This setup picks one per job, so you don't pay top price for small work.

| Model | Used for | Cost |
|---|---|---|
| Haiku | tests and small edits | cheapest |
| Sonnet | most coding and reviews | middle, and the default |
| Opus | planning and hard analysis | most expensive |

The rule: a planning model writes the plan, then separate agents do the building — never the same breath. Today that is Fable planning and Opus building; swapping in a newer, better planner is expected. Never start coding without a plan.

## Keeping your setup up to date

Type `/checkup` in this folder. You don't need to know git. It checks GitHub without changing anything, tells you in plain words what is different, then you pick what to act on:

| You type | What happens |
|---|---|
| `preview` | shows the changes, changes nothing |
| `full` | pulls everything and re-runs setup |
| `rules` | pulls only the rule files |
| `rollback` | undoes the last update |
| `restore <name>` | brings back one file |

If you have edited files yourself, `full` is still safe. It puts your edits aside, applies the update, puts your edits back, and tells you about anything that clashed. The changes take effect next time you start Claude Code.

## Keeping your fork in sync

A fork is your own copy of this repo on your GitHub account. `/checkup` tells you when the original has moved on, without changing anything. To actually pull those changes in:

```bash
cd ~/.claude
git remote add upstream https://github.com/holland-built/no-yolo.git 2>/dev/null
git fetch upstream && git rebase upstream/main
```

That replays your own changes on top, so nothing you wrote is lost. Then `git push --force origin main`.

## Add a new skill

Make a file at `skills/<name>/SKILL.md` with `user-invocable: true`, and put the phrases that should trigger it in that same `description`. That is the whole checklist.

There is deliberately no catalogue to update, no lock file to re-seal and no index to regenerate. This repo used to have all three, and maintaining them cost more edits than the skills themselves — roughly 390 commits against files whose only job was describing other files. `/checkup` now derives the inventory from the folder at read time instead.

Before adding one, ask whether an existing skill should gain a mode instead. Seventeen commands with modes beat fifty-two commands; that is the entire lesson of this repo's first six weeks.

## Update memory preferences

**Easy way:** just say "Remember that I use pnpm, not npm", or "Forget what you saved about X". It is saved, and it carries over into your next session.

**The way that travels to another computer:** add a file under `memory/facts/`, run `/memory-compile`, then commit. Only the built-up summary, `memory/CLAUDE.generated.md`, gets uploaded. The `memory/facts/` folder is private on purpose. Git ignores it, and a check before every commit blocks it, so the raw notes never leave your machine. Never hand-edit `CLAUDE.generated.md`; it is overwritten every time you compile.

## Plain English mode

On by default. Every reply uses plain words and short charts instead of jargon and long paragraphs. Code, commands, file contents and security warnings are still written out exactly, because those have to be precise.

To turn it off, set `ELI5_MODE=off`, or say "stop eli5" to drop it for the rest of a session. The script behind it is `hooks/eli5-activate.js`.

## The status bar (the line at the bottom of Claude Code)

Example: `Opus 5 · 42%ctx · 5h 18% 3h · wk 40% 5d · no-yolo* · ⬢ prod`

| Piece | What it means |
|---|---|
| `Opus 5` | which model you are talking to |
| `42%ctx` | how full Claude's memory of this conversation is. Over 60%, type `/compact`. |
| `5h 18% 3h` | you have used 18% of your 5-hour allowance; it resets in 3 hours |
| `wk 40% 5d` | 40% of your 7-day allowance used; it resets in 5 days |
| `no-yolo*` | the folder you are in. The `*` means you have changes not yet saved to git. |
| `⬢ prod` | which environment the branch you're on counts as |

It is drawn by `hooks/statusline.sh`. When literal mode is on, a badge for it appears at the front.

## The CLAUDE.md instruction chain

`CLAUDE.md` holds pointers and nothing else: three imports — `@memory/CLAUDE.generated.md` (learned preferences), `@docs/CORE_RULES.md` (8 rules, down from 35 after a six-day test with them switched off), and `@docs/ANTISLOP.md` — then one line per topic, each naming the condition before the file (Before any multi-file change → `PLANNING.md`, and so on). Never put an actual rule in `CLAUDE.md`. Put it in the right topic file and point at it.

Anti-slop is imported rather than pointed at, and it is the only doc treated that way: a pointer gets read after the writing has already started.

The reasoning behind the current shape of all of this — what was deleted, what was kept, and the evidence for each call — is `docs/FRESH_START_PLAN.md`. Read it before you undo something here on the grounds that it looks arbitrary.

## What's excluded

These are kept out of git on purpose.

| Left out | Why |
|---|---|
| `settings.json` | It is specific to your computer — paths, connections, possibly API keys. Never commit it. Start from `settings.example.json`. |
| `plugins/` and plugin shortcuts (`ponytail*/`, `improve`, …) | Other people's code. Reinstall from the Add-ons table. |
| `skills/design/vendor/` | Other people's code, fetched on demand. `/checkup` reports when it has drifted from upstream. |
| `.pending-tasks.md`, `learnings.md` | Working files on your machine: the `/whats-next` list and the `/better-prompt --refresh` output |
| `cache/`, `sessions/`, `history.jsonl`, logs | Temporary files |

## Uninstall

Remove one tool at a time: `npx skills@latest remove DietrichGebert/ponytail` · `npx skills@latest remove shadcn/improve` · `npm uninstall -g fallow` · `/plugin remove <name>` inside Claude Code.

Remove all of it: `rm -rf ~/.claude`. If you used the install command above, your old setup is still sitting at `~/.claude.bak`.
