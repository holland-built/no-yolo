# no-yolo

My personal Claude Code setup, saved in git. Fork it and you get a working setup in minutes — slash commands, strict coding habits, and a memory system that learns your preferences.

## What this is

Claude Code reads `~/.claude/` every time it starts. This repo *is* that folder, saved in git:

- **Rules** Claude reads at session start — plan before coding, surgical changes, right model for the job.
- **25 custom commands** (+2 utility commands), plus 11 borrowed from plugins — type `/name` to run one. Run `/my-skills` for the full list.
- **Memory** that learns your preferences — say "remember that I prefer X" and it carries forward.

New here? Read `CLAUDE.md` (the pointer map), then `docs/CORE_RULES.md`, then run `/my-skills` — everything else is routed from those.

## Prerequisites

| Tool | Required? | Check | Install |
|---|---|---|---|
| [Claude Code](https://claude.ai/code) | Required | `claude --version` | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |
| **git** | Required | `git --version` | Pre-installed on Mac; Linux: `sudo apt install git` |
| **Node.js** | Required | `node --version` | [nodejs.org](https://nodejs.org/) |
| **gh** (GitHub CLI) | Optional — for `/release` | `gh auth status` | `brew install gh && gh auth login` |

`~` means your home directory — Mac: `/Users/<username>`, Linux: `/home/<username>`.

## Install on a new machine

**Step 1 — Clone** (the `mv` backs up any existing `~/.claude`; to read first, clone elsewhere):

```bash
mv ~/.claude ~/.claude.bak 2>/dev/null || true
git clone https://github.com/holland-built/no-yolo.git ~/.claude
```

**Step 2 — Run setup.sh.** Safe to re-run; it skips completed steps and prints what it's doing at each one (settings.json copy, hook permissions, CLI tools, plugin skills, env vars):

```bash
bash ~/.claude/setup.sh           # full install
bash ~/.claude/setup.sh --md-only # rules only — no tools; strips skill triggers from CLAUDE.md
```

Started with `--md-only` and want tools later? Re-run the full command.

**Step 3 — Optional plugins inside Claude Code:**

- Caveman (shorter replies, saves tokens): `/plugin marketplace add JuliusBrussee/caveman`
- impeccable (frontend polish tool `/design` hands existing-UI work to): `/plugin marketplace add pbakaus/impeccable`

**Cut the noise — optional session settings.** `settings.example.json` ships with friction-cutting defaults: no feedback survey, no telemetry/error reporting, no filler model calls, no spinner tips, earlier autocompact (75%). `setup.sh` copies them in; if you have an older `settings.json`, copy the `env` block and `spinnerTipsEnabled` from `settings.example.json` — each key in that `env` block is named for exactly what it disables or tunes.

**Step 4 — Verify.** Open Claude Code anywhere and run `/my-skills` — a table of commands means setup is complete.

**Outside tools some skills need** (not installed by setup.sh):

| Tool | Used by | How to install |
|---|---|---|
| [gh (GitHub CLI)](https://cli.github.com/) | `review`, `release` | `brew install gh && gh auth login` |
| [archify](https://github.com/tt-a1i/archify) | diagrams | installed by setup.sh — zero extra deps |
| [Groq Whisper](https://console.groq.com/) | `video-to-kb` | Free API key, then `export GROQ_API_KEY=...` in `~/.zshrc` |
| [Chrome](https://www.google.com/chrome/) (headless) | `design`, `build` | Usually present; `brew install --cask google-chrome` |
| [Playwright](https://playwright.dev/) | `build` | Add the `playwright` MCP server to `settings.json` (below) |
| [shadcn/ui MCP](https://ui.shadcn.com/docs/mcp) | `design` | `pnpm dlx shadcn@latest mcp init --client claude` |
| [Lazyweb](https://github.com/aboul3ata/lazyweb-skill) | `design-audit`, `design` | `curl -fsSL https://www.lazyweb.com/install.sh \| bash` |

> **MCP servers** give Claude extra tools via a config block in `settings.json` — see the [Claude MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp).
> ⚠️ **Security note:** the example settings ship a *narrowed* default allow list — `Bash(curl:*)`, `Bash(env:*)`, `Bash(export:*)`, `Bash(chmod:*)`, and `Bash(cat:*)` are deliberately NOT auto-allowed, since together they form a prompt-free read-and-exfiltrate chain (read a secret, then ship it out) once any secret lands in your environment. `skipAutoPermissionPrompt` is `false` by default, so the first time a session wants one of those you'll get a permission prompt — that's intended for a repo named no-yolo. `permissions.deny: ["Read(.env)"]` also blocks reading `.env` files by default.
>
> **Opting back in.** On a trusted personal machine, add any of the five entries above back to your (gitignored) `settings.json`'s `permissions.allow`, and optionally set `skipAutoPermissionPrompt: true`. Prefer the sanctioned path over blindly re-adding wildcards: the `fewer-permission-prompts` skill scans your own transcripts and writes a scoped allowlist from your actual usage. Only remove the `Read(.env)` deny entry if you understand the exposure.

## Set up a new project

None required — skills create their own folders (e.g. `brainstorms/`). The one thing you may add is MCP servers in `settings.json`'s `"mcpServers"` block — e.g. `"playwright": { "command": "npx", "args": ["-y", "@playwright/mcp@latest"] }`. Add one only when a skill asks for it.

## Directory layout

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Main rules file — pointers only; loads memory, routes to topic files |
| `docs/CORE_RULES.md` | The 10 core working rules |
| `docs/*.md` | Topic rule files CLAUDE.md points at — e.g. PLANNING, TESTING, SUBAGENTS, CONTEXT, SKILLS, CODE_REVIEW, UI_MOCKUPS, MEMORY, SKILL_TRIGGERS, NO_YOLO (skill authoring), DAILY_CHANGELOG (public changelog, `/release` appends here) |
| `memory/` | Saved preferences — `facts/` is source of truth, `CLAUDE.generated.md` is compiled |
| `skills/` | Your skills plus symlinks to borrowed ones |
| `hooks/` | Automation scripts: caveman mode, worktree guard/auto-clean, lockstep, prompt-scan nudge, status line |
| `settings.example.json` | Starter settings, no secrets — `setup.sh` copies to `settings.json` |

## Skills inventory

A "skill" is a slash command, like `/review`.

### Frontend design — audit and build

Design tokens are read as **context, not constraint** — a redesign can replace them. Both always show light + dark mode; `/design-audit` findings can feed a `/design` fix pass.

| Command | Depth | What it does | Gates |
|---|---|---|---|
| `/design-audit` | read-only | 5 parallel lenses + adversarial verify → ranked violations; "fix it" triggers a scoped 10-mockup fix pipeline | none |
| `/design` | full pipeline | Brand seed → 10 Opus mockups → slop validator → you pick → Opus plan → Sonnet build; `--apply-spec` swaps onto a spec's tokens | Nothing builds until you pick |

### Commands in this setup

| Skill | What it does | Modes & flags |
|---|---|---|
| `/review` | Reviews the diff AND whole codebase, one approve-all gate, then fixes | `--auto` |
| `/diagnose` | 6-step root-cause bug diagnosis | `--debate` (6-persona Opus) |
| `/build` | Full feature pipeline: evidence → Opus plan → mockup gate → TDD → prove | — |
| `/plan` | One-question-at-a-time planning interview, routes result to the right skill | — |
| `/my-md` | Lists every markdown file, global + project | — |
| `/quick-mockup` | Fast disposable gray-box HTML mockup, auto-opened in browser | — |
| `/my-skills` | This list as a one-screen table | `deep` |
| `/lockstep` | Hook that physically blocks Edit/Write until you say go | `on` / `off` |
| `/video-to-kb` | YouTube video → Obsidian wiki page (needs Obsidian + Groq key) | — |
| `/whats-next` | Runs next queued task, or proposes project improvements | — |
| `/debate` | Product-team persona debate → YES/NO/CONDITIONAL verdict | — |
| `/eli5` | Plain-English explanation before you commit | — |
| `/prompt-scan` | Snapshots system prompts + model release notes into `learnings.md` | — |
| `/better-prompt` | Rewrites a rough prompt with target/scope/criterion (run `/prompt-scan` first) | — |
| `/last-30` | Last-30-days trending signal from GitHub/HN/YouTube/X | — |
| `/md-check` | Audits `~/.claude/` docs for bloat and duplicates | `--fix` · `--drift` · `--pre FILENAME` |
| `/release` | Context-aware publish via repo-root `SHIP.md`; stops if none exists | `[env]` `--auto` |
| `/skill-audit` | Audits skill library: bucket fit, gaps, verifiers, triggers | `--audit` · `--build-verifier <skill>` · `--gotchas` |
| `/update` | Checks if your setup is behind; applies, rolls back, or restores | `preview` · `full` · `rules` · `rollback` · `restore NAME` |
| `/ingest-docs` | Converts `docs/raw/` files into dense runtime context files | — |
| `/remember-that` | Saves a decision or preference as a fact file | — |

**Hidden from `/my-skills` but still real commands:**

| Skill | What it does | Why hidden |
|---|---|---|
| `/antislop` | Slop violations table + CLEAN/SLOP-DETECTED verdict | Auto-runs inside `/review` and `/release` |
| `/tdd` | Failing test first, then make it pass | `/build` step 4 runs the same loop |

Two utility commands live in `commands/`, not `skills/`: `/watch` (watch a video and answer questions about it) and `/memory-compile` (recompile learned preferences).

### Borrowed commands

| Skill | What it does | Install |
|---|---|---|
| `/trim` + 5 sub-commands | Simplest-thing-that-works pressure, six commands in one install | `npx skills@latest add holland-built/trim` |
| `/improve` | Ranked improvement plan, never changes anything | `npx skills@latest add shadcn/improve` |
| `emil-design-eng`, `animation-vocabulary`, `review-animations` | Emil Kowalski's UI-polish/animation rules — feed `/design` and `/design-audit`, not typed directly | `npx skills@latest add emilkowalski/skills` |
| `archify` | Architecture/flow/sequence/dataflow/state diagrams as zero-dep HTML+SVG | `npx skills@latest add tt-a1i/archify` |

## Model guidance

**Haiku** — tests, small edits (cheapest). **Sonnet** — most coding and reviews (default). **Opus** — planning and hard analysis (most capable).

**The rule: Opus plans, Sonnet builds. Never code without a plan first.**

## Keeping your setup up to date

Run `/update` in any folder — no git knowledge needed. It fetches from GitHub without changing anything, shows a plain-English summary, and you choose: `preview` (changelog only), `full` (pull everything + re-run setup), `rules` (rules only), `rollback` (undo last update), `restore <name>` (bring back a removed skill). Customized clones are safe — `full` stashes, applies, restores; conflicts shown explicitly. Changes take effect on next launch.

## Keeping your fork in sync

`/update full` handles both direct clones and GitHub forks — for forks it adds an `upstream` remote and rebases your commits on top; your customizations survive. After a successful rebase, force-push: `git push --force origin main` (it reminds you).

## Add a new skill

Make `skills/<name>/SKILL.md` with `user-invocable: true` and its triggers in that same `description` (the harness injects it — no trigger block anywhere else). Then add one-line entries to `TAGLINES.md`, `WHEN_TO_USE.md`, `WHY_TO_USE.md`, and `STORIES.md` (all in `skills/my-skills/`), run `regen.py`, and re-seal with `catalog_lock.py --relock`. Run `/release` to publish. Full checklist: `docs/NO_YOLO.md`.

## Update memory preferences

**Easy way:** just say "Remember that I use pnpm, not npm" (or "Forget what you saved about X") — Claude saves it automatically.

**Committed way** (syncs across machines): add a file under `memory/facts/`, run `/memory-compile`, commit `memory/facts/` + `memory/CLAUDE.generated.md`, pull elsewhere. Never hand-edit `CLAUDE.generated.md` — it's overwritten on compile.

## Caveman mode — shorter replies

Very short replies, filler dropped — saves tokens on long sessions. On: `/caveman lite|full|ultra`. Off: `stop caveman`. Stays on across messages; the status bar shows when it's active.

## The status bar (the line at the bottom of Claude Code)

Example: `~  no-yolo  main  ●  42% ctx  2.1h/5h  18h/7d  [CAVEMAN:full]`

Left to right: home dir · project folder · git branch · `●` = uncommitted changes · context fullness (above 60%, run `/compact`) · 5-hour usage · 7-day usage · caveman level (only when active). Driven by `hooks/statusline.sh` — check that file if something looks wrong.

## The CLAUDE.md instruction chain

`CLAUDE.md` holds *only* pointers: `@docs/CORE_RULES.md` (the 10 core rules — see that file), `@memory/CLAUDE.generated.md` (compiled preferences), and topic routing (Planning → `PLANNING.md`, etc.). Never put real content in `CLAUDE.md` — put it in the right topic file and point to it.

## What's excluded

| Excluded | Reason |
|---|---|
| `settings.json` | Machine-specific (Node path, MCP servers, possible API keys) — never commit; start from `settings.example.json` |
| `plugins/` | Third-party marketplaces; each lives in its own repo |
| Plugin shortcuts (`trim*/`, `improve`, etc.) | Symlinks to `~/.agents/skills/` — reinstall via the commands above |
| `skills/design/vendor/` | Third-party content (taste-skill) — `/update vendor taste-skill` fetches it; list in `docs/THIRD_PARTY_SKILLS.md`; without it `/design` uses a built-in minimum ruleset |
| `.pending-tasks.md` | `/whats-next` task queue — local only |
| `learnings.md` | Written by `/prompt-scan` — local only |
| `cache/`, `sessions/`, `history.jsonl`, logs | Temporary runtime files |

## Uninstall

Individual tools: `npm uninstall -g fallow` · `npx skills@latest remove holland-built/trim` · `npx skills@latest remove shadcn/improve` · `/plugin remove <name>` inside Claude Code for plugins.

Remove the whole setup (backup at `~/.claude.bak` if you used the install command): `rm -rf ~/.claude`
