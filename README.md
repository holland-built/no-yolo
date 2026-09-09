# no-yolo

My Claude Code setup, kept in version control.

Clone this onto a new machine, copy the files into `~/.claude/`, and Claude
behaves the same way it does here.

## What's in here

| Folder or file    | What it does                                            |
| ----------------- | ------------------------------------------------------- |
| `CLAUDE.md`       | The rules Claude follows on every task                  |
| `output-styles/`  | How Claude talks to me — short, plain words, no jargon  |
| `memory/`         | Notes Claude saved about how I like to work             |
| `skills/`         | My own skills                                           |
| `settings.json`   | Which plugins are on, theme, status line                |
| `statusline.sh`   | The bar at the bottom of the terminal                   |
| `docs/agents/`    | Settings for Matt Pocock's skills — see below           |

## Matt Pocock's skills

I use a set of skills from Matt Pocock. They are workflows Claude follows:
write the test first, hunt a bug down, review a branch, research a question,
grill a plan for holes.

The skills themselves are not in this repo. They install themselves, because
`settings.json` lists them.

What is in this repo is the three settings files they read:

| File                            | What it tells them                        |
| ------------------------------- | ----------------------------------------- |
| `docs/agents/issue-tracker.md`  | My issues live on GitHub                   |
| `docs/agents/triage-labels.md`  | What my five sorting labels are called     |
| `docs/agents/domain.md`         | Where my project notes and decisions go    |

Without those three files the skills have to guess. With them they don't.

## What's deliberately missing

My chat history, my typed commands, and my login details are not here. They
live only on my machine. The `.gitignore` file blocks them.

Plugins are not here either. `settings.json` lists them, so Claude Code
reinstalls them on its own.

## Changing it

Edit the files directly. Nothing generates them.
