# no-yolo

[![MIT licence](https://img.shields.io/badge/licence-MIT-blue)](LICENSE)
![macOS and Linux](https://img.shields.io/badge/macOS%20%7C%20Linux-supported-green)
![26 commands](https://img.shields.io/badge/commands-26-8A2BE2)
[![latest release](https://img.shields.io/github/v/release/holland-built/no-yolo)](https://github.com/holland-built/no-yolo/releases)
![last commit](https://img.shields.io/github/last-commit/holland-built/no-yolo)

Claude Code is an AI that writes code in your terminal. Left alone, it guesses what you meant and
marks its own homework. no-yolo makes it ask first, answer briefly and get a second opinion on
costly work. Installing takes about two minutes.

## Quick start

You need macOS or Linux, [Claude Code](https://claude.com/claude-code), Git, Python 3.9+, Node.js and `jq`.

1. Download and install the safe version:

   ```bash
   # download no-yolo, open its folder, and run the safe install
   git clone https://github.com/holland-built/no-yolo.git ~/no-yolo && cd ~/no-yolo && ./install.sh
   ```

2. Read any "Needs attention" lines the installer prints.
3. Restart Claude Code.
4. Type `/fix`. Claude should ask what is broken instead of guessing.

> [!WARNING]
> The installer replaces `~/.claude/CLAUDE.md`, `statusline.sh` and any skill with the same name as
> one here. It keeps a copy of each in `~/.claude/.no-yolo-backups`. Your `settings.json` is merged,
> not replaced, and a dated backup is saved beside it.

> [!WARNING]
> The secret guard makes git use this repo's hooks in every repo on your computer, so hooks in a
> repo's own `.git/hooks` stop running. If you already set a global hooks folder, the installer
> leaves it alone and tells you the guard is off. Keep this folder, because the guard runs from it.

> [!WARNING]
> On Linux the risky-change review tool never runs, because its network block needs macOS. Claude
> reviews those changes by hand.

## Choose a mode

| | `./install.sh` (safe) | `./install.sh --full` |
|---|---|---|
| Rules, skills, reply style | Yes | Yes |
| Guards and plugins | Yes | Yes |
| Claude can merge, tag and release without asking | No | **Yes** |
| Auto permission mode | No | **Yes** |
| Tidies branches and copies at session start | No | **Yes** |
| Stops unused Codex processes | No | **Yes, macOS** |
| Weekly updaters | No | **Yes, macOS** |

> [!WARNING]
> `--full` lets Claude push branches, delete remote branches, merge pull requests, create tags and
> publish releases without asking you. It also deletes merged local branches and finished Orca
> copies when a session starts. A hook still blocks pushes straight to `main`, and Claude still asks
> before a force push or deleting a repo or release. Use it only on a computer and GitHub account
> where you accept that.

```bash
# switch on everything in the table, including merging without asking
./install.sh --full
```

```bash
# go back to the safe version and remove what only full mode added
./install.sh
```

## Use cases

Type the command and what you want, or just say it in plain words.

| Type this | What happens |
|---|---|
| `/fix the login page throws a 500` | Reproduces the error, shows the cause, fixes it, shows it working |
| `/build a Save button on the settings page` | Agrees what it should do, has a second AI attack the plan, builds it |
| `/improve the checkout page feels clunky` | Tests on phone and computer sizes, fixes the worst problems, tests again |
| `/site-design a landing page for a bakery` | Builds three versions, has a second AI check them, then you pick one |
| `/dashboard-design is the overview clear?` | Gives a verdict, what works, then fixes in order |
| `/grill-lite should I move my desk upstairs?` | Asks numbered questions, then saves your decisions |
| `/better make my dashboard look nicer` | Rewrites your request around the result you want |
| `/short` | Redoes the last reply shorter, next step first |
| `/handoff` | Writes down where you got to for the next session |
| `/retro` | Reviews a session and suggests what to change |
| `/write-doc a quick start for the new laptop` | Writes a guide, report, email or post |
| `/github-readme` | Tidies a repo and its README for GitHub |
| `/last30days Claude Code` | Summarises what people said in the last 30 days |
| `/claude-video <YouTube link>` | Summarises a video into your notes |
| `/skill-audit` | Shows which skills you use and which are out of date |
| `/writing`, `/humanizer` | Writes rules for an AI, or makes writing sound less like an AI |
| `/diagram-design` | Makes a branded diagram or chart |
| `/frontend-design`, `/find-skills` | Gives a page its own look, or finds someone else's skill |
| `/impeccable` | Designs, critiques and polishes a page |

`/improve` chooses from eight design checklists on its own, so you do not need to remember them.

<details>
<summary><b>What gets installed</b></summary>

| Path | Holds |
|---|---|
| `CLAUDE.md`, `shared/` | The rules Claude follows, and the rules Claude and Codex share |
| `skills/` | The 17 commands that live in this repo. The other 9 install from their own projects |
| `output-styles/` | The Action First reply style |
| `hooks/` | The secret guard and the Claude Code safety hooks |
| `tools/` | Risky-change review, session tidy, process cleanup and weekly updaters |
| `templates/` | Settings for each mode and the macOS schedule files |
| `installer/` | The installer and the recorded version of each outside project |
| `memory/` | Example notes. The installer does not copy them |

The safe install copies only the two tools it uses. `--full` copies them all.

</details>

<details>
<summary><b>Mac-only features</b></summary>

On Linux, each of these prints one "macOS only" line and changes nothing.

| Feature | Needs |
|---|---|
| Risky-change review tool | `sandbox-exec` network block |
| Weekly updaters | `launchd` |
| Codex process cleanup | BSD `stat` |
| Voiceover timing in `/demo-voiceover` | `say`, `afinfo` |

</details>

<details>
<summary><b>Optional add-ons</b></summary>

Codex gives Claude a second opinion. It needs an OpenAI account. Without it, Claude says once that
it skipped the Codex checks.

```bash
# install the Codex command-line tool
npm install -g @openai/codex
```

```bash
# sign in to Codex
codex login
```

The risky-change review uses Open Code Review on macOS. Without it, Claude reviews by hand.

```bash
# install the review tool without running its install scripts
npm install -g --ignore-scripts @alibaba-group/open-code-review
```

The TypeScript plugin needs its language server.

```bash
# install the TypeScript language server
npm install -g typescript-language-server typescript
```

[Orca](https://github.com/stablyai/orca) runs several Claude and Codex jobs side by side. Without
it, Claude does the jobs one at a time.

</details>

<details>
<summary><b>Update</b></summary>

Run the mode you use. A file here replaces the installed copy, and your own version is backed up
the first time.

```bash
# get the latest version of no-yolo
cd ~/no-yolo && git pull
```

```bash
# apply it in safe mode. Add --full if that is the mode you use
./install.sh
```

</details>

<details>
<summary><b>Uninstall</b></summary>

This removes only what the installer recorded. It keeps files you changed afterwards and restores
copies it backed up.

```bash
# remove no-yolo from this computer
cd ~/no-yolo && ./install.sh --uninstall
```

</details>

<details>
<summary><b>Credits and licences</b></summary>

Outside projects install from their own source at the commit recorded in
[`installer/sources.json`](installer/sources.json). Anthropic's official plugin list is the one
exception, because it follows Anthropic's own branch. The Action First style, `/dashboard-design`,
`/retro` and `/grill-lite` live in this repo, with credit below.

| Project | Used for | Licence |
|---|---|---|
| [codex-plugin-cc](https://github.com/openai/codex-plugin-cc) | Codex plugin | Apache-2.0 |
| [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | TypeScript plugin | Apache-2.0 |
| [cc-safety-net](https://github.com/kenryu42/cc-safety-net) | Command safety plugin | MIT |
| [last30days-skill](https://github.com/mvanhorn/last30days-skill) | `/last30days` | MIT |
| [humanizer](https://github.com/blader/humanizer) | `/humanizer` | MIT |
| [diagram-design](https://github.com/cathrynlavery/diagram-design) | `/diagram-design` | MIT |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | `/find-skills`, skill installer | MIT |
| [anthropics/skills](https://github.com/anthropics/skills) | `/frontend-design` | Apache-2.0 |
| [impeccable](https://github.com/pbakaus/impeccable) | `/impeccable` | Apache-2.0 |
| [jakubkrehel/skills](https://github.com/jakubkrehel/skills) | Eight `better-*` checklists | MIT |
| [i-have-adhd](https://github.com/ayghri/i-have-adhd) | Adapted into the Action First style | MIT |
| [dashboard-design-skill](https://github.com/abdiraimov-otabek/dashboard-design-skill) | Adapted into `/dashboard-design` | MIT |
| [mattpocock/skills](https://github.com/mattpocock/skills) | `/retro`, and the idea for `/grill-lite` | MIT |

</details>

## Licence

[MIT](LICENSE). Keep the licence notice with any copy.
