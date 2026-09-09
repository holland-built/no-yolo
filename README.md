# no-yolo

My Claude Code setup. Everything that makes Claude behave the way I want it to,
in one repo, so I can put it on a new machine in about two minutes.

The name is the point: no vibe coding. Claude states its assumptions, keeps
changes small, and writes the test before the fix.

## Install

**1. Clone it.**

```bash
git clone https://github.com/holland-built/no-yolo.git
cd no-yolo
```

**2. Copy the settings into your Claude folder.**

```bash
mkdir -p ~/.claude
cp CLAUDE.md settings.json statusline.sh ~/.claude/
cp -R skills output-styles ~/.claude/
chmod +x ~/.claude/statusline.sh
```

**3. Fix the status line path.** `settings.json` points at my home folder.
Point it at yours:

```bash
sed -i '' "s|/Users/sholland/.claude|$HOME/.claude|" ~/.claude/settings.json
```

On Linux, drop the `''` after `-i`.

**4. Install the plugins.**

```bash
claude plugin install mattpocock-skills@claude-plugins-official
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex
```

**5. Restart Claude Code.**

The status line should appear at the bottom. Type `/output-style` and pick
**Plain** if it isn't already on.

**Optional: the memory notes.** These are notes Claude saved about how *I* like
to work, so they only make sense if you want my habits. They live in a folder
named after the project path:

```bash
mkdir -p ~/.claude/projects/$(echo "$HOME/.claude" | sed 's|/|-|g')/memory
cp memory/*.md ~/.claude/projects/$(echo "$HOME/.claude" | sed 's|/|-|g')/memory/
```

## What's in here

| Folder or file   | What it does                                           |
| ---------------- | ------------------------------------------------------ |
| `CLAUDE.md`      | The rules Claude follows on every task                 |
| `output-styles/` | How Claude talks to me — short, plain words, no jargon |
| `memory/`        | Notes Claude saved about how I like to work            |
| `skills/`        | My own skills                                          |
| `settings.json`  | Which plugins are on, theme, status line               |
| `statusline.sh`  | The bar at the bottom of the terminal                  |
| `docs/agents/`   | Settings for Matt Pocock's skills — see below          |

### The Plain output style

The one I use hardest. It stops Claude burying the answer in a wall of text.
The core rule in it:

> When I say "wait, what?", Claude's next answer is always the right one.
> Write that answer first.

## Matt Pocock's skills

A set of workflows Claude follows, installed in step 3 above. The ones I use:

| Skill                | What it does                                   |
| -------------------- | ---------------------------------------------- |
| `/tdd`               | Writes the failing test first, then the fix    |
| `/diagnosing-bugs`   | Hunts a bug down instead of guessing at it     |
| `/code-review`       | Reviews a branch against my standards and spec |
| `/research`          | Digs through real docs and writes up what it found |
| `/grilling`          | Attacks my plan looking for holes              |
| `/domain-modeling`   | Pins down what the words in my project mean    |
| `/prototype`         | Throwaway build to test whether an idea feels right |

The skills themselves are not in this repo. They come from the plugin.

### The three settings files

Matt's skills need to know a few things about whatever project they're working
in. That's what `docs/agents/` is:

| File                           | What it tells them                     |
| ------------------------------ | -------------------------------------- |
| `docs/agents/issue-tracker.md` | My issues live on GitHub               |
| `docs/agents/triage-labels.md` | What my five sorting labels are called |
| `docs/agents/domain.md`        | Where my project notes and decisions go |

**These belong in each project, not in `~/.claude/`.** To set them up in a new
project, run `/setup-matt-pocock-skills` inside it. It asks a few questions and
writes the three files.

## What's deliberately missing

My chat history, my typed commands, and my login details are not here. They
live only on my machine. `.gitignore` blocks them.

The plugins aren't here either. Step 3 installs them fresh.

## Updating it

Edit the files and push. Nothing generates them.

```bash
cp ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/statusline.sh .
cp -R ~/.claude/output-styles ~/.claude/skills .
git add -A && git commit -m "Sync settings" && git push
```
