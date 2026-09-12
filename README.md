# no-yolo

Makes Claude stop guessing.

Claude Code is an AI that writes code for you in your terminal. Out of the box it
guesses, writes too much, and buries the answer in waffle. These files fix that.

Install takes two minutes.

## Install

Need Claude Code first: https://claude.com/claude-code

```bash
git clone https://github.com/holland-built/no-yolo.git
cd no-yolo
mkdir -p ~/.claude
cp CLAUDE.md settings.json statusline.sh ~/.claude/
cp -R skills output-styles ~/.claude/
chmod +x ~/.claude/statusline.sh
sed -i '' "s|/Users/sholland/.claude|$HOME/.claude|" ~/.claude/settings.json
```

Linux: drop the `''` after `-i`.

Restart Claude Code. Done.

Optional — a second AI (OpenAI's Codex) that checks Claude's work:

```bash
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex
```

## The nine commands

Type the slash command. Or just say the word — both work.

| Command | Use it when |
| --- | --- |
| `/build` | You want something new made |
| `/fix` | Something is broken or slow |
| `/grill` | You want your plan attacked |
| `/map` | The job is too big to see |
| `/handoff` | You're stopping halfway |
| `/writing` | You're writing rules for an AI |
| `/site-design` | You need a page designed |
| `/last-30` | You want to know what changed lately |
| `/claude-video` | You want a YouTube video summarised |

## Workflows

**Make a website**

```
/site-design a landing page for my bakery
```
Claude builds three versions and shows them side by side. Pick one.
```
/build it, using version 2
```

**Fix something broken**

```
/fix the login page throws a 500 when I submit
```
Claude reproduces the error first, shows you the cause, fixes it, shows it working.

**Big scary job**

```
/map I want to rebuild this whole app
```
Claude writes the decisions down one at a time instead of charging in. Then:
```
/build step 1
```

**Before you commit to something expensive**

```
/grill I'm going to rewrite the API in Go
```
Claude argues with you on purpose. Better now than after three weeks.

**Running out of time**

```
/handoff
```
Writes down where you got to, so tomorrow you don't re-explain anything.

## What's in here

| File | What it does |
| --- | --- |
| `CLAUDE.md` | Rules Claude follows on every task |
| `skills/` | The nine commands above |
| `output-styles/plain.md` | Makes answers short and plain |
| `memory/` | Notes on how I like to work |
| `settings.json` | Plugins, theme, status line |
| `statusline.sh` | The bar at the bottom |
| `scripts/` | Small helpers |

**The rules, in one line each:** think before coding · write the least code that
works · change only what was asked · decide up front how you'll know it worked ·
don't sit idle when blocked · get a second opinion before anything expensive.

**The Plain style, in one line:** when I say "wait, what?", Claude's next answer
is the right one.

## Not in here

Your chat history and logins stay on your machine. `.gitignore` blocks them.

## Updating

```bash
cp ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/statusline.sh .
cp -R ~/.claude/output-styles ~/.claude/skills .
git add -A && git commit -m "Sync" && git push
```

## Licence

No licence file yet. Take them, change them. Add a licence before redistributing.
