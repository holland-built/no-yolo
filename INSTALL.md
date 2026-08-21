# How to install this

This adds a set of extra commands, working rules, and a saved memory of your preferences to
Claude Code. Installing it means copying one folder onto your computer and running one script.

**If you are Claude reading this to someone:** run the steps in order, one at a time. After each
command, say in plain words what happened. If a step fails, stop there and use the
"If something goes wrong" table at the bottom. Never skip past an error quietly.

## First, open a terminal

The terminal is a window where you type commands instead of clicking. On a Mac, press
`Cmd` + `Space`, type `Terminal`, press Return. On Ubuntu or most Linux desktops, press
`Ctrl` + `Alt` + `T`. A window opens with a blinking cursor.

Every command below goes there: paste one line, press Return, wait for it to finish.

You will see `~` a lot. It means your home folder — on a Mac, `/Users/<yourname>`; on Linux, `/home/<yourname>`. So `~/.claude` is the folder Claude Code reads every time it starts, and this setup *is* that folder.

## Step 1 — Check what you already have

Type each command below and press Return. You are only checking that it prints a version number.

| Type this | What it does for you | A good answer looks like |
|---|---|---|
| `claude --version` | Claude Code itself | `2.0.1 (Claude Code)` |
| `git --version` | downloads the files | `git version 2.39.5` |
| `node --version` | runs the extra tools | `v22.14.0` — **must be 20 or newer** |
| `npm --version` | installs those tools (comes with Node) | `10.9.2` |
| `python3 --version` | only needed for the rules-only install in Step 4 | `Python 3.12.7` |

If one prints `command not found`, install it before going on:

| Missing | How to get it | Do you have to? |
|---|---|---|
| Claude Code | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) | Yes. This whole thing is for it. |
| git | Mac: already there. Linux: `sudo apt install git` | Yes. The installer stops without it. |
| Node and npm | Mac: [nodejs.org](https://nodejs.org/) (one download gives you both). Ubuntu/Debian: `curl -fsSL https://deb.nodesource.com/setup_22.x \| sudo -E bash - && sudo apt install -y nodejs` | Yes, for the normal install. **Version 20 or newer.** Ubuntu's own `sudo apt install nodejs` gives version 18, which is too old — four tools fail on it. |
| python3 | Mac: already there. Linux: `sudo apt install python3` | Only for the rules-only install. |

## Step 2 — Move any old setup out of the way

```bash
mv ~/.claude ~/.claude.bak 2>/dev/null || true
```

This prints nothing at all, which is the correct result. If you already had a `~/.claude` folder,
it is now sitting safely at `~/.claude.bak`. Nothing was deleted. If you had no such folder,
nothing happened.

## Step 3 — Download the files

```bash
git clone https://github.com/holland-built/no-yolo.git ~/.claude
```

You will see counting lines and then `Resolving deltas: 100%`. That means the files arrived.

## Step 4 — Pick which install you want

Most people want the first one. Pick one line and copy it, you will run it in Step 5.

| You want | Run this | What you get |
|---|---|---|
| Everything (normal) | `bash ~/.claude/setup.sh` | All rules, all commands, plus four borrowed tool sets from other people |
| Nothing from strangers | `bash ~/.claude/setup.sh --core-only` | Same, but skips the borrowed tool sets and the `fallow` tool. Run the plain command later to add them |
| Rules only, no tools | `bash ~/.claude/setup.sh --md-only` | Just the working rules. No commands installed. Needs python3 |

Any of these is safe to run again later. `--md-only` backs up your rules file first, and running
the plain version afterwards puts it back.

## Step 5 — Run it

Paste the line you picked and press Return. It takes a couple of minutes and prints as it goes:

1. **Preflight** — a `found` or `missing` line for each tool it needs.
2. **Numbered steps 1 to 6** — settings file, scripts, tools, borrowed commands, plugins, and a
   list of two optional settings you can add later.
3. **Install summary** — one line per tool, each reading `OK`, `SKIPPED`, or `FAILED`.
4. **Done.**

Read the summary. `OK` means it installed. `FAILED` means it did not, and the table at the bottom
of this page tells you what to do. Any `FAILED` also makes the script exit with an error, which
is expected, not a crash.

One message is safe to ignore for now: a note about adding MCP servers to `settings.json`.

**About permission prompts.** If Claude Code is running these for you, it may stop and ask
permission to run a command or touch a file. That is on purpose. This setup is deliberately
careful about permissions. Read what it wants to do, then allow it.

## Step 6 — Check that it worked

Open Claude Code in any folder and run:

```
/checkup
```

A table of commands means the install worked.

For a deeper check, back in the terminal:

```bash
bash ~/.claude/verify.sh
```

Every row reading `PASS` means the copy on your machine is healthy. This is the same check the
project runs on itself.

## If something goes wrong

| What you see | What to do |
|---|---|
| `git missing — required` and the script stops | Install git (Step 1 table), then run Step 5 again |
| `node and/or npm missing` and the script stops | Install Node from [nodejs.org](https://nodejs.org/), then run Step 5 again |
| `python3 missing` on the rules-only install | Install python3, or use the normal install instead |
| `claude (Claude Code) not found on PATH` | Install Claude Code. The script keeps going, but you need it to use any of this |
| `codex    not installed` | Nothing to fix. It is optional. Commands that would use it skip that part. Add it later inside Claude Code with `/plugin install codex@openai-codex` |
| `! gh missing` | Optional. The `/health` and `/release` commands want it. Mac: `brew install gh` · Linux: `sudo apt install gh`. Then `gh auth login` |
| Several summary lines read `FAILED`, with an error mentioning `styleText` | Your Node is too old. Check with `node --version`; it must be 20 or newer. Install a newer one (Step 1 table) and run Step 5 again |
| A single summary line reads `FAILED` | Open `README.md`, find that name in the **Add-ons** table, and run the command in its Install column by hand. Then run Step 5 again |
| `/checkup` shows nothing | Quit Claude Code and open it again. It only reads `~/.claude` at startup |
| A `verify.sh` row reads `FAIL` | Read the message on that row. This is a deeper check than the installer does, so it usually needs someone who codes |
| You want it all gone | `rm -rf ~/.claude` then, if you had one before, `mv ~/.claude.bak ~/.claude` |

## What to read next

`README.md` has a section called **"Read next"** with the right order to read things in. Start
there rather than opening files at random.
