# no-yolo

[![last commit](https://img.shields.io/github/last-commit/holland-built/no-yolo?style=flat-square&label=last%20commit)](https://github.com/holland-built/no-yolo/commits/main)
[![checks](https://img.shields.io/github/actions/workflow/status/holland-built/no-yolo/ci.yml?branch=main&style=flat-square&label=checks)](https://github.com/holland-built/no-yolo/actions)
[![release](https://img.shields.io/github/v/release/holland-built/no-yolo?style=flat-square&label=release)](https://github.com/holland-built/no-yolo/releases/latest)
[![commits](https://img.shields.io/github/commit-activity/t/holland-built/no-yolo?style=flat-square&label=commits)](https://github.com/holland-built/no-yolo/commits/main)
[![licence](https://img.shields.io/github/license/holland-built/no-yolo?style=flat-square&label=licence)](LICENSE)

## What this is

Every time Claude Code starts, it reads a folder in your home directory called `.claude`. That
folder is where its rules and its shortcut commands live. This repo **is** that folder, saved
so you can copy it onto your machine.

Once you do, Claude Code starts working like this:

- Every claim about the state of something arrives with the command that established it. What
  was not measured gets called a guess.
- Nothing gets built until you have seen a plan and said yes.
- A second model reads the approach before any code exists.
- Library versions come from the registry and library docs come from the live docs, not from
  what the model remembers.
- Destructive shell commands are stopped before they run, and come back to you with what they
  would have removed.
- Writing that sounds machine-made is caught the moment a file is saved and sent back to be
  rewritten, before you ever read it.
- Any kind of project works. Nothing is loaded that the job has not asked for.

Copy it to your own GitHub account (that's called a **fork**) and it's yours. Change any file,
add your own commands. `/checkup` can still spot later improvements without wiping what you
wrote.

## Install on a new machine

Paste this into a terminal. It saves your existing setup first, then downloads this one.

```bash
mv ~/.claude ~/.claude.bak 2>/dev/null || true   # backs up any existing ~/.claude
git clone https://github.com/holland-built/no-yolo.git ~/.claude
bash ~/.claude/setup.sh
```

Then run `bash ~/.claude/verify.sh`. Every row should say PASS. It is the same script the
automated checks run. After that, open Claude Code anywhere and type `/checkup`.

`setup.sh` installs nothing from the internet. It checks your tools, seeds `settings.json` and
the deny-list from their templates, makes the hooks executable, and puts the secret scanner
into this clone's git hooks. It is safe to run again.

**Never done anything like this before?** Open Claude Code and say: `walk me through
installing this, read ~/.claude/INSTALL.md`. It looks at your computer and explains each step.

**That is the whole install. Everything below is reference, read it when you need it, not
before.**

Four words you will see:

| Word | What it means |
|---|---|
| skill | a shortcut command you type, like `/build` |
| plugin | a bundle of extra skills someone else made |
| MCP server | a connection that gives Claude an extra tool, like a web browser |
| hook | a small script that runs by itself at set moments |

## Prerequisites

| Tool | Check you have it | Get it |
|---|---|---|
| [Claude Code](https://claude.ai/code) | `claude --version` | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |
| **git** | `git --version` | Already on a Mac; Linux: `sudo apt install git` |
| **jq** | `jq --version` | Mac: `brew install jq` · Linux: `sudo apt install jq` |
| **Node.js 20+** | `node --version` | Mac: [nodejs.org](https://nodejs.org/) · Ubuntu: `curl -fsSL https://deb.nodesource.com/setup_22.x \| sudo -E bash - && sudo apt install -y nodejs` (apt's own nodejs is v18, too old) |
| **python3** | `python3 --version` | Already on a Mac |

`~` means your home folder: on a Mac `/Users/<username>`, on Linux `/home/<username>`.

**jq is not optional.** Both guard hooks read their input with it, and the destructive-command
guard refuses every command when jq is missing rather than waving them through. A guard that
cannot read its input and exits quietly is worse than no guard, because it looks like
protection.

### Optional extras

Thirteen outside pieces make some steps better and none of them is required: every file that
reaches for one carries a fallback. `INSTALL.md` lists what each one gives you and holds the
commands that install them.

Every name in that file is pinned to a project in `hooks/externals.txt` and re-checked by
`verify.sh` on every run, because on 2026-08-21 six of the seven names it listed turned out to
be wrong and one of them was not a package at all.

The second-model check needs the `codex` CLI. Where it is absent, every step that would use it
reports itself as "did not run" and carries on. See `rules/codex.md`.

> **MCP servers** give Claude an extra tool. You add one as a block of settings in
> `settings.json`, see the [Claude MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp).
>
> ⚠️ **Security note.** Claude asks your permission before running most commands. The settings
> shipped here deliberately do **not** pre-approve five of them: `Bash(curl:*)`, `Bash(env:*)`,
> `Bash(export:*)`, `Bash(chmod:*)` and `Bash(cat:*)`. Used together, those five are enough to
> read a password or key off your machine and send it out to someone else, without ever showing
> you a prompt. Leaving them un-approved means the first time a session wants one, you get
> asked. `skipAutoPermissionPrompt` is `false` for the same reason: this repo is called no-yolo.
> Reading `.env` files, which is where passwords and keys usually sit, is blocked as well by
> `permissions.deny: ["Read(.env)"]`.
>
> **Turning them back on.** On a computer only you use, you can add any of those five back to
> `permissions.allow` in your own `settings.json` (that file never leaves your machine), and set
> `skipAutoPermissionPrompt: true`. There is a safer route first: the `fewer-permission-prompts`
> skill reads what you actually run and writes a narrow approved list from that, instead of
> approving everything. Only remove the `Read(.env)` block if you understand what it exposes.

### Running two accounts from one setup

Claude Code keeps its login in the config folder, so two accounts need two folders. You cannot
share one. What you *can* share is everything else, and you should, or the two drift apart.

Point each account at its own folder with `CLAUDE_CONFIG_DIR`, as a shell alias:

```sh
alias cc-home='CLAUDE_CONFIG_DIR="$HOME/.claude" claude'
alias cc-work='CLAUDE_CONFIG_DIR="$HOME/.claude-work" claude'
```

Then make the second folder a set of shortcuts back to this one. `~/.claude` is the authority;
the other folder owns only its login, history and sessions:

```sh
cd "$HOME/.claude-work"
for p in skills docs rules hooks agents CLAUDE.md settings.json; do
  [ -e "$p" ] && [ ! -L "$p" ] && mv "$p" "$p.replaced-$(date +%F)"
  ln -s "$HOME/.claude/$p" "$p"
done
```

**`settings.json` is the one people miss, and it is the one that bites.** Skills and docs are
usually linked on day one; settings gets copied instead, then edited in one folder and not the
other. On 2026-08-05 that drift left the work folder pointing at five hooks this repo had
deleted: two errors on every session start, `MODULE_NOT_FOUND`, and none of the guards the main
folder had. Link it, don't copy it. Anything you genuinely want to differ per account (a pinned
model, an extra plugin) belongs in `~/.claude/settings.json` for both, or in neither.

Because `settings.json` is gitignored, cloning this repo cannot recreate those links for you.
That is why they are written down here.

## Set up a new project

Nothing to do. Skills make their own folders when they need them. The one thing you might add
is an MCP server in `settings.json` under `"mcpServers"`, for example
`"playwright": { "command": "npx", "args": ["-y", "@playwright/mcp@latest"] }`. Add one only
when a skill asks for it.

## Directory layout

| Path | What it holds |
|---|---|
| `CLAUDE.md` | Six rules, loaded every session, and a table of pointers to everything else |
| `docs/*.md` | One file per topic, each opened only when its condition fires. `DECISIONS.md` holds the evidence behind every rule |
| `rules/*.md` | The rules two or more files share, so a change reaches both at once |
| `skills/` | Your commands, one directory each |
| `hooks/` | Small scripts that run by themselves: the two guards, the secret scanner, the status bar |
| `memory/` | Things you asked it to remember. All of it is gitignored except the template |
| `settings.example.json` | Starter settings with no passwords in them. `setup.sh` copies this to `settings.json` |

## Skills inventory

A skill is a shortcut command you type, like `/build`. There are six.

| Skill | What it does |
|---|---|
| `/build` | The whole job: evidence, interview, plan, mockups, tests, build, proof. Sizes itself, so a one-word change does not get the full pipeline |
| `/checkup` | One read-only pass over this setup: what exists, what is broken, what has drifted |
| `/eli5` | Explains anything just said in plain words, as a table |
| `/handoff` | Writes a dying session to a file a fresh session can resume from |
| `/release` | Reads the repo's own `SHIP.md` playbook and runs it |
| `/whats-next` | Reads the task list, then unfinished work in the repo, then proposes three things |

There were thirteen until 2026-08-21. The rebuild kept the six that were used and deleted the
rest; `docs/DECISIONS.md` records why. Archived commands are not gone: each has a one-line
restore command in `archive/MANIFEST.md`.

This sentence said "26" until 2026-08-22, and no commit on this branch ever had 26 skills in
it. Counted with `git ls-tree -d --name-only <commit>:skills | wc -l` across the last sixty
commits, the tracked total goes 17, then 18, then 13 on 2026-08-20 when eight commands were
archived, then 6 at the rebuild. Thirteen is what stood on the day. The likeliest source of
26 is a count that included the borrowed skills symlinked into `skills/` alongside this
repo's own, which are gitignored and cannot be recovered from history, so the number that
replaced it is the one that can be recomputed.

## The rules that load every session

`CLAUDE.md` is one page and holds six rules. Each one is there because it was measured breaking
without it, or because it carries a fact training data cannot hold. Everything else sits behind
a pointer and is opened only when its condition fires.

That shape is deliberate and was measured. A pointer table written `topic -> file` made sessions
open every sibling doc at once; written `when this happens -> read that`, they opened almost
none. Thirty-five rules were unloaded for six days and nine were missed enough to earn their way
back, so a rule now joins `CLAUDE.md` after it is observed breaking without it, and the default
for a new rule is a doc behind a pointer.

The reasoning behind all of it, what was deleted and the evidence for each call, is
`docs/DECISIONS.md`. Read it before you undo something here on the grounds that it looks
arbitrary.

## Model guidance

Claude comes in several sizes and they cost different amounts. This setup picks one per job, so
you don't pay top price for small work.

| Job | Model |
|---|---|
| Planning and long-horizon design | Fable |
| Writing code, fixing, reviewing | Opus |
| Routing and short lookups | Haiku |

The rule: a planning model writes the plan, then separate agents do the building, never the same
breath. Swapping in a newer, better planner is expected. The full version is `docs/DELEGATION.md`.

## Keeping your setup up to date

Type `/checkup` in this folder. You don't need to know git. It checks GitHub without changing
anything and tells you in plain words what is different. Nothing is pulled without you asking.

## Keeping your fork in sync

A fork is your own copy of this repo on your GitHub account. `/checkup` tells you when the
original has moved on, without changing anything. To actually pull those changes in:

```bash
cd ~/.claude
git remote add upstream https://github.com/holland-built/no-yolo.git 2>/dev/null
git fetch upstream && git rebase upstream/main
```

That replays your own changes on top, so nothing you wrote is lost. Publishing the result
needs a force push, and the destructive-command guard refuses those, including
`--force-with-lease`. That is the guard working: a force push rewrites history anyone else has
already pulled. Run it yourself in a terminal outside Claude Code once you have read what it
would replace:

```bash
git push --force-with-lease origin main
```

`--force-with-lease` is the safer of the two. It refuses if someone else has pushed since you
last fetched, where a plain `--force` would overwrite them.

## Add a new skill

Make a file at `skills/<name>/SKILL.md` with `user-invocable: true`, and put the phrases that
should trigger it in that same `description`. That is the whole checklist.

There is deliberately no catalogue to update, no lock file to re-seal and no index to
regenerate. This repo used to have all three, and maintaining them cost real edits: 61 of the
341 commits reachable from any branch or tag touched a catalogue, index, manifest or lock
file, which is roughly one commit in six spent on files whose only job was describing other
files. `/checkup` derives the inventory from the folder at read time instead.

That sentence claimed "roughly 390 commits" until 2026-08-22. There are only 341 commits in
this repository across every ref (`git rev-list --count --all`), so the figure was larger than
the entire history it was drawn from. The 61 comes from counting distinct commits touching
`*CATALOG*`, `*index*`, `*MANIFEST*` and `*lock*` paths; the pattern is deliberately generous
and still lands nowhere near the old number.

Before adding one, ask whether an existing skill should gain a mode instead. Six commands with
modes beat twenty-six commands, and that is the entire lesson of this repo's first six weeks.

## Update memory preferences

**Easy way:** just say "Remember that I use pnpm, not npm", or "Forget what you saved about X".
It is saved, and it carries over into your next session.

**Where it goes:** one file per fact under `memory/facts/`, plus one line in `memory/MEMORY.md`,
which is the only part loaded into a session. Both are gitignored, because both name things
about you, so neither travels to another computer through this repo. The tracked template is
`memory/MEMORY.example.md`. A check before every commit blocks the private ones as well, so the
raw notes cannot leave your machine by accident. The rules for what earns a file are
`docs/MEMORY.md`.

## The status bar (the line at the bottom of Claude Code)

Example: `Opus 5 · 42%ctx · 5h 18% 3h · wk 40% 5d · no-yolo* · ⬢ prod`

| Piece | What it means |
|---|---|
| `Opus 5` | which model you are talking to |
| `42%ctx` | how full Claude's memory of this conversation is. Over 60%, type `/compact` |
| `5h 18% 3h` | you have used 18% of your 5-hour allowance; it resets in 3 hours |
| `wk 40% 5d` | 40% of your 7-day allowance used; it resets in 5 days |
| `no-yolo*` | the folder you are in. The `*` means you have changes not yet saved to git |

It is drawn by `hooks/statusline.sh`. When literal mode is on, a badge for it appears at the
front.

**Literal mode** is the one thing you can type that is not in the list of six above. Type
`/literal` and Claude stops offering alternatives and does exactly what you asked; `/literal
off` ends it, and so does starting a new session. It is not a skill, which is why it has no
row up there: `hooks/literal-mode-tracker.js` reads what you typed and sets a flag the status
bar shows.

## What's excluded

These are kept out of git on purpose.

| Left out | Why |
|---|---|
| `settings.json` | It is specific to your computer: paths, connections, possibly API keys. Never commit it. Start from `settings.example.json` |
| `memory/MEMORY.md`, `memory/facts/` | They name things about you. `memory/MEMORY.example.md` is the tracked template |
| `plugins/` | Other people's code. Reinstall from `INSTALL.md` |
| `.pending-tasks.md`, `learnings.md` | Working files on your machine |
| `cache/`, `sessions/`, `history.jsonl`, logs | Temporary files |

## Uninstall

Remove one tool at a time: `npm uninstall -g agnix @yawlabs/ctxlint jscpd` · `brew uninstall vale` ·
`npx skills@latest remove <name>` · `/plugin remove <name>` inside Claude Code.

Remove all of it: `rm -rf ~/.claude`. If you used the install command above, your old setup is
still sitting at `~/.claude.bak`.
