<h1 align="center">no-yolo</h1>

<p align="center"><strong>Makes Claude stop guessing.</strong></p>

<p align="center">
<a href="LICENSE"><img alt="MIT licence" src="https://img.shields.io/badge/licence-MIT-blue"></a>
<img alt="macOS and Linux" src="https://img.shields.io/badge/macOS%20%7C%20Linux-supported-green">
<img alt="eleven skills" src="https://img.shields.io/badge/skills-11-8A2BE2">
</p>

Claude Code is an AI that writes code for you in your terminal. Out of the box
it guesses, writes too much, and buries the answer in waffle. These files fix that, and
installing them takes two minutes.

## Install

Needs [Claude Code](https://claude.com/claude-code), Git and Node.js. macOS or Linux.

**Back up anything you already have.** This overwrites files in `~/.claude`:

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
```

Then the two skills that come from other people's projects. They update themselves, so they
install from their own repos instead of being copied here:

```bash
npx skills add blader/humanizer --global
npx skills add tt-a1i/archify --global
```

- [Humanizer](https://github.com/blader/humanizer) (MIT, by blader) makes Claude's writing
  sound less like an AI wrote it.
- [Archify](https://github.com/tt-a1i/archify) (MIT, by tt-a1i) draws diagrams of a system.

Then Codex, a second AI from OpenAI that attacks Claude's plans before any code exists. It
needs an OpenAI account. **No account? Skip this block.** Everything else still works; Claude
skips the Codex checks and tells you it did.

```bash
npm install -g @openai/codex
codex login
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex
```

Then Firecrawl, which lets Claude search and read the web. Get a key at
[firecrawl.dev](https://firecrawl.dev) and put it where it says `your-key`:

```bash
claude mcp add firecrawl -s user -e FIRECRAWL_API_KEY=your-key -- npx -y firecrawl-mcp
```

Windows is not supported.

Restart Claude Code. You should see a status bar along the bottom. Try:

```
/fix
```

Claude should ask you what's broken instead of guessing.

<details>
<summary><strong>Uninstall</strong></summary>

Removes only what this repo installed. Your own skills stay.

```bash
cd ~/.claude/skills && rm -rf build claude-video fix grill handoff last-30 map site-design writing humanizer archify
rm -rf ~/.agents/skills/humanizer ~/.agents/skills/archify
claude plugin uninstall codex@openai-codex
claude mcp remove firecrawl -s user
rm -f ~/.claude/output-styles/plain.md
rm -f ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/statusline.sh
```

Then put your old config back, if you took the backup:

```bash
cp -R ~/.claude-backup/. ~/.claude/
```

</details>

## The eleven commands

Type the slash command, or just say the word. Both work.

<table>
<tr>
<td width="50%" valign="top">
<ul>
<li><code>/build</code>: you want something new made</li>
<li><code>/fix</code>: something is broken or slow</li>
<li><code>/grill</code>: you want your plan attacked</li>
<li><code>/map</code>: the job is too big to see</li>
<li><code>/handoff</code>: you're stopping halfway</li>
</ul>
</td>
<td width="50%" valign="top">
<ul>
<li><code>/writing</code>: you're writing rules for an AI</li>
<li><code>/humanizer</code>: your writing sounds like an AI wrote it</li>
<li><code>/site-design</code>: you need a page designed</li>
<li><code>/last-30</code>: what changed lately</li>
<li><code>/claude-video</code>: summarise a YouTube video</li>
<li><code>/archify</code>: draw a diagram of a system</li>
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
it working.</p>

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

<p>Claude argues with you on purpose, so the holes turn up now instead of three weeks in.</p>

</td>
</tr>
</table>

**Running out of time?** `/handoff` writes down where you got to, so tomorrow
you don't re-explain anything.

## What's in here

| File | What it does |
| --- | --- |
| `CLAUDE.md` | Rules Claude follows on every task |
| `skills/` | Nine of the eleven commands above. `/humanizer` and `/archify` install from their own repos |
| `output-styles/plain.md` | Makes answers short and plain |
| `memory/` | Notes Claude keeps on how you like to work |
| `settings.json` | Plugins, theme, status line |
| `statusline.sh` | The bar at the bottom |
| `scripts/` | Tidies up stray Codex processes at session start |

## How it talks to you

`output-styles/plain.md` caps every reply. Normal answer: six sentences. If you
asked it to explain something: twelve. Bullets and table rows count as one each.
Over the cap, it cuts what you don't need first. It would rather run long than
leave out a step you need. Steps you have to follow in order don't count.

It also skips announcing what it's about to do and offering things you didn't ask for. It
drops reflex hedging but still tells you when it has a real doubt.

<table>
<tr>
<td width="50%" valign="top">
<h4>Without this</h4>
<p><em>"Great question! Let me take a look at your configuration files to
understand the current setup. I'll start by examining the settings and then
walk through the various options available to you. There are a few different
approaches we could take here, each with their own tradeoffs…"</em></p>
</td>
<td width="50%" valign="top">
<h4>With this</h4>
<p><em>"Your status line file is not executable. That is why the bar is
missing. One line fixes it:"</em></p>
<p><code>chmod +x ~/.claude/statusline.sh</code></p>
</td>
</tr>
</table>

Four things it will never shorten: commands, file paths, error text, and any
warning about deleting or overwriting your data.

The rule underneath all of it: when you say <em>"wait, what?"</em>, it writes
the answer you would have needed anyway, first time.

## The rules it follows

`CLAUDE.md` is seven short sections. What each one actually stops:

| Rule | What it stops |
| --- | --- |
| **Think before coding** | Guessing what you meant. If your request could mean two different things, it shows you both before building either. |
| **Simplicity first** | Features you did not ask for, wrappers around one call, settings nobody requested, handling for cases that cannot happen. |
| **Surgical changes** | Tidying code next to the thing you asked about. It matches the style already there, even style it would do differently. |
| **Goal-driven execution** | "Make it work" as a finish line. It says up front what test or command will prove it, then runs that check. |
| **Never idle** | Sitting waiting. Blocked on one thing, it finishes everything that does not depend on it, then reports. |
| **Confer with Codex** | Trusting its own plan. Before anything expensive, a second AI attacks the plan first. |
| **Read before describing** | Describing your setup from memory. It opens the file first. |

Two rounds, then it decides: one critique from Codex, one revision, one
re-check. If they still disagree it picks and tells you what it overrode in one
line.

<details>
<summary><strong>For me: syncing my machine back to this repo</strong></summary>

```bash
cp ~/.claude/CLAUDE.md ~/.claude/statusline.sh .
cp -R ~/.claude/output-styles/. output-styles/
rsync -a --exclude humanizer --exclude archify ~/.claude/skills/ skills/
git add -A && git commit -m "Sync" && git push
```

</details>

## Licence

[MIT](LICENSE). Take it, change it, ship it.
