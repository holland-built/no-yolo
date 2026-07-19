# INSTALL.md — agent-guided install walkthrough

You (Claude) are reading this because a beginner just cloned this repo and asked you to walk
them through installing it. Follow these steps in order. Talk plainly — translate any jargon
in one short clause the first time you use it. Do not skip a failed step silently; explain it
and give the manual fallback.

## 1. Greet

One or two sentences: this repo gives Claude Code extra commands, working rules, and memory.
You're going to check their machine, run the installer, and confirm it worked.

## 2. Check the machine

Run each check below. For any that's missing, explain in one plain sentence why it's needed,
then give the install line for their OS (Mac vs Linux — ask if unsure, or detect via `uname`).

| Check | Command | Why (one sentence) |
|---|---|---|
| git | `git --version` | Downloads and updates this repo's files. |
| Node.js | `node --version` | Runs the tools (skills) this setup installs. |
| npm | `npm --version` | Installs those tools (comes with Node.js). |
| python3 | `python3 --version` | Runs the setup script's rule-checking steps. |

Install pointers if missing:
- **git** — Mac: pre-installed; Linux: `sudo apt install git`
- **Node.js / npm** — [nodejs.org](https://nodejs.org/) (installs both together)
- **python3** — Mac: pre-installed; Linux: `sudo apt install python3`

If git or python3 is missing, stop and help them install it before continuing — the installer
needs both. Node/npm are needed for the full install but not for a rules-only install.

## 3. Run the installer

Run: `bash ~/.claude/setup.sh`

The script prints a **Preflight** block first (tool check, same as step 2 — just confirm it
matches what you already found), then numbered steps, then an **Install summary** at the end.

Narrate the summary in plain English, step by step:
- Each line reading `OK` — say what that tool now does for them, one clause.
- Any line reading `FAILED` — do NOT skip past it. Name the exact step, explain what it means
  in plain words, and give the manual fallback. Manual fallbacks live in **README.md → Add-ons
  table** — look up the row matching that tool and quote its "Install" column. Don't guess or
  invent a fallback; point at that table.

## 3.5. Codex is optional

The Preflight block also checks for `codex`. If it reads "not installed", tell the user in one
plain sentence: Codex is optional, the cross-check steps in skills detect it's missing and skip
themselves, and they can add it later via `/plugin install codex@openai-codex`. If the user asked
for a minimal install, run `bash ~/.claude/setup.sh --core-only` instead of the plain command in
step 3, and explain that it skips the third-party plugin-skill installs (trim, improve,
emilkowalski/skills, archify) — they can add those later by re-running plain `setup.sh`.

## 4. Explain permission prompts

If Claude Code shows a permission prompt during setup (asking to run a command or touch a
file), explain in one sentence what it's about to do and why, in plain words, before it
proceeds. This repo is deliberately cautious about permissions — that's expected, not a bug.

## 5. Confirm it worked

Have the user do two things, then interpret the results for them:

1. Run `/my-skills` — a table of commands appearing means the install worked.
2. Run `bash ~/.claude/verify.sh` — a health check. Explain: **all rows reading PASS means
   the clone is healthy.** If any row reads `FAIL`, read that row's message aloud in plain
   words and say this needs a developer's help (it's a deeper check than setup.sh covers).

## 6. Wrap up

Point them at **README.md → "Read next"** for what to read to understand the rules, rather
than re-explaining those rules yourself here — that section is the source of truth and this
file would drift from it otherwise.
