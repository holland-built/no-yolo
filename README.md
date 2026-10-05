<h1 align="center">no-yolo</h1>

<p align="center"><strong>Makes Claude stop guessing.</strong></p>

<p align="center">
<a href="LICENSE"><img alt="MIT licence" src="https://img.shields.io/badge/licence-MIT-blue"></a>
<img alt="macOS and Linux" src="https://img.shields.io/badge/macOS%20%7C%20Linux-supported-green">
<img alt="seventeen skills" src="https://img.shields.io/badge/skills-17-8A2BE2">
</p>

Claude Code is an AI that writes code for you in your terminal. Out of the box it guesses
what you meant and pads its answers. These files make it ask first and answer short. Installing
them takes two minutes.

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

**Jump to:** [Install](#install) · [Commands](#the-seventeen-commands) · [Workflows](#workflows) · [Rules](#the-rules-it-follows) · [Update](#update)

## Install

Needs [Claude Code](https://claude.com/claude-code), Git, Node.js and `jq`, which the status
line reads its values with. macOS or Linux. Windows is not supported.

The script copies the rules, the style and the skills into `~/.claude`, installs `gitleaks`,
switches the secret guard on, and downloads the linter behind `/slop`. It backs up whatever
you already have before it copies anything, and it tells you what it did at each step. If git
on this machine already has a hooks folder of its own, it leaves that alone and prints the one
line to run instead.

```bash
# download this repo to the path the settings expect
mkdir -p ~/AI && git clone https://github.com/holland-built/no-yolo.git ~/AI/no-yolo
# set everything up on this machine
~/AI/no-yolo/install.sh
```

Then **restart Claude Code** and type `/fix`. It should ask what is broken instead of guessing.

**Rather have an AI do it?** Paste this into Claude Code, or any coding agent that can run
commands. It does the same steps and adds the five skills from other repos.

```text
Install no-yolo on this machine. Clone https://github.com/holland-built/no-yolo.git to
~/AI/no-yolo. If that folder already exists, check that its origin is that URL and that git
status is clean; if either is not true, stop and tell me. Otherwise git pull. Read its README,
then run ~/AI/no-yolo/install.sh. Then install the five third-party skills with these commands:
npx -y skills add blader/humanizer -g -y && npx -y skills add tt-a1i/archify --skill archify -g -y && npx -y skills add vercel-labs/skills --skill find-skills -g -y && npx -y skills add ayghri/i-have-adhd --skill i-have-adhd -g -y && npx -y skills add anthropics/skills --skill frontend-design -g -y
Do not change anything else. When it is done, tell me what the install script backed up,
what it installed, and anything that failed, then remind me to restart Claude Code.
```

> [!WARNING]
> The script replaces files in `~/.claude`. A skill of your own with the same name as one here
> is overwritten, and so are `CLAUDE.md`, `settings.json` and `statusline.sh`. The dated backup
> folder it writes first is the only way back.
>
> The secret guard also stops any hook of your own in a repo's `.git/hooks` from running,
> because git uses one hooks folder at a time for the whole machine. Undo that with
> `git config --global --unset core.hooksPath`.
>
> The settings also let Claude work on GitHub without asking you first. It can open and merge
> pull requests, watch CI runs, make releases, tag, and push. The rules tell it that a job is
> only done once the pull request is merged and released. It still asks before a force push or
> before deleting a repo or a release. To be asked each time, move the `gh` and `git` lines from
> `allow` to `ask` in `~/.claude/settings.json`. Running `install.sh` again puts them back, so
> redo this after each update.

<details>
<summary><strong>Do the same by hand instead</strong></summary>

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

</details>

<details>
<summary><strong>Five skills that install from their own repos</strong></summary>

They update themselves, so they are not copied into this repo.

All five in one line, with no questions asked:

```bash
# install humanizer, archify, find-skills, i-have-adhd and frontend-design from their own repos
npx -y skills add blader/humanizer -g -y && npx -y skills add tt-a1i/archify --skill archify -g -y && npx -y skills add vercel-labs/skills --skill find-skills -g -y && npx -y skills add ayghri/i-have-adhd --skill i-have-adhd -g -y && npx -y skills add anthropics/skills --skill frontend-design -g -y
```

Or one at a time:

```bash
# makes Claude's writing sound less like an AI wrote it
npx skills add blader/humanizer --global
# draws diagrams of a system
npx skills add tt-a1i/archify --skill archify --global
# finds and installs skills other people have made
npx skills add vercel-labs/skills --skill find-skills --global
# shapes replies for a reader with ADHD; type /i-have-adhd to switch it on
npx skills add ayghri/i-have-adhd --skill i-have-adhd --global
# gives pages and screens a deliberate look instead of a template one
npx skills add anthropics/skills --skill frontend-design --global
```

To take their newest versions later:

```bash
# update the five skills installed from someone else's repo
npx skills update -g
```

- [Humanizer](https://github.com/blader/humanizer), MIT, by blader.
- [Archify](https://github.com/tt-a1i/archify), MIT, by tt-a1i.
- [find-skills](https://github.com/vercel-labs/skills), by Vercel Labs.
- [i-have-adhd](https://github.com/ayghri/i-have-adhd), MIT, by ayghri.
- [frontend-design](https://github.com/anthropics/skills), by Anthropic.

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

With several Claude Code windows open, signing in to Codex from one window can break Codex in
the others with `401 Unauthorized`, because each window's Codex server keeps its own copy of the
sign-in and does not notice a new one
([openai/codex-plugin-cc#281](https://github.com/openai/codex-plugin-cc/issues/281)). Add
this to `~/.zshrc` and sign in with `codex-relogin` instead of `codex login`:

```bash
# sign Codex in, then stop the plugin's Codex servers; each window starts a fresh one that reads the new sign-in
codex-relogin() {
  codex login || return
  pkill -f 'plugins/cache/openai-codex/.*/app-server-broker\.mjs'
  case $? in
    0) echo "Stopped the plugin's Codex servers. Each window starts a fresh one on its next Codex call." ;;
    1) echo "No plugin Codex servers were running." ;;
    *) echo "Could not stop the plugin's Codex servers." >&2; return 1 ;;
  esac
}
```

A Codex review running in another window at that moment stops. The next one starts normally.

</details>

<details>
<summary><strong>Jev: a tiebreaker when two AIs disagree</strong></summary>

Jev is a small AI model from [TypeSafe](https://typesafe.ai) that picks between options. When
Codex and Claude disagree, `/jev-judge` asks Jev to compare their claims, one criterion at a
time, and shows you the table. `/build` uses it when Codex and an Opus helper (Opus is another
Claude model) propose different approaches: you approve the criteria and mark the must-haves,
and Jev gives advice. Claude says which way it is going before it writes any code, and you can
switch it at any point. When Jev is not sure, it asks you. It does not judge whether code works,
because tests do that.

Three more places use Jev as an optional helper. `/build` runs a safety check on the chosen
approach: it asks Jev whether the approach fails a must-have or would delete data, publish
something or spend money, and sends it to you if so. `/last-30` can rank changelog entries so only
the relevant ones are read in full. `/claude-video` can suggest which topic pages in your notes
vault a video bears on. Each skips itself when no key is saved.

It needs Python 3 and a TypeSafe account. Each judgement costs a fraction of a cent at TypeSafe's
listed price. **No account? Skip this.** Everything else still works, and `/build` shows you both
approaches and waits for you.

> [!WARNING]
> The criteria and claims are sent to TypeSafe. Keep passwords and private details out of them.

1. **Get a key.** Sign up at [console.typesafe.ai](https://console.typesafe.ai), then copy a key
   from the [keys page](https://console.typesafe.ai/keys).

2. **Save the key where the skill looks.** Paste the line below, then paste your key when it
   asks. Nothing shows as you type, so the key stays out of your screen and your shell history.

   ```bash
   # ask for your key and save it in a file only you can read
   mkdir -p ~/.config/typesafe && chmod 700 ~/.config/typesafe && printf 'TypeSafe key: ' && IFS= read -rs k && printf '\n' && [ -n "$k" ] && (umask 077; printf '%s' "$k" > ~/.config/typesafe/key); unset k
   ```

3. **Check the skill's own tests pass.** They need no internet connection.

   ```bash
   # run the skill's checks
   cd ~/.claude/skills/jev-judge && python3 -m unittest
   ```

If a call fails, the skill prints `Jev: couldn't tell` and the reason, and Claude asks you instead.

</details>

<details>
<summary><strong>TypeScript checker: catch broken code as Claude writes it</strong></summary>

Lets Claude spot errors in JavaScript and TypeScript files (`.js`, `.jsx`, `.ts`, `.tsx`) while it
works, before you run anything. Claude Code offers it on its own the first time it opens one
of those files.

```bash
# install the language server the plugin talks to
npm install -g typescript-language-server typescript
# install the plugin from Anthropic's official list
claude plugin install typescript-lsp@claude-plugins-official
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

Run the same script again to take a newer version of this repo. Nothing is deleted, but a file
here replaces the one on your machine, including a skill of yours that shares a name.

```bash
# take the latest version of this repo
cd ~/AI/no-yolo && git pull
# apply it to this machine
./install.sh
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
too, and so do Humanizer, Archify, find-skills, i-have-adhd, frontend-design,
Codex, the TypeScript checker and Firecrawl, even if you installed them yourself. Your dated
backup is the way back.

```bash
# take out the skills this repo installed, leaving your own alone
cd ~/.claude/skills && rm -rf build claude-video fix github-readme grill handoff jev-judge last-30 map site-design slop writing humanizer archify find-skills i-have-adhd frontend-design
# take out the copies the third-party skills install from
rm -rf ~/.agents/skills/humanizer ~/.agents/skills/archify ~/.agents/skills/find-skills ~/.agents/skills/i-have-adhd ~/.agents/skills/frontend-design
# remove the Codex plugin
claude plugin uninstall codex@openai-codex
# remove the TypeScript checker plugin
claude plugin uninstall typescript-lsp@claude-plugins-official
# disconnect the web search tool
claude mcp remove firecrawl -s user
# delete the plain speaking style
rm -f ~/.claude/output-styles/plain.md
# delete the rules, settings and status line
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

The uninstall leaves your TypeSafe key alone, because other tools can use it. Delete
`~/.config/typesafe/key` yourself if you no longer want it.

</details>

## The seventeen commands

Type the slash command, or just say the word. Both work.

<table>
<tr>
<td width="50%" valign="top">
<ul>
<li><code>/build</code>: you want something new made</li>
<li><code>/fix</code>: something is broken or slow</li>
<li><code>/grill</code>: you want your plan attacked</li>
<li><code>/jev-judge</code>: Claude and Codex disagree and you want a tiebreaker</li>
<li><code>/map</code>: the job is too big to see</li>
<li><code>/handoff</code>: you're stopping halfway</li>
<li><code>/github-readme</code>: tidy a repo and its README for GitHub</li>
<li><code>/find-skills</code>: find a skill someone else has made</li>
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
<li><code>/i-have-adhd</code>: replies shaped for an ADHD reader</li>
<li><code>/frontend-design</code>: give a page a deliberate look</li>
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
| `skills/` | Twelve of the seventeen commands above. `/humanizer`, `/archify`, `/find-skills`, `/i-have-adhd` and `/frontend-design` install from their own repos |
| `output-styles/plain.md` | Makes answers short and plain, next step first |
| `memory/` | Notes Claude keeps on how you like to work |
| `settings.json` | Plugins, theme, status line, and merging pull requests without asking |
| `statusline.sh` | The bar at the bottom |
| `install.sh` | Sets this repo up on a machine, or updates one that already has it |
| `scripts/` | Tidies up stray Codex processes at session start |
| `hooks/` | The pre-commit guard that refuses a commit holding a secret |
| `tools/anti-slop/` | The rules behind `/slop` |

## How it talks to you

`output-styles/plain.md` caps every reply. Normal answer: six sentences. If you
asked it to explain something: twelve. Bullets and table rows count as one each.
Over the cap, it cuts what you don't need first. It would rather run long than
leave out a step you need. Steps you have to follow in order don't count.

The first line is the answer, or the one thing you can do next. When you have a choice to
make, it ranks the options, puts its pick first, and gives each one a real time: "10 minutes",
"an afternoon". On a long job it opens each progress update with where things stand
("step 3 of 5 done"), so you don't have to keep track.

It skips offering things you didn't ask for. It drops reflex hedging but still tells you when
it has a real doubt.


Four things it will never shorten: commands, file paths, error text, and any
warning about deleting or overwriting your data.

When you say <em>"wait, what?"</em>, the next answer should be the one you needed the first
time.

## The rules it follows

`CLAUDE.md` is eight short sections. What each one actually stops:

| Rule | What it stops |
| --- | --- |
| **Think before coding** | Guessing what you meant. If your request could mean two different things, it shows you both before building either. |
| **Simplicity first** | Features you did not ask for, wrappers around one call, settings nobody requested, handling for cases that cannot happen. |
| **Surgical changes** | Tidying code next to the thing you asked about. It matches the style already there, even style it would do differently. |
| **Goal-driven execution** | "Make it work" as a finish line. It says up front what test or command will prove it, then runs that check. |
| **Never idle** | Sitting waiting. Blocked on one thing, it finishes everything that does not depend on it, then reports. |
| **Confer with Codex** | Trusting its own plan. Before anything expensive, a second AI attacks the plan first. |
| **Read before describing** | Describing your setup from memory. It opens the file first. |
| **Design rules** | Pages that all look alike: cream backgrounds, pill buttons, one italic word in the headline. PowerPoint keeps its template, and every edit gets a backup first. |

Two rounds, then it decides: one critique from Codex, one revision, one
re-check. If they still disagree it picks and tells you what it overrode in one
line. When tests cannot settle the question, it can ask Jev for a tiebreaker instead of picking
alone. Jev's pick is advice, and you can override it.

<details>
<summary><strong>For me: syncing my machine back to this repo</strong></summary>

On my machine a git `post-commit` hook does this after every commit in `~/.claude`. It copies from the
last commit, so unfinished edits never ship, and it stops without pushing if a check fails: a name, home
path, pronoun, e-mail or address on an added line, a secret, a path it did not expect, or more than 5
deleted files. The manual steps below do the same without the checks.

```bash
# copy the rules and the status line from this machine into the repo
cp ~/.claude/CLAUDE.md ~/.claude/statusline.sh .
# copy the plain speaking style
cp -R ~/.claude/output-styles/. output-styles/
# copy the skills, leaving out third-party skills, personal skills, test cases and the sync folder
rsync -a --exclude humanizer --exclude archify --exclude find-skills --exclude i-have-adhd --exclude frontend-design --exclude tasks --exclude model-update --exclude synced --exclude evals --exclude .claude-plugin --exclude __pycache__ ~/.claude/skills/ skills/
# publish it
git add -A && git commit -m "Sync" && git push
```

</details>

## Licence

[MIT](LICENSE). Use it however you like, as long as the licence notice stays with it.
