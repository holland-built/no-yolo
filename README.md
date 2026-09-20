<h1 align="center">no-yolo</h1>

<p align="center"><strong>Makes Claude stop guessing.</strong></p>

<p align="center">
<a href="LICENSE"><img alt="MIT licence" src="https://img.shields.io/badge/licence-MIT-blue"></a>
<img alt="macOS and Linux" src="https://img.shields.io/badge/macOS%20%7C%20Linux-supported-green">
<img alt="thirteen skills" src="https://img.shields.io/badge/skills-13-8A2BE2">
</p>

Claude Code is an AI that writes code for you in your terminal. Out of the box
it guesses, writes too much, and buries the answer in waffle. These files fix that, and
installing them takes two minutes.

## Install

Needs [Claude Code](https://claude.com/claude-code), Git, Node.js and `jq`, which the status
line reads its values with. macOS or Linux. Windows is not supported.

> [!WARNING]
> Step 2 replaces files in `~/.claude`. A skill of your own with the same name as one here is
> overwritten, and so are `CLAUDE.md`, `settings.json` and `statusline.sh`. Take the backup in
> step 1 first, because there is no undo.

1. **Back up what you have.** The date in the name means a second run never writes into the
   first backup.

   ```bash
   # keep a dated copy of your current setup, in case you want it back
   cp -R ~/.claude ~/.claude-backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null
   ```

2. **Copy the rules, the style and the skills in.** Clone into `~/AI/no-yolo`, because
   `settings.json` looks for the repo's scripts there.

   ```bash
   # download this repo to the path the settings expect, then step into it
   mkdir -p ~/AI && git clone https://github.com/holland-built/no-yolo.git ~/AI/no-yolo && cd ~/AI/no-yolo
   # put the rules, settings and status line where Claude reads them
   mkdir -p ~/.claude/skills ~/.claude/output-styles
   cp CLAUDE.md settings.json statusline.sh ~/.claude/
   # add the skills and the plain speaking style
   cp -R skills/. ~/.claude/skills/
   cp -R output-styles/. ~/.claude/output-styles/
   # let the status line run
   chmod +x ~/.claude/statusline.sh
   ```

3. **Switch on the secret guard.** It refuses any commit holding a password or an API key, in
   every repo on the machine. Without `gitleaks` the guard does nothing, so install that first.

   ```bash
   # the scanner the guard calls. Linux: apk add gitleaks, or apt install gitleaks
   brew install gitleaks
   # if this prints a path, you already have hooks set up: write it down before the next line
   git config --global --get core.hooksPath
   # tell git to run this repo's hooks for every repo on this machine
   git config --global core.hooksPath "$PWD/hooks"
   # let the guard run
   chmod +x hooks/pre-commit
   ```

4. **Add the code checker behind `/slop`.**

   ```bash
   # copy the rules in, then download the linter they run on
   cp -R tools ~/.claude/
   cd ~/.claude/tools/anti-slop && npm install --save-exact oxlint@1.83.0 @oxlint/plugins@1.83.0 && cd -
   ```

5. **Restart Claude Code**, then type `/fix`. It should ask what is broken instead of guessing.

<details>
<summary><strong>Two skills that install from their own repos</strong></summary>

They update themselves, so they are not copied into this repo.

```bash
# makes Claude's writing sound less like an AI wrote it
npx skills add blader/humanizer --global
# draws diagrams of a system
npx skills add tt-a1i/archify --global
```

- [Humanizer](https://github.com/blader/humanizer), MIT, by blader.
- [Archify](https://github.com/tt-a1i/archify), MIT, by tt-a1i.

</details>

<details>
<summary><strong>Codex: a second AI that attacks the plan</strong></summary>

Codex is OpenAI's coding AI. Claude asks it to find holes in a plan before any code is written.
It needs an OpenAI account. **No account? Skip this.** Everything else still works, and Claude
says once that it skipped the Codex checks.

```bash
# install Codex and sign in
npm install -g @openai/codex
codex login
# let Claude call it
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex
```

</details>

<details>
<summary><strong>Firecrawl: let Claude search and read the web</strong></summary>

Get a key at [firecrawl.dev](https://firecrawl.dev), then put it where it says `your-key`.

```bash
# connect the web search tool to Claude
claude mcp add firecrawl -s user -e FIRECRAWL_API_KEY=your-key -- npx -y firecrawl-mcp
```

</details>


## Update

The repo changes. To take the latest, pull and copy again. Nothing is deleted, but a file here
replaces the one on your machine, including a skill of yours that shares a name.

```bash
# from your clone of this repo
git pull
cp CLAUDE.md settings.json statusline.sh ~/.claude/
cp -R skills/. ~/.claude/skills/
cp -R output-styles/. ~/.claude/output-styles/
cp -R tools/anti-slop/src tools/anti-slop/slop.config.ts ~/.claude/tools/anti-slop/
```

The guard needs nothing: it runs from your clone, so `git pull` updates it.

Check what you have matches the repo. Silence means you are up to date.

```bash
# lists any file on this machine that no longer matches the repo
diff -rq skills ~/.claude/skills; diff -q CLAUDE.md ~/.claude/CLAUDE.md
```

<details>
<summary><strong>Uninstall</strong></summary>

This removes the skills by name. A skill of your own that shares a name with one here goes
too, and so do Humanizer, Archify, Codex and Firecrawl even if you installed them yourself.
Your dated backup is the way back.

```bash
# take out the skills this repo installed, leaving your own alone
cd ~/.claude/skills && rm -rf build claude-video fix github-readme grill handoff last-30 map site-design slop writing humanizer archify
rm -rf ~/.agents/skills/humanizer ~/.agents/skills/archify
claude plugin uninstall codex@openai-codex
claude mcp remove firecrawl -s user
rm -f ~/.claude/output-styles/plain.md
rm -f ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/statusline.sh
# take out the code checker
rm -rf ~/.claude/tools/anti-slop
# stop git using the secret guard. Had your own hooks path before? Set it back instead
git config --global --unset core.hooksPath
```

Then put your old config back, naming the backup folder you made in step 1:

```bash
# restore the setup you had before
cp -R ~/.claude-backup-<date>/. ~/.claude/
```

</details>

## The thirteen commands

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
<li><code>/github-readme</code>: tidy a repo and its README for GitHub</li>
</ul>
</td>
<td width="50%" valign="top">
<ul>
<li><code>/writing</code>: you're writing rules for an AI</li>
<li><code>/humanizer</code>: your writing sounds like an AI wrote it</li>
<li><code>/site-design</code>: you need a page designed</li>
<li><code>/slop</code>: check code for the patterns AI writes and humans do not</li>
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
| `skills/` | Eleven of the thirteen commands above. `/humanizer` and `/archify` install from their own repos |
| `output-styles/plain.md` | Makes answers short and plain |
| `memory/` | Notes Claude keeps on how you like to work |
| `settings.json` | Plugins, theme, status line |
| `statusline.sh` | The bar at the bottom |
| `scripts/` | Tidies up stray Codex processes at session start |
| `hooks/` | The pre-commit guard that refuses a commit holding a secret |
| `tools/anti-slop/` | The rules behind `/slop` |

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
# copy this machine's live setup back into the repo, then publish it
cp ~/.claude/CLAUDE.md ~/.claude/statusline.sh .
cp -R ~/.claude/output-styles/. output-styles/
rsync -a --exclude humanizer --exclude archify ~/.claude/skills/ skills/
git add -A && git commit -m "Sync" && git push
```

</details>

## Licence

[MIT](LICENSE). Take it, change it, ship it.
