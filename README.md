<h1 align="center">no-yolo</h1>

<p align="center"><strong>Makes Claude stop guessing.</strong></p>

<p align="center">
<a href="LICENSE"><img alt="MIT licence" src="https://img.shields.io/badge/licence-MIT-blue"></a>
<img alt="macOS and Linux" src="https://img.shields.io/badge/macOS%20%7C%20Linux-supported-green">
<img alt="ten skills" src="https://img.shields.io/badge/skills-10-8A2BE2">
</p>

Claude Code is an AI that writes code for you in your terminal. Out of the box
it guesses, writes too much, and buries the answer in waffle.

These files fix that. Install takes two minutes.

## Install

Needs [Claude Code](https://claude.com/claude-code) and Git. macOS or Linux.

**Back up anything you already have** — this overwrites `~/.claude` files:

```bash
cp -R ~/.claude ~/.claude-backup 2>/dev/null
```

Then:

```bash
git clone https://github.com/holland-built/no-yolo.git
cd no-yolo
mkdir -p ~/.claude
cp CLAUDE.md settings.json statusline.sh ~/.claude/
mkdir -p ~/.claude/skills ~/.claude/output-styles
cp -R skills/. ~/.claude/skills/
cp -R output-styles/. ~/.claude/output-styles/
chmod +x ~/.claude/statusline.sh
sed -i '' "s|/Users/sholland/.claude|$HOME/.claude|" ~/.claude/settings.json
```

Linux: drop the `''` after `-i`. Windows is not supported.

Restart Claude Code. **You should now see** a status bar along the bottom. Try:

```
/fix
```

Claude should ask you what's broken instead of guessing.

<details>
<summary><strong>Optional: add a second AI that checks Claude's work</strong></summary>

Codex is OpenAI's model. Some skills ask it to attack a plan before any code exists.

```bash
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex
```

</details>

<details>
<summary><strong>Optional: add <code>/archify</code>, the diagram drawer</strong></summary>

It is someone else's project and it updates itself, so it is not copied into this
repo. Install it straight from the source:

```bash
git clone https://github.com/tt-a1i/archify.git ~/.claude/skills/archify
```

MIT, by tt-a1i.

</details>

<details>
<summary><strong>Uninstall</strong></summary>

Removes only what this repo installed. Your own skills stay.

```bash
cd ~/.claude/skills && rm -rf build claude-video fix grill handoff last-30 map site-design writing
rm -f ~/.claude/output-styles/plain.md
rm -f ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/statusline.sh
```

Then put your old config back, if you took the backup:

```bash
cp -R ~/.claude-backup/. ~/.claude/
```

</details>

## The ten commands

Type the slash command. Or just say the word — both work.

<table>
<tr>
<td width="50%" valign="top">
<ul>
<li><code>/build</code> — you want something new made</li>
<li><code>/fix</code> — something is broken or slow</li>
<li><code>/grill</code> — you want your plan attacked</li>
<li><code>/map</code> — the job is too big to see</li>
<li><code>/handoff</code> — you're stopping halfway</li>
</ul>
</td>
<td width="50%" valign="top">
<ul>
<li><code>/writing</code> — you're writing rules for an AI</li>
<li><code>/site-design</code> — you need a page designed</li>
<li><code>/last-30</code> — what changed lately</li>
<li><code>/claude-video</code> — summarise a YouTube video</li>
<li><code>/archify</code> — draw a diagram of a system</li>
</ul>
</td>
</tr>
</table>

## Workflows

<table>
<tr>
<td width="50%" valign="top">

<h3>Make a website</h3>

<p><code>/site-design a landing page for a bakery</code></p>

<p>Claude builds three versions and shows them side by side. Pick one.</p>

<p><code>/build it, using version 2</code></p>

</td>
<td width="50%" valign="top">

<h3>Fix something broken</h3>

<p><code>/fix the login page throws a 500</code></p>

<p>Claude reproduces the error first, shows you the cause, fixes it, then shows
it working. No guessing.</p>

</td>
</tr>
<tr>
<td width="50%" valign="top">

<h3>A job too big to start</h3>

<p><code>/map I want to rebuild this whole app</code></p>

<p>Claude writes the decisions down one at a time instead of charging in. Then
build them one by one.</p>

</td>
<td width="50%" valign="top">

<h3>Before something expensive</h3>

<p><code>/grill I'm rewriting the API in Go</code></p>

<p>Claude argues with you on purpose. Better now than after three weeks.</p>

</td>
</tr>
</table>

**Running out of time?** `/handoff` writes down where you got to, so tomorrow
you don't re-explain anything.

## What's in here

| File | What it does |
| --- | --- |
| `CLAUDE.md` | Rules Claude follows on every task |
| `skills/` | Nine of the ten commands above |
| `output-styles/plain.md` | Makes answers short and plain |
| `memory/` | Notes Claude keeps on how I like to work |
| `settings.json` | Plugins, theme, status line |
| `statusline.sh` | The bar at the bottom |
| `scripts/` | Tidies up stray Codex processes at session start |

**The rules, in one line each:** think before coding · write the least code that
works · change only what was asked · decide up front how you'll know it worked ·
don't sit idle when blocked · get a second opinion before anything expensive.

**The Plain style, in one line:** when I say "wait, what?", Claude's next answer
is the right one.

<details>
<summary><strong>For me: syncing my machine back to this repo</strong></summary>

```bash
cp ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/statusline.sh .
cp -R ~/.claude/output-styles/. output-styles/
cp -R ~/.claude/skills/. skills/
git add -A && git commit -m "Sync" && git push
```

</details>

## Licence

[MIT](LICENSE). Take it, change it, ship it.
