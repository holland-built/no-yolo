<h1 align="center">no-yolo</h1>

<p align="center"><strong>Makes Claude stop guessing.</strong></p>

<p align="center">
<a href="LICENSE"><img alt="MIT licence" src="https://img.shields.io/badge/licence-MIT-blue"></a>
<img alt="macOS and Linux" src="https://img.shields.io/badge/macOS%20%7C%20Linux-supported-green">
<img alt="twenty commands" src="https://img.shields.io/badge/commands-20-8A2BE2">
<a href="https://github.com/holland-built/no-yolo/releases"><img alt="latest release" src="https://img.shields.io/github/v/release/holland-built/no-yolo"></a>
<img alt="last commit" src="https://img.shields.io/github/last-commit/holland-built/no-yolo">
</p>

Claude Code is an AI that writes code for you in your terminal. Out of the box it guesses
what you meant, pads its answers and marks its own homework. These files make it ask first, answer
short, and have a second AI check costly work before it is built, when mistakes are cheapest to fix.
Installing them takes two minutes.

| Without this | With this |
|---|---|
| *"Great question! Let me take a look at your configuration files to understand the current setup. I'll start by examining the settings and then walk through the various options available to you. There are a few different approaches we could take here, each with their own tradeoffs…"* | *"Your status line file is not executable. That is why the bar is missing. One line fixes it:"* `chmod +x ~/.claude/statusline.sh` |

**Jump to:** [Install](#install) · [Commands](#the-twenty-commands) · [Workflows](#workflows) · [Rules](#the-rules-it-follows) · [Update](#update)

## Install

Needs [Claude Code](https://claude.com/claude-code), Git, Node.js and `jq`, which the status
line reads its values with. macOS or Linux. Windows is not supported.

The script copies the rules, the style and the skills into `~/.claude`, installs `gitleaks` and
`exiftool`, and switches the secret guard on. It backs up whatever
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
commands. It does the same steps and adds the twelve skills from other repos.

```text
Install no-yolo on this machine. Clone https://github.com/holland-built/no-yolo.git to
~/AI/no-yolo. If that folder already exists, check that its origin is that URL and that git
status is clean; if either is not true, stop and tell me. Otherwise git pull. Read its README,
then run ~/AI/no-yolo/install.sh. Then install the twelve third-party skills by running the
install-everything command under "Twelve skills that install from their own repos" in that README.
Do not change anything else. When it is done, tell me what the install script backed up,
what it installed, and anything that failed, then remind me to restart Claude Code.
```

> [!WARNING]
> The script replaces files in `~/.claude`. A skill of your own with the same name as one here
> is overwritten, and so are `CLAUDE.md`, `settings.json` and `statusline.sh`. The dated backup
> folder it writes first is the only way back.
>
> If Codex is installed, `~/.codex/AGENTS.md` is replaced too. The old one is kept beside it with
> the date in its name.
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
   # make the folders Claude reads from
   mkdir -p ~/.claude/skills ~/.claude/output-styles ~/.claude/shared
   # put the rules, settings and status line where Claude reads them
   cp CLAUDE.md settings.json statusline.sh ~/.claude/
   # add the skills
   cp -R skills/. ~/.claude/skills/
   # add the Action First reply style
   cp -R output-styles/. ~/.claude/output-styles/
   # copy the rules Claude and Codex share, which CLAUDE.md reads in
   cp -R shared/. ~/.claude/shared/
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
   # lets /github-readme strip hidden data from screenshots. Linux: apt install libimage-exiftool-perl
   brew install exiftool
   ```

4. **Restart Claude Code**, then type `/fix`. It should ask what is broken instead of guessing.

</details>

<details>
<summary><strong>Twelve skills that install from their own repos</strong></summary>

They update themselves, so they are not copied into this repo.

All twelve, with no questions asked:

```bash
# install humanizer, archify, find-skills and frontend-design from their own repos
npx -y skills add blader/humanizer -g -y && npx -y skills add tt-a1i/archify --skill archify -g -y && npx -y skills add vercel-labs/skills --skill find-skills -g -y && npx -y skills add anthropics/skills --skill frontend-design -g -y
# install ui-demo, which /demo-voiceover builds on
npx -y skills add affaan-m/ecc --skill ui-demo -g -y
# install the seven design checklists that /improve uses
npx -y skills add jakubkrehel/skills --skill better-interface -g -y && npx -y skills add jakubkrehel/skills --skill better-accessibility -g -y && npx -y skills add jakubkrehel/skills --skill better-layout -g -y && npx -y skills add jakubkrehel/skills --skill better-writing -g -y && npx -y skills add jakubkrehel/skills --skill better-typography -g -y && npx -y skills add jakubkrehel/skills --skill better-colors -g -y && npx -y skills add jakubkrehel/skills --skill better-ui -g -y
```

What each one does:

| Skill | What it does | Made by |
|---|---|---|
| `humanizer` | Makes Claude's writing sound less like an AI wrote it | [blader](https://github.com/blader/humanizer), MIT |
| `archify` | Draws diagrams of a system | [tt-a1i](https://github.com/tt-a1i/archify), MIT |
| `find-skills` | Finds and installs skills other people have made | [Vercel Labs](https://github.com/vercel-labs/skills) |
| `frontend-design` | Gives pages and screens a deliberate look instead of a template one | [Anthropic](https://github.com/anthropics/skills) |
| `ui-demo` | Records demo videos of a web app; `/demo-voiceover` adds narration | [affaan-m](https://github.com/affaan-m/ecc) |
| `better-interface` | The ranked review `/improve` runs when you say "make it better" | [jakubkrehel](https://github.com/jakubkrehel/skills), MIT |
| `better-accessibility` | Checks keyboard use, screen readers and contrast | jakubkrehel, MIT |
| `better-layout` | Checks grouping, alignment and how a page resizes | jakubkrehel, MIT |
| `better-writing` | Checks button labels, error messages and empty screens | jakubkrehel, MIT |
| `better-typography` | Checks text sizes, spacing and wrapping | jakubkrehel, MIT |
| `better-colors` | Checks color palettes and contrast | jakubkrehel, MIT |
| `better-ui` | Checks corners, shadows, icons and motion | jakubkrehel, MIT |

To install only some of them, copy just their `npx -y skills add ...` parts from the command above.

To take their newest versions later:

```bash
# update the twelve skills installed from someone else's repo
npx skills update -g
```

`/skill-audit` lists which of them are behind before you run this.

</details>

<details>
<summary><strong>Codex: a second AI that attacks the plan</strong></summary>

Codex is OpenAI's coding AI. Claude asks it to find holes in a plan before any code is written.
It needs an OpenAI account. **No account? Skip this.** Everything else still works, and Claude
says once that it skipped the Codex checks.

```bash
# install Codex
npm install -g @openai/codex
# sign in to Codex
codex login
# tell Claude where to find the Codex plugin
claude plugin marketplace add openai/codex-plugin-cc
# let Claude call Codex
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

> [!WARNING]
> Uninstall removes skills by name. A skill of your own that shares a name with one here goes
> too, and so do Humanizer, Archify, find-skills, frontend-design, ui-demo, the seven
> `better-*` checklists, Codex, the TypeScript checker and Firecrawl, even if you installed them
> yourself. It also clears `jev-judge` and `i-have-adhd`, which older versions of this repo
> installed. Your dated backup brings back `~/.claude`. Skills from other repos live in
> `~/.agents/skills`, which the backup does not cover, so reinstall those with the commands above.

<details>
<summary><strong>Uninstall</strong></summary>

```bash
# take out the skills this repo installed, by name
cd ~/.claude/skills && rm -rf better build claude-video demo-voiceover fix github-readme write-doc handoff improve jev-judge last-30 resume short site-design skill-audit writing humanizer archify find-skills i-have-adhd frontend-design ui-demo better-interface better-accessibility better-layout better-writing better-typography better-colors better-ui
# take out the copies the third-party skills install from
cd ~/.agents/skills && rm -rf humanizer archify find-skills i-have-adhd frontend-design ui-demo better-interface better-accessibility better-layout better-writing better-typography better-colors better-ui
# remove the Codex plugin
claude plugin uninstall codex@openai-codex
# remove the TypeScript checker plugin
claude plugin uninstall typescript-lsp@claude-plugins-official
# disconnect the web search tool
claude mcp remove firecrawl -s user
# delete the Action First reply style, and older styles an earlier install left
rm -f ~/.claude/output-styles/action-first.md ~/.claude/output-styles/action-first.LICENSE ~/.claude/output-styles/i-have-adhd.md ~/.claude/output-styles/i-have-adhd.LICENSE ~/.claude/output-styles/plain.md
# delete the rules, settings and status line
rm -f ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/statusline.sh
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

## The twenty commands

Type the slash command, or just say the word. Both work.

| Command | What it's for |
|---|---|
| `/better` | turn a rough ask into a better prompt, then run it |
| `/build` | you want something new made; a new page gets a design check without asking |
| `/improve` | make a page or app you already have better, tested on a phone and a computer |
| `/fix` | something is broken or slow |
| `/handoff` | you're stopping halfway |
| `/short` | the last reply was too long; redo it with the next step first |
| `/resume` | write, tune or check a resume |
| `/github-readme` | tidy a repo and its README for GitHub |
| `/write-doc` | write a guide, report, email or post someone will read, or shorten one you have |
| `/find-skills` | find a skill someone else has made |
| `/skill-audit` | see which skills you use, which to drop, and which are out of date |
| `/writing` | you're writing rules for an AI |
| `/humanizer` | your writing sounds like an AI wrote it |
| `/site-design` | you need a page designed |
| `/dashboard-design` | design or check a dashboard, status page or metrics screen |
| `/demo-voiceover` | add a spoken voiceover to a demo video |
| `/last-30` | what changed lately |
| `/claude-video` | summarise a YouTube video |
| `/archify` | draw a diagram of a system |
| `/frontend-design` | give a page a deliberate look |

`/improve` picks from seven design checklists by itself (`better-interface`, `better-accessibility`,
`better-layout`, `better-writing`, `better-typography`, `better-colors`, `better-ui`), so you never
have to remember them. You can still type any of them on its own.

`/dashboard-design` is adapted from Otabek Abdiraimov's
[dashboard-design-skill](https://github.com/abdiraimov-otabek/dashboard-design-skill) (MIT, licence in
`skills/dashboard-design/LICENSE`).

## Workflows

| Type this | What happens |
|---|---|
| `/site-design a landing page for a bakery` | Claude builds three versions and shows them side by side. Pick one, then type `/build it, using version 2`. |
| `/fix the login page throws a 500` | Claude reproduces the error first, shows you the cause, fixes it, then shows it working. |
| `/improve the checkout page feels clunky` | Claude tries the page on a phone and a computer first, picks the design checks that fit, gets Codex and Fable to agree on each change, ships it, and tests again until it passes. |
| `/dashboard-design is the overview page clear at a glance?` | Claude sums the page up in one line, says what works, then lists what to fix, worst first. |
| `/improve just the colors` | Only the matching checklist runs. Problems it finds elsewhere are listed, not fixed. |
| `/better make my dashboard look nicer` | Claude rewrites your ask around what you want to end up with, shows you the new version, and runs it when you say go. |
| `/skill-audit` | Claude counts how often you used each skill and suggests which to keep, hide or delete. It also lists skills from other repos that have a newer version, and tests which skill Claude picks for about twenty everyday asks. It changes nothing until you choose. Once a month is about right. |
| `/handoff` | Running out of time? It writes down where you got to, so tomorrow you don't re-explain anything. |

## What's in here

| File | What it does |
| --- | --- |
| `CLAUDE.md` | Rules Claude follows on every task |
| `shared/` | The rules Claude and Codex share (`AGENTS.md`), which `CLAUDE.md` reads in, plus the script that builds Codex's copy |
| `skills/` | Sixteen of the twenty commands above. `/humanizer`, `/archify`, `/find-skills` and `/frontend-design` install from their own repos |
| `output-styles/action-first.md` | Shapes answers with the next step first and no recap |
| `memory/` | Notes Claude keeps on how you like to work |
| `settings.json` | Plugins, theme, status line, and merging pull requests without asking |
| `statusline.sh` | The bar at the bottom |
| `install.sh` | Sets this repo up on a machine, or updates one that already has it |
| `scripts/` | Tidies up stray Codex processes at session start |
| `hooks/` | The pre-commit guard that refuses a commit holding a secret |

## How it talks to you

`output-styles/action-first.md` shapes every reply for a busy reader who acts on it. It is adapted
from Ayoub Ghriss's [i-have-adhd](https://github.com/ayghri/i-have-adhd) skill (MIT, licence in
`output-styles/action-first.LICENSE`), renamed and turned into an output style so it runs in every
session without being typed.

The first line is the next thing you can do. Steps come as a numbered list with one action each,
and on a long job each update says where things stand ("step 3 of 5 done"). Time estimates use
real units such as "10 minutes" or "an afternoon". A side issue waits until the main one is
finished. Replies skip the opening filler and the closing recap, and they don't end by asking
whether you need anything else.

There is a length limit too. A normal reply is six sentences or fewer, and a reply that explains or
compares gets twelve. The limit holds in every folder, including the report at the end of a long job.

## The rules it follows

The rules live in `CLAUDE.md` and `shared/AGENTS.md`. What each one stops:

| Rule | What it stops |
| --- | --- |
| **Think before coding** | Guessing what you meant. If your request could mean two different things, it shows you both before building either. |
| **Check before you explain** | Made-up causes. It tells you why something happened only after checking logs, history or a test. If it can't check, it says it doesn't know and names the test that would tell. |
| **Simplicity first** | Features you did not ask for, wrappers around one call, settings nobody requested, handling for cases that cannot happen. |
| **Surgical changes** | Tidying code next to the thing you asked about. It matches the style already there, even style it would do differently. |
| **Goal-driven execution** | "Make it work" as a finish line. It says up front what test or command will prove it, then runs that check. |
| **Never idle** | Sitting waiting. Blocked on one thing, it finishes everything that does not depend on it, then reports. |
| **Confer with Codex** | Trusting its own plan. Before anything expensive, a second AI attacks the plan first. |
| **Check big jobs as they go** | Finding a wrong turn only at the end. On a job of more than about five steps or about an hour, Fable and Codex's Astra each write a plan, then take turns giving a quick yes-or-no check after each major step, and Codex reviews the finished work. |
| **Read before describing** | Describing your setup from memory. It opens the file first. |
| **Design rules** | Pages that all look alike: cream backgrounds, pill buttons, one italic word in the headline. PowerPoint keeps its template, and every edit gets a backup first. |

Two rounds, then it decides: one critique from Codex, one revision, one
re-check. If they still disagree it picks and tells you what it overrode in one
line. When tests cannot settle the question, it hands both positions to Fable, another
Claude model, without saying which is its own, and takes that pick. You can override it.

<details>
<summary><b>Costs and limits</b></summary>

Bigger or riskier jobs can mean extra questions, a plan and a second opinion before anything is
built, and those cost tokens. These rules limit when that happens and how long it goes on:

| Limit | What it does |
|---|---|
| Short replies | A normal reply stops at six sentences, twelve when it explains, so Claude writes less per answer. |
| A cheap model for read-only work | Haiku, a smaller and cheaper model, handles searching, listing and checking, and never writes anything. A stronger model always checks what it finds. |
| An effort ceiling | Codex never runs above medium effort. A sharper question comes before more effort. |
| Second opinions where they pay | Small edits that are easy to undo skip Codex. The full plan, step checks and review are kept for big jobs. |
| No endless loops | One critique, one revision and one re-check, then Claude decides. If Codex hangs twice on one task, Claude stops asking it for that task. |

</details>

<details>
<summary><strong>For me: syncing my machine back to this repo</strong></summary>

On my machine a git `post-commit` hook does this after every commit in `~/.claude`. It copies from the
last commit, so unfinished edits never ship, and it stops without pushing if a check fails: a name, home
path, pronoun, e-mail or address on an added line, a secret, a path it did not expect, or more than 5
deleted files. The manual steps below do the same without the checks.

```bash
# copy the rules and the status line from this machine into the repo
cp ~/.claude/CLAUDE.md ~/.claude/statusline.sh .
# copy the Action First reply style
cp -R ~/.claude/output-styles/. output-styles/
# copy the rules Claude and Codex share
cp -R ~/.claude/shared/. shared/
# copy the skills, leaving out third-party skills, personal skills, test cases and the sync folder
rsync -a --exclude humanizer --exclude archify --exclude find-skills --exclude i-have-adhd --exclude frontend-design --exclude diagram-design --exclude tasks --exclude model-update --exclude synced --exclude better-interface --exclude better-accessibility --exclude better-layout --exclude better-writing --exclude better-typography --exclude better-colors --exclude better-ui --exclude reverse-engineer-anything --exclude hub-add --exclude impeccable --exclude evals --exclude .claude-plugin --exclude __pycache__ --exclude results --exclude .DS_Store ~/.claude/skills/ skills/
# publish it
git add -A && git commit -m "Sync" && git push
```

</details>

## Licence

[MIT](LICENSE). Use it however you like, as long as the licence notice stays with it.
