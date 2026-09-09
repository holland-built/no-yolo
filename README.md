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
| `docs/agents/`    | Where issues live, and what the triage labels are       |

## What's deliberately missing

My chat history, my typed commands, and my login details are not here. They
live only on my machine. The `.gitignore` file blocks them.

Plugins are not here either. `settings.json` lists them, so Claude Code
reinstalls them on its own.

## Changing it

Edit the files directly. Nothing generates them.
