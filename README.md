# no-yolo

## What this is

**A ready-made brain for Claude Code — not a settings file, a working method.** The idea is simple: an AI that must *earn* your trust at every step. It plans before touching code, proves before claiming done, and gets second-guessed — by expert debate panels, by a rival AI, by its own automated checks — before anything reaches you or your GitHub.

**When you build:** `/build` runs the whole pipeline — evidence gathering, a decision interview, a plan authored by the strongest model, your approval gate, test-first coding, and a final proof step where a claim without a passing measurement doesn't count.

**When you decide:** `/debate` convenes seven expert personas who argue it out under a chairman who discards weak arguments; a rival AI then names what all seven missed.

**When you design:** ten competing mockups render in your browser, an anti-slop judge kills the generic ones, two AIs score the survivors, and nothing gets built until you pick.

**When you publish:** secret scans, path guards, and health checks run every time; a repo without a publishing playbook doesn't get pushed, it gets a playbook written.

**All the time:** it remembers what you teach it, routes plain-English requests to the right tool on its own, answers in beginner-readable tables, and spends tokens like they're yours — because they are.

**Any stack:** the method doesn't care what you build — plans, proofs, debates, and gates work the same for a Python API, a CLI tool, or infrastructure. The design wing runs web-deep, but it only wakes up when your change touches a screen; backend work walks right past it.

Fork it and it's yours.

Claude Code reads `~/.claude/` every time it starts, and this repo *is* that folder, saved in git.

## Install on a new machine

```bash
mv ~/.claude ~/.claude.bak 2>/dev/null || true   # backs up any existing ~/.claude
git clone https://github.com/holland-built/no-yolo.git ~/.claude
bash ~/.claude/setup.sh
```

Then open Claude Code anywhere and run `/my-skills`. A table of commands means setup is complete. For a deeper health check, run `bash ~/.claude/verify.sh` — all PASS means the clone is healthy (it's the same script CI runs).

**New to this?** After cloning, open Claude Code and say: `walk me through installing this — read ~/.claude/INSTALL.md` — it checks your machine and explains every step.

**You're done. Everything below this line is reference — read it when you need it, not before.**

| Word | Plain meaning |
|---|---|
| skill | a slash command like `/health` — task instructions Claude follows |
| plugin | an add-on bundle of skills |
| MCP server | a connection that gives Claude an extra tool, like a browser |
| hook | a small script that runs automatically at set moments |

`setup.sh` is safe to re-run; it skips finished steps and prints what it's doing — with one caveat: the borrowed-skill installs (`npx skills@latest add …`) re-run every time and may update those skills to their latest upstream versions. `bash ~/.claude/setup.sh --md-only` installs rules only (no tools; requires python3) — it backs up `CLAUDE.md` and a later full run restores it, so upgrading is safe.

**Read next:** `CLAUDE.md` (the pointer map) → `docs/CORE_RULES.md` (the 10 working rules) → `/my-skills` (every command). Everything else is routed from those three.

## Prerequisites

| Tool | Check | Install |
|---|---|---|
| [Claude Code](https://claude.ai/code) | `claude --version` | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |
| **git** | `git --version` | Pre-installed on Mac; Linux: `sudo apt install git` |
| **Node.js** | `node --version` | [nodejs.org](https://nodejs.org/) |
| **python3** | `python3 --version` | Pre-installed on Mac; needed for `--md-only`, plugin listing, and catalog scripts |

`~` means your home directory — Mac: `/Users/<username>`, Linux: `/home/<username>`.

### Add-ons

Everything optional lives here. Install one only when you want the skill it serves.

| Add-on | What it does | Needed for | Install |
|---|---|---|---|
| [Caveman plugin](https://github.com/JuliusBrussee/caveman) | Shorter replies, saves tokens | optional | `/plugin marketplace add JuliusBrussee/caveman` |
| [impeccable plugin](https://github.com/pbakaus/impeccable) | Frontend polish on existing UI | `/design` handoff | `/plugin marketplace add pbakaus/impeccable` |
| [Codex plugin](https://github.com/openai/codex-plugin-cc) | Run OpenAI Codex reviews/tasks from Claude Code | Shared optional dependency: `/xcheck`, `/health`, `/build`, `/design`, `/design-audit` directly — plus `/plan`, `/debate`, `/diagnose --debate` via their `/xcheck` step. All skip silently if absent | `/plugin marketplace add openai/codex-plugin-cc` then `/plugin install codex@openai-codex`; needs a ChatGPT login (free tier OK) or OpenAI API key — `/xcheck` pins `gpt-5.6-sol`, which may need a paid plan; it falls back to your Codex default model if unavailable |
| [archify](https://github.com/tt-a1i/archify) | Architecture/flow diagrams as zero-dep HTML+SVG | diagrams | installed by `setup.sh` |
| [fallow](https://www.npmjs.com/package/fallow) | Dead-code scan | `/health` | installed by `setup.sh` (`npm install -g fallow`) |
| [gh (GitHub CLI)](https://cli.github.com/) | GitHub from the terminal | `/health`, `/release` | `brew install gh && gh auth login` |
| [Groq Whisper key](https://console.groq.com/) | Video transcription | `/video-to-kb` | Free API key, then `export GROQ_API_KEY=...` in `~/.zshrc` |
| [Chrome](https://www.google.com/chrome/) | Headless browser for mockup previews | `/design`, `/build` | Usually present; `brew install --cask google-chrome` |
| [Playwright MCP](https://github.com/microsoft/playwright-mcp) | Browser automation | `/build` | Add the `playwright` MCP server to `settings.json` (see below) |
| [shadcn MCP](https://ui.shadcn.com/docs/mcp) | Component registry access | `/design` | `npx shadcn@latest mcp init --client claude` |
| Firecrawl MCP | Web search/scrape data | optional web-data | See `docs/MCP_SERVICES.md` |
| [interface-design MCP](https://github.com/Dammyjay93/interface-design) | Design memory for the design pipeline | `/design` (optional) | Add to `settings.json` `mcpServers` |
| [design-refine MCP](https://github.com/0xdesign/design-plugin) | Variant compare for the design pipeline | `/design` (optional) | Add to `settings.json` `mcpServers` |

Install commands above show Mac (`brew`); on Linux use your package manager (e.g. `sudo apt install gh`) or the vendor's install page.

> **MCP servers** give Claude extra tools via a config block in `settings.json` — see the [Claude MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp).
>
> ⚠️ **Security note:** the example settings ship a *narrowed* default allow list. `Bash(curl:*)`, `Bash(env:*)`, `Bash(export:*)`, `Bash(chmod:*)`, and `Bash(cat:*)` are deliberately NOT auto-allowed, since together they form a prompt-free read-and-exfiltrate chain (read a secret, then ship it out) once any secret lands in your environment. `skipAutoPermissionPrompt` is `false` by default, so the first time a session wants one of those you get a permission prompt — intended, for a repo named no-yolo. `permissions.deny: ["Read(.env)"]` also blocks reading `.env` files by default.
>
> **Opting back in.** On a trusted personal machine, add any of the five entries back to your (gitignored) `settings.json`'s `permissions.allow`, and optionally set `skipAutoPermissionPrompt: true`. Prefer the sanctioned path over re-adding wildcards: the `fewer-permission-prompts` skill scans your own transcripts and writes a scoped allowlist from your actual usage. Only remove the `Read(.env)` deny entry if you understand the exposure.

## Set up a new project

Nothing required — skills create their own folders (e.g. `brainstorms/`). The one thing you may add is MCP servers in `settings.json`'s `"mcpServers"` block, e.g. `"playwright": { "command": "npx", "args": ["-y", "@playwright/mcp@latest"] }`. Add one only when a skill asks for it.

## Directory layout

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Main rules file — pointers only; loads memory, routes to topic files |
| `docs/CORE_RULES.md` | The 10 core working rules |
| `docs/*.md` | Topic rule files `CLAUDE.md` points at (PLANNING, TESTING, SUBAGENTS, MEMORY, NO_YOLO, …) — every file's one-line description lives in [`skills/my-md/GLOBAL_DESCRIPTIONS.md`](skills/my-md/GLOBAL_DESCRIPTIONS.md) |
| `memory/` | Saved preferences — `facts/` is source of truth, `CLAUDE.generated.md` is compiled |
| `skills/` | Your skills plus symlinks to borrowed ones |
| `hooks/` | Automation scripts: caveman mode, worktree guard, lockstep, status line |
| `settings.example.json` | Starter settings, no secrets — `setup.sh` copies to `settings.json` |

## Skills inventory

A "skill" is a slash command, like `/health`. The count: 26 custom commands (+2 utility commands: `/watch` and `/memory-compile` in `commands/`), plus 11 borrowed from plugins.

| Skill | What it does | Skill | What it does |
| --- | --- | --- | --- |
| design | Fresh UI mockup generation | quick-mockup | Throwaway layout mockup |
| design-audit | 5-lens UI violation audit | build | Full feature build pipeline |
| plan | Pre-build decision interview | health | Diff, health + trend review |
| xcheck | Codex second opinion on plans | last-30 | Trending last 30 days |
| video-to-kb | YouTube video to KB note | ingest-docs | Docs to context files |
| diagnose | Root-cause bug analysis | debate | 7-persona decision debate |
| improve | Deep audit, generates plans | prompt-scan | Scan prompts, log learnings |
| better-prompt | Sharpen a rough prompt | archify | Zero-dep diagram generator |
| remember-that | Save facts across sessions | my-skills | This skill menu |
| whats-next | Shows unfinished work | release | One command, any repo |
| eli5 | Plain-English table explain anything | my-md | List all markdown files |
| md-check | Audit + fix docs | skill-audit | Audit skill library health |
| update | Check/apply setup updates | lockstep | Hard block on edits |

The table shows the runnable menu: it includes 2 borrowed skills (`improve`, `archify`) and hides 2 custom helpers (`antislop`, `tdd` — see below), so it isn't a 1:1 list of the 26 custom commands. It is a copy of [`skills/my-skills/RENDERED_FAST.md`](skills/my-skills/RENDERED_FAST.md) — inside Claude Code, run `/my-skills` (same table) or `/my-skills deep` (adds when/why per skill, from [`RENDERED.md`](skills/my-skills/RENDERED.md)).

Borrowed sets install with one command each: `npx skills@latest add holland-built/trim` (six simplicity commands), `npx skills@latest add shadcn/improve`, `npx skills@latest add emilkowalski/skills` (UI-polish rules that feed `/design`), `npx skills@latest add tt-a1i/archify`.

Two commands are hidden from `/my-skills` but still real: `/antislop` (runs inside `/health` and `/release`) and `/tdd` (same loop `/build` step 4 runs).

## Model guidance

**Haiku** — tests, small edits (cheapest). **Sonnet** — most coding and reviews (default). **Opus** — planning and hard analysis (most capable). The rule: Opus plans, Sonnet builds (or the current best planner — substitutions are sanctioned, see `docs/CORE_RULES.md` rule 5). Never code without a plan first.

## Keeping your setup up to date

Run `/update` in any folder — no git knowledge needed. It fetches from GitHub without changing anything, shows a plain-English summary, and you choose: `preview`, `full` (pull everything + re-run setup), `rules`, `rollback`, or `restore <name>`. Customized clones are safe: `full` stashes, applies, restores, and shows conflicts explicitly. Changes take effect on next launch.

## Keeping your fork in sync

`/update full` handles both direct clones and GitHub forks. For forks it adds an `upstream` remote and rebases your commits on top, so your customizations survive. After a successful rebase, force-push: `git push --force origin main` (it reminds you).

## Add a new skill

Make `skills/<name>/SKILL.md` with `user-invocable: true` and its triggers in that same `description`. Then update the catalog files in `skills/my-skills/`, run `regen.py`, and re-seal with `catalog_lock.py --relock`. Full checklist: `docs/NO_YOLO.md`.

## Update memory preferences

**Easy way:** just say "Remember that I use pnpm, not npm" (or "Forget what you saved about X") — Claude saves it and it carries forward across sessions.

**Committed way** (syncs across machines): add a file under `memory/facts/`, run `/memory-compile`, then commit — only the compiled `memory/CLAUDE.generated.md` syncs. `memory/facts/` itself is deliberately private: it is both gitignored and blocked by the pre-commit scanner, so raw facts never leave the machine; the compiled summary is what travels. Never hand-edit `CLAUDE.generated.md`; it is overwritten on compile.

## Caveman mode — shorter replies

Requires the optional Caveman plugin (Add-ons table). Very short replies, filler dropped — saves tokens on long sessions. On: `/caveman lite|full|ultra`. Off: `stop caveman`. Stays on across messages; the status bar shows when it's active.

## The status bar (the line at the bottom of Claude Code)

Example: `~  no-yolo  main  ●  42% ctx  2.1h/5h  18h/7d  [CAVEMAN:full]`

Left to right: home dir · project folder · git branch · `●` = uncommitted changes · context fullness (above 60%, run `/compact`) · 5-hour usage · 7-day usage · caveman level (only when active). Driven by `hooks/statusline.sh`.

## The CLAUDE.md instruction chain

`CLAUDE.md` holds *only* pointers: `@docs/CORE_RULES.md`, `@memory/CLAUDE.generated.md`, and topic routing (Planning → `PLANNING.md`, etc.). Never put real content in `CLAUDE.md` — put it in the right topic file and point to it.

## What's excluded

| Excluded | Reason |
|---|---|
| `settings.json` | Machine-specific (paths, MCP servers, possible API keys) — never commit; start from `settings.example.json` |
| `plugins/` and plugin shortcuts (`trim*/`, `improve`, …) | Third-party; reinstall via the Add-ons table |
| `skills/design/vendor/` | Third-party (taste-skill) — `/update vendor taste-skill` fetches it; see `docs/THIRD_PARTY_SKILLS.md` |
| `.pending-tasks.md`, `learnings.md` | Local working files (`/whats-next` queue, `/prompt-scan` output) |
| `cache/`, `sessions/`, `history.jsonl`, logs | Temporary runtime files |

## Uninstall

Individual tools: `npx skills@latest remove holland-built/trim` · `npx skills@latest remove shadcn/improve` · `npm uninstall -g fallow` · `/plugin remove <name>` inside Claude Code.

Remove the whole setup (backup at `~/.claude.bak` if you used the install command): `rm -rf ~/.claude`
