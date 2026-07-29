# no-yolo

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

Copy it to your own GitHub account (that's called a **fork**) and it's yours. Change any file, add your own commands. `/update` can still pull in later improvements without wiping what you wrote.

## Install on a new machine

Paste this into a terminal. It saves your existing setup first, then downloads this one.

```bash
mv ~/.claude ~/.claude.bak 2>/dev/null || true   # backs up any existing ~/.claude
git clone https://github.com/holland-built/no-yolo.git ~/.claude
bash ~/.claude/setup.sh
```

Then open Claude Code anywhere and type `/my-skills`. If you get a table of commands back, it worked.

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

**Read next:** `CLAUDE.md` (the map) → `docs/CORE_RULES.md` (the 10 working rules) → `/my-skills` (every command). Everything else is reached from those three.

## Prerequisites

| Tool | Check you have it | Get it |
|---|---|---|
| [Claude Code](https://claude.ai/code) | `claude --version` | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |
| **git** | `git --version` | Already on a Mac; Linux: `sudo apt install git` |
| **Node.js** | `node --version` | [nodejs.org](https://nodejs.org/) |
| **python3** | `python3 --version` | Already on a Mac; needed for `--md-only`, the plugin list, and the catalog scripts |

`~` means your home folder — on a Mac `/Users/<username>`, on Linux `/home/<username>`.

### Add-ons

Everything here is optional. Install one only when you want the command that uses it.

| Add-on | What it does | Used by | Install |
|---|---|---|---|
| [Caveman plugin](https://github.com/JuliusBrussee/caveman) | Short replies, fewer tokens | optional | `/plugin marketplace add JuliusBrussee/caveman` |
| [impeccable plugin](https://github.com/pbakaus/impeccable) | Polishes an existing screen | `/design` hands off to it | `/plugin marketplace add pbakaus/impeccable` |
| [Codex plugin](https://github.com/openai/codex-plugin-cc) | Gets a second opinion from OpenAI's Codex | `/xcheck` and others (see note) | `/plugin marketplace add openai/codex-plugin-cc` then `/plugin install codex@openai-codex` |
| [archify](https://github.com/tt-a1i/archify) | Turns a description into a diagram | diagrams | installed by `setup.sh` |
| [fallow](https://www.npmjs.com/package/fallow) | Finds code nothing uses any more | `/health` | installed by `setup.sh` (`npm install -g fallow@2.98.0`) |
| [gh (GitHub CLI)](https://cli.github.com/) | GitHub from the terminal | `/health`, `/release` | `brew install gh && gh auth login` |
| [Groq Whisper key](https://console.groq.com/) | Turns speech in a video into text | `/video-to-kb` | Free API key, then `export GROQ_API_KEY=...` in `~/.zshrc` |
| [Chrome](https://www.google.com/chrome/) | Renders design previews | `/design`, `/build` | Usually already there; `brew install --cask google-chrome` |
| [Playwright MCP](https://github.com/microsoft/playwright-mcp) | Lets Claude drive a browser | `/build` | Add the `playwright` MCP server to `settings.json` (see below) |
| [shadcn MCP](https://ui.shadcn.com/docs/mcp) | Fetches ready-made screen components | `/design` | `npx shadcn@latest mcp init --client claude` |
| Firecrawl MCP | Searches and reads web pages | optional | See `docs/MCP_SERVICES.md` |
| [interface-design MCP](https://github.com/Dammyjay93/interface-design) | Remembers past design decisions | `/design` (optional) | Add to `settings.json` under `mcpServers` |
| [design-refine MCP](https://github.com/0xdesign/design-plugin) | Compares design versions side by side | `/design` (optional) | Add to `settings.json` under `mcpServers` |

The install commands show Mac (`brew`). On Linux use your package manager (`sudo apt install gh`) or the vendor's page.

> **More on the Codex add-on.** `/xcheck`, `/health`, `/build`, `/design` and `/design-audit` use it directly. `/plan`, `/debate` and `/diagnose --debate` use it through their `/xcheck` step. Every one of them skips it quietly if it isn't installed. It needs a ChatGPT login (the free tier works) or an OpenAI API key. `/xcheck` asks for the `gpt-5.6-sol` model, which may need a paid plan; without it, Codex falls back to your default model.

> **MCP servers** give Claude an extra tool. You add one as a block of settings in `settings.json` — see the [Claude MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp).
>
> ⚠️ **Security note.** Claude asks your permission before running most commands. The settings shipped here deliberately do **not** pre-approve five of them: `Bash(curl:*)`, `Bash(env:*)`, `Bash(export:*)`, `Bash(chmod:*)` and `Bash(cat:*)`. Used together, those five are enough to read a password or key off your machine and send it out to someone else, without ever showing you a prompt. Leaving them un-approved means the first time a session wants one, you get asked. `skipAutoPermissionPrompt` is `false` for the same reason — this repo is called no-yolo. Reading `.env` files, which is where passwords and keys usually sit, is blocked as well by `permissions.deny: ["Read(.env)"]`.
>
> **Turning them back on.** On a computer only you use, you can add any of those five back to `permissions.allow` in your own `settings.json` (that file never leaves your machine), and set `skipAutoPermissionPrompt: true`. There is a safer route first: the `fewer-permission-prompts` skill reads what you actually run and writes a narrow approved list from that, instead of approving everything. Only remove the `Read(.env)` block if you understand what it exposes.

## Set up a new project

Nothing to do. Skills make their own folders when they need them, like `brainstorms/`. The one thing you might add is an MCP server in `settings.json` under `"mcpServers"`, for example `"playwright": { "command": "npx", "args": ["-y", "@playwright/mcp@latest"] }`. Add one only when a skill asks for it.

## Directory layout

| Path | What it holds |
|---|---|
| `CLAUDE.md` | The main rules file. It holds no rules itself — it points at the others. |
| `docs/CORE_RULES.md` | The 10 rules Claude works by |
| `docs/*.md` | One file per topic (planning, testing, memory, and so on), each pointed at by `CLAUDE.md`. A one-line summary of every file is in [`skills/my-md/GLOBAL_DESCRIPTIONS.md`](skills/my-md/GLOBAL_DESCRIPTIONS.md) |
| `memory/` | Things you asked it to remember. `facts/` is the real copy; `CLAUDE.generated.md` is built from it. |
| `skills/` | Your commands, plus links to the borrowed ones |
| `hooks/` | Small scripts that run by themselves: plain English mode, the bottom status bar, the edit blocker |
| `settings.example.json` | Starter settings with no passwords in them. `setup.sh` copies this to `settings.json`. |

## Skills inventory

A skill is a shortcut command you type, like `/health`. There are 31 custom commands, plus 1 utility command (`/memory-compile`, which lives in `commands/`), plus 11 borrowed from other people's plugins.

| Skill | What it does | Skill | What it does |
| --- | --- | --- | --- |
| design | Fresh UI mockup generation | quick-mockup | 5 style-matched layout candidates |
| design-audit | 5-lens UI violation audit | match-all | Conform siblings to one golden |
| build | Full feature build pipeline | plan | Pre-build decision interview |
| health | Diff, health + trend review | xcheck | Codex second opinion on plans |
| fixloop | Find and fix, no commentary. | last-30 | Trending last 30 days |
| watch | Ask a video questions | video-to-kb | YouTube video to KB note |
| ingest-docs | Docs to context files | diagnose | Root-cause bug analysis |
| debate | 7-persona decision debate | improve | Deep audit, generates plans |
| prompt-scan | Scan prompts, log learnings | better-prompt | Sharpen a rough prompt |
| archify | Zero-dep diagram generator | remember-that | Save facts across sessions |
| my-skills | This skill menu | whats-next | Shows unfinished work |
| release | One command, any repo | eli5 | Plain-English explain anything, no jargon |
| my-md | List all markdown files | md-check | Audit + fix docs |
| skill-audit | Audit skill library health | update | Check/apply setup updates |
| lockstep | Hard block on edits | checkup | Full skill-library health pass |
| literal | Obey exactly, no push-back | — | — |

That table is the menu of what you can run, so it is not a straight list of the custom commands. It adds 2 borrowed ones (`improve`, `archify`) and leaves out 2 that only run inside other commands.

The table is a copy of [`skills/my-skills/RENDERED_FAST.md`](skills/my-skills/RENDERED_FAST.md). Inside Claude Code, `/my-skills` shows the same thing, and `/my-skills deep` adds when and why to use each one, from [`RENDERED.md`](skills/my-skills/RENDERED.md). Every command's options are also listed on their own page, [`docs/FLAGS.md`](docs/FLAGS.md), which is generated so it can't go stale.

The borrowed sets install one command each:

- `npx skills@latest add DietrichGebert/ponytail` — six commands that push for the simplest solution
- `npx skills@latest add shadcn/improve` — `/improve`, the deep audit
- `npx skills@latest add emilkowalski/skills` — screen-polish rules that `/design` reads
- `npx skills@latest add tt-a1i/archify` — the diagram maker

Two commands are hidden from `/my-skills` but still real: `/antislop`, which runs inside `/health` and `/release`, and `/tdd`, which is the same loop that step 4 of `/build` runs.

## Model guidance

Claude comes in three sizes and they cost different amounts. This setup picks one per job, so you don't pay top price for small work.

| Model | Used for | Cost |
|---|---|---|
| Haiku | tests and small edits | cheapest |
| Sonnet | most coding and reviews | middle, and the default |
| Opus | planning and hard analysis | most expensive |

The rule: Opus writes the plan, Sonnet does the building. Swapping in a newer, better planner is allowed — see rule 5 in `docs/CORE_RULES.md`. Never start coding without a plan.

## Keeping your setup up to date

Type `/update` in any folder. You don't need to know git. It checks GitHub without changing anything, tells you in plain words what is different, then you pick one:

| You type | What happens |
|---|---|
| `preview` | shows the changes, changes nothing |
| `full` | pulls everything and re-runs setup |
| `rules` | pulls only the rule files |
| `rollback` | undoes the last update |
| `restore <name>` | brings back one file |

If you have edited files yourself, `full` is still safe. It puts your edits aside, applies the update, puts your edits back, and tells you about anything that clashed. The changes take effect next time you start Claude Code.

## Keeping your fork in sync

A fork is your own copy of this repo on your GitHub account. `/update full` works whether you cloned this directly or forked it. For a fork it also links your copy back to the original and replays your own changes on top, so nothing you wrote is lost. After that, send your copy back up with `git push --force origin main`. It reminds you.

## Add a new skill

Make a file at `skills/<name>/SKILL.md` with `user-invocable: true` in it, and put the phrases that should trigger it in that same `description`. Then update the list files in `skills/my-skills/`, run `regen.py`, and re-seal with `catalog_lock.py --relock`. Full checklist: `docs/NO_YOLO.md`.

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

It is drawn by `hooks/statusline.sh`. If you install the optional caveman or literal modes, a badge for each appears at the front.

## The CLAUDE.md instruction chain

`CLAUDE.md` holds pointers and nothing else: `@docs/CORE_RULES.md`, `@memory/CLAUDE.generated.md`, and one line per topic (Planning → `PLANNING.md`, and so on). Never put an actual rule in `CLAUDE.md`. Put it in the right topic file and point at it.

## What's excluded

These are kept out of git on purpose.

| Left out | Why |
|---|---|
| `settings.json` | It is specific to your computer — paths, connections, possibly API keys. Never commit it. Start from `settings.example.json`. |
| `plugins/` and plugin shortcuts (`ponytail*/`, `improve`, …) | Other people's code. Reinstall from the Add-ons table. |
| `skills/design/vendor/` | Other people's code. `/update vendor taste-skill` fetches it. See `docs/THIRD_PARTY_SKILLS.md`. |
| `.pending-tasks.md`, `learnings.md` | Working files on your machine: the `/whats-next` list and the `/prompt-scan` output |
| `cache/`, `sessions/`, `history.jsonl`, logs | Temporary files |

## Uninstall

Remove one tool at a time: `npx skills@latest remove DietrichGebert/ponytail` · `npx skills@latest remove shadcn/improve` · `npm uninstall -g fallow` · `/plugin remove <name>` inside Claude Code.

Remove all of it: `rm -rf ~/.claude`. If you used the install command above, your old setup is still sitting at `~/.claude.bak`.
