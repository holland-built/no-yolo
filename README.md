<h1 align="center">no-yolo</h1>

<p align="center"><strong>Makes Claude stop guessing.</strong></p>

<p align="center">
<a href="LICENSE"><img alt="MIT licence" src="https://img.shields.io/badge/licence-MIT-blue"></a>
<img alt="macOS and Linux" src="https://img.shields.io/badge/macOS%20%7C%20Linux-supported-green">
<img alt="twenty-two commands" src="https://img.shields.io/badge/commands-22-8A2BE2">
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

**Jump to:** [Install](#install) · [Use cases](#use-cases) · [Rules](#the-rules-it-follows) · [Update](#update)

## Install

| Where | Needs |
|---|---|
| Your computer | macOS or Linux (not Windows) |
| Installed first | [Claude Code](https://claude.com/claude-code), Git, Node.js, `jq` |

1. Download and install. The script backs up your current `~/.claude` first, then copies the
   rules, style and skills in, installs `gitleaks` and `exiftool`, and turns on the secret guard.

   ```bash
   # download this repo to the path the settings expect
   mkdir -p ~/AI && git clone https://github.com/holland-built/no-yolo.git ~/AI/no-yolo
   # set everything up on this machine
   ~/AI/no-yolo/install.sh
   ```

2. Restart Claude Code.
3. Type `/fix`. It should ask what is broken instead of guessing.

> [!WARNING]
> The script replaces `CLAUDE.md`, `settings.json`, `statusline.sh` and any skill of yours with
> the same name as one here, and `~/.codex/AGENTS.md` if Codex is installed (its old copy is kept beside it). The dated backup it
> writes first is the only way back.
>
> The secret guard makes git use this repo's hooks for every repo on the machine, so your own
> `.git/hooks` stop running. Undo with `git config --global --unset core.hooksPath`. If git
> already has a hooks folder set, the script leaves it alone and prints the one line to run instead.
>
> Claude may open, merge and release pull requests on GitHub without asking. A hook still blocks
> its pushes straight to `main`, and it asks before a force push or deleting a repo or release.
> To be asked every time, move the `gh` and `git` lines from `allow` to `ask` in
> `~/.claude/settings.json` (redo after each update).

<details>
<summary><strong>Have an AI install it instead</strong></summary>

Paste this into Claude Code, or any coding agent that can run commands. It does the same steps
and adds the twelve skills from other repos.

```text
Install no-yolo on this machine. Clone https://github.com/holland-built/no-yolo.git to
~/AI/no-yolo. If that folder already exists, check that its origin is that URL and that git
status is clean; if either is not true, stop and tell me. Otherwise git pull. Read its README,
then run ~/AI/no-yolo/install.sh. Then install the twelve third-party skills by running the
install-everything command under "Twelve skills that install from their own repos" in that README.
Do not change anything else. When it is done, tell me what the install script backed up,
what it installed, and anything that failed, then remind me to restart Claude Code.
```

</details>

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
<summary><strong>Orca: run several coding jobs at once</strong></summary>

[Orca](https://github.com/stablyai/orca) is a desktop app that runs Claude and Codex side by side,
each in its own copy of your project. With it, Claude hands separate coding jobs to helper
agents in Orca tabs and combines their work when they report back (see **Use cases** and the
**Manage, don't do** rule below). **No Orca? Skip this.** Claude does the jobs one after another itself and says so.

Download it from [orca.dev/download](https://orca.dev/download) (Mac, Windows, Linux), or on a Mac:

```bash
# install the Orca desktop app
brew install --cask stablyai/orca/orca
```

Then, in Orca:

1. Open your project folder. It has to be a git repo, because each helper works in its own copy.
2. Click the gear icon at the bottom left, then **Orchestration**, then **Update**, and answer
   yes. That installs the add-on that lets Claude start helpers and hear back from them.
3. Start Claude in an Orca tab, not a separate terminal, so Orca can wake Claude when a helper
   finishes. Keep Orca's notifications on (gear icon, then **Notifications**) so you hear when
   Claude is waiting on you.

Helpers' copies clean themselves up. Each time you start Claude, a hook deletes any copy whose work
is merged, that has no changed or new files (files git ignores aside), and that nobody has touched
for an hour. Nothing to set up.

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
cd ~/.claude/skills && rm -rf better build claude-video dashboard-design demo-voiceover fix github-readme grill-lite write-doc handoff improve jev-judge last-30 resume retro short site-design skill-audit writing humanizer archify find-skills i-have-adhd frontend-design ui-demo better-interface better-accessibility better-layout better-writing better-typography better-colors better-ui
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

## Use cases

Type the command and what you want, or just say it in plain words. Both work.

| Type this | What happens |
|---|---|
| `/fix the login page throws a 500` | Reproduces the error, shows you the cause, fixes it, shows it working |
| `/build a Save button on the settings page` | Agrees what it should do, has a second AI attack the plan, builds it, shows it running |
| `/improve the checkout page feels clunky` | Tests it on a phone and a computer, fixes the worst problems, tests again until they pass |
| `/improve just the colors` | Runs only the color checks; other problems are listed, not fixed |
| `/site-design a landing page for a bakery` | Builds three versions side by side. Then `/build it, using version 2` |
| `/dashboard-design is the overview clear at a glance?` | One-line verdict, what works, then fixes worst first |
| `/grill-lite should I move the NAS to the garage?` | Asks you questions in numbered rounds before anything is built or bought, then saves the decisions in a short note |
| `/better make my dashboard look nicer` | Rewrites your ask around what you want to end up with, runs it on your go |
| `/short` | Redoes the last reply shorter, next step first |
| `/handoff` | Writes down where you got to, so tomorrow you don't re-explain |
| `/retro` | Looks back at a session and suggests what to change next time |
| `/write-doc a quick start for the new laptop setup` | A guide, report, email or post someone will read |
| `/github-readme` | Tidies a repo and its README for GitHub |
| `/resume tailor mine to this job post` | Writes, tunes or checks a resume, without inventing facts |
| `/last-30 Claude Code` | What changed in a tool in the last 30 days |
| `/claude-video <YouTube link>` | Summarises a video into your notes |
| `/skill-audit` | Which skills you use, which to drop, which are out of date. Changes nothing until you choose |
| `/writing`, `/humanizer` | Write rules for an AI; make your writing sound less like an AI |
| `/demo-voiceover`, `/archify`, `/frontend-design`, `/find-skills` | Narrate a demo video; draw a system diagram; give a page its own look; find someone else's skill |
| `fix the login error, add a Save button, and add dark mode` | With Orca, each job goes to its own helper, up to three at once. Each change goes live as soon as it's tested, and you get a "Live: test this" note for each |
| `why is the login page so slow?` | A reading helper digs and reports back; the main chat stays free |
| `1 2` | Your answer when Claude is waiting on you: one number per question |

`/improve` picks from seven design checklists by itself (`better-*`), so you never have to
remember them. `/retro` is from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT), and `/grill-lite` is adapted from its grilling skills.
`/dashboard-design` is adapted from
[dashboard-design-skill](https://github.com/abdiraimov-otabek/dashboard-design-skill) (MIT, licence
in `skills/dashboard-design/LICENSE`).

<details>
<summary><strong>What's in here</strong></summary>

| File | What it does |
| --- | --- |
| `CLAUDE.md` | Rules Claude follows on every task |
| `shared/` | The rules Claude and Codex share (`AGENTS.md`), which `CLAUDE.md` reads in, the script that builds Codex's copy, and `orca-builders.md`, the steps for running coding jobs in parallel in Orca |
| `skills/` | Eighteen of the twenty-two commands above. `/humanizer`, `/archify`, `/find-skills` and `/frontend-design` install from their own repos |
| `output-styles/action-first.md` | Shapes answers with the next step first and no recap |
| `memory/` | Notes Claude keeps on how you like to work |
| `settings.json` | Plugins, theme, status line, and merging pull requests without asking |
| `statusline.sh` | The bar at the bottom |
| `install.sh` | Sets this repo up on a machine, or updates one that already has it |
| `scripts/` | Run when Claude starts: tidies stray Codex processes, deletes finished Orca helper copies and merged branches, and catches your project up with GitHub |
| `hooks/` | The pre-commit guard that refuses a commit holding a secret, and the Claude hook that blocks pushes straight to `main` |

</details>

## How it talks to you

The first line is the next thing you can do. Steps are numbered, one action each. A normal reply
is six sentences or fewer (twelve when it explains), in your words, not tool words. Four fixed
blocks tell you where things stand.

When it needs you to choose, every question comes in one block, with the recommended option
first. You answer with one number per question:

```text
------------------------- Waiting on you -------------------------
Save button
  1. Top right, next to Share (recommended)
  2. Bottom of the page

Dark mode
  1. Follow the phone's setting (recommended)
  2. Always dark

Reply with one number per question, in order. Example: 1 2
```

Each helper's change goes live as soon as it's tested, with one thing to try while the others
keep working:

```text
------------------------- Live: test this -------------------------
The Save button now keeps your changes when you leave the page
Try: on your phone, edit your name, tap Save, then reload
```

Every piece of real work ends with Done or Not done yet, so you know if it's safe to close:

```text
------------------------------ Done ------------------------------
Live: the login page no longer shows an error after a wrong password
Safe to close. Nothing is running, nothing is waiting on you.
```

<details>
<summary><strong>More on the reply style</strong></summary>

`output-styles/action-first.md` is adapted from Ayoub Ghriss's
[i-have-adhd](https://github.com/ayghri/i-have-adhd) skill (MIT, licence in
`output-styles/action-first.LICENSE`), turned into an output style so it runs in every session.

- Long jobs say where they stand ("step 3 of 5 done") and give times in real units.
- A side issue waits until the main one is finished. No opening filler, recap or "anything else?".
- A technical word appears only after you've used it, and one thing keeps one name all chat.
- Not done yet looks like `Still running: two helpers, about 10 minutes`.
- A helper's own tab never asks you anything. It ends with
  `Handed to the main chat. Nothing for you here.`, and a helper that fails gets one line in the
  main chat, such as `dark-mode: failed 2 times (the page tests broke). See the question above.`
- Codex gets the same style, so its answers look the same.

</details>

## The rules it follows

The rules live in `CLAUDE.md` and `shared/AGENTS.md`. What each one stops:

| Rule | What it stops |
| --- | --- |
| **Think before coding** | Guessing what you meant. If your request could mean two different things, it shows you both before building either. |
| **Check before you explain** | Made-up causes. It tells you why something happened only after checking logs, history or a test. If it can't check, it says it doesn't know and names the test that would tell. |
| **Simplicity first** | Features you did not ask for, wrappers around one call, settings nobody requested, handling for cases that cannot happen. |
| **Surgical changes** | Tidying code next to the thing you asked about. It matches the style already there, even style it would do differently. |
| **Every change through a pull request** | Changes that skip CI and review. It works on a branch and opens a pull request; a hook blocks its ordinary pushes straight to `main` or `master`. |
| **Goal-driven execution** | "Make it work" as a finish line. It says up front what test or command will prove it, then runs that check. |
| **Work around a blocker, then wait** | Sitting waiting. Blocked on one thing, it finishes everything that does not depend on it, then reports. |
| **Manage, don't do** | One chat buried in one task while your next request waits. The main Claude hands each coding job to a helper in its own copy of the repo in [Orca](https://github.com/stablyai/orca), at most three at once. As each reports, it merges, tests and ships that change live right away, one at a time, and tells you what to test. It ships finished work before it asks you anything, so nothing waits behind a question. Without Orca, outside a git repo, or for a one-line change, it does the work itself and says so. |
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
