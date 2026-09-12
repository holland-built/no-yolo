# no-yolo

A setup for **Claude Code** that stops the AI from guessing.

"Vibe coding" is letting an AI write whatever it wants and hoping it works. The
name of this repo is the opposite of that. With these files installed, Claude
says what it is assuming before it writes anything, keeps its changes small, and
shows you the thing working instead of telling you it works.

Copy it onto a new machine in about two minutes.

## New to all this? Read this bit first

**Claude Code** is a program you run in your terminal. You type what you want in
plain English, and it reads and writes files on your computer for you.

It looks in a folder called `~/.claude` for instructions on how to behave. The
`~` means your home folder, so on a Mac that is `/Users/yourname/.claude`.

This repo is just a copy of that folder. Installing it means copying these
files into `~/.claude`.

Three words that show up below:

| Word | What it means |
| --- | --- |
| **Skill** | A saved recipe. You type `/build` and Claude follows the steps in `skills/build/SKILL.md`. |
| **Output style** | How Claude talks to you — long and chatty, or short and plain. |
| **Memory** | Short notes Claude keeps about how you like to work, so you don't repeat yourself. |

You need Claude Code installed first: https://claude.com/claude-code

## Install

**1. Clone this repo.**

```bash
git clone https://github.com/holland-built/no-yolo.git
cd no-yolo
```

**2. Copy the files into your Claude folder.**

```bash
mkdir -p ~/.claude
cp CLAUDE.md settings.json statusline.sh ~/.claude/
cp -R skills output-styles ~/.claude/
chmod +x ~/.claude/statusline.sh
```

**3. Point the status line at your own home folder.**

`settings.json` still has my path in it. This swaps in yours:

```bash
sed -i '' "s|/Users/sholland/.claude|$HOME/.claude|" ~/.claude/settings.json
```

On Linux, drop the `''` straight after `-i`.

**4. Install the Codex plugin.**

Codex is a second AI (OpenAI's) that reviews Claude's plans and catches its
mistakes. Several of the skills here ask it for a second opinion.

```bash
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex
```

You can skip this. The skills still work; they just stop double-checking.

**5. Restart Claude Code.**

A status bar appears at the bottom. If replies are still long and chatty, type
`/output-style` and pick **Plain**.

**Optional — the memory notes.** These are notes about how *I* like to work, so
only copy them if you want my habits too:

```bash
mkdir -p ~/.claude/projects/$(echo "$HOME/.claude" | sed 's|/|-|g')/memory
cp memory/*.md ~/.claude/projects/$(echo "$HOME/.claude" | sed 's|/|-|g')/memory/
```

## The nine skills

Type the slash command, or just say the word in a sentence — both work.

| Type this | Use it when | Example |
| --- | --- | --- |
| `/build` | You want something new made | `/build a script that renames my photos by date` |
| `/fix` | Something is broken, erroring, or slow | `/fix the login page throws a 500 on submit` |
| `/grill` | You have a plan and want it attacked | `/grill I'm going to rewrite the whole API in Go` |
| `/map` | The job is too big to see the shape of | `/map I want to redo this entire repo` |
| `/handoff` | A session is ending unfinished | `/handoff` |
| `/writing` | You're writing instructions for an AI | `/writing my CLAUDE.md isn't working` |
| `/site-design` | You need a page or screen designed | `/site-design a landing page for my bakery` |
| `/last-30` | You want to know what changed recently | `/last-30 what's new in Next.js` |
| `/claude-video` | You want a YouTube video summarised | `/claude-video https://youtu.be/...` |

### Which one do I want?

- **Making a new thing** → `/build`. For a web page, run `/site-design` first to
  settle how it looks, then `/build` to build it.
- **Something is wrong** → `/fix`. It reproduces the problem first, so it fixes
  the real cause instead of the first thing it sees.
- **A big or foggy idea** → `/map`. It writes the decisions down one at a time
  instead of charging at a rewrite.
- **About to commit to something expensive** → `/grill`. It argues with you on
  purpose.

## What's in here

| File or folder | What it does |
| --- | --- |
| `CLAUDE.md` | The rules Claude follows on every single task |
| `skills/` | The nine recipes above |
| `output-styles/plain.md` | Makes Claude answer short and in plain words |
| `memory/` | Notes about how I like to work |
| `settings.json` | Which plugins are on, the theme, the status line |
| `statusline.sh` | The bar along the bottom of the terminal |
| `scripts/` | Small helpers — status line installer, Codex tidy-up |

### The Plain output style

The one that changes the most. It stops Claude burying the answer in a wall of
text. The rule at the heart of it:

> When I say "wait, what?", Claude's next answer is always the right one.
> Write that answer first.

### The rules in CLAUDE.md

Six short sections. In plain terms they say: think before coding, write the
least code that does the job, change only what you were asked to change, decide
up front how you'll know it worked, don't sit idle when you're blocked on one
thing, and get a second opinion before anything expensive.

## What's deliberately missing

My chat history, my typed commands, and my login details are **not** in this
repo. They stay on my machine. `.gitignore` blocks them.

The plugins aren't here either — step 4 installs Codex fresh.

`docs/agents/` is left over from a plugin I no longer use. Ignore it.

## Updating it

Edit the files and push. Nothing is generated.

```bash
cp ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/statusline.sh .
cp -R ~/.claude/output-styles ~/.claude/skills .
git add -A && git commit -m "Sync settings" && git push
```

## Licence

No licence file yet. These are my own working files — take them and change them
freely. Some started life from other people's public skills before being
rewritten; if you plan to redistribute them, add a licence first.
