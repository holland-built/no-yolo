# Looking after your copy

Read when you want a second account, when the original repo has moved on, or when you want to
know what the line at the bottom of the screen is telling you.

Nothing here is needed to install. `README.md` covers that, and it is finished in three
commands.

## Running two accounts from one setup

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
other. Link it, don't copy it. Anything you genuinely want to differ per account (a pinned
model, an extra plugin) belongs in `~/.claude/settings.json` for both, or in neither. What a
copied `settings.json` cost on 2026-08-05 is in `docs/DECISIONS.md`.

Because `settings.json` is gitignored, cloning this repo cannot recreate those links for you.
That is why they are written down here.

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

## The status bar

The line at the bottom of Claude Code. Example:

`Opus 5 · 42%ctx · 5h 18% 3h · wk 40% 5d · no-yolo* · ⬢ prod`

| Piece | What it means |
|---|---|
| `Opus 5` | which model you are talking to |
| `42%ctx` | how full Claude's memory of this conversation is. Over 60%, type `/compact` |
| `5h 18% 3h` | you have used 18% of your 5-hour allowance; it resets in 3 hours |
| `wk 40% 5d` | 40% of your 7-day allowance used; it resets in 5 days |
| `no-yolo*` | the folder you are in. The `*` means you have changes not yet saved to git |

It is drawn by `hooks/statusline.sh`. When literal mode is on, a badge for it appears at the
front.

**Literal mode** is the one thing you can type that is not one of the skills listed in
`README.md`. Type `/literal` and Claude stops offering alternatives and does exactly what you
asked; `/literal off` ends it, and so does starting a new session. It is not a skill, which is
why it has no row in that table: `hooks/literal-mode-tracker.js` reads what you typed and sets
a flag the status bar shows.
