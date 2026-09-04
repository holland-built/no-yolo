# no-yolo

A small Claude Code setup: four plugins other people maintain, seven files you own.

It fixes four things Claude does badly out of the box — it talks too much, it makes
ugly websites, it forgets what you told it, and it marks its own homework. No one
else's code is copied here; the plugins install from their authors.

## Install

One command per plugin — `install` takes a single name, so a combined line silently
installs only the first.

```bash
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex
claude plugin install mattpocock-skills
claude plugin install frontend-design
claude plugin install skill-creator
```

Two more, from their authors' repos:

```bash
npx skills@latest add blader/humanizer --global
npx skills@latest add nextlevelbuilder/ui-ux-pro-max-skill --global
```

The second one brings five extra skills with it (banner, brand, design-system,
slides, ui-styling). That is more than you asked for — drop the ones you do not want
from `~/.claude/skills/`.

Then the files:

```bash
git clone https://github.com/holland-built/no-yolo.git "$(mktemp -d)/no-yolo" && \
  bash "$_"/install.sh
```

`install.sh` never overwrites anything you already have. A file of yours that differs
is kept and mine lands beside it as `.theirs`. Your `settings.json` is backed up with a
timestamp, then deep-merged so every existing hook event and every existing `Stop` hook
survives. Run it twice and nothing duplicates. Restart Claude Code when it finishes.

Needs `git`, `jq`, `node` 20+, `python3`.
Second opinion: `npm install -g @openai/codex` then `codex login`.
Set `OBSIDIAN_VAULT` to your vault path in your shell profile. Both `/claude-video`
and `/claude-doc` stop without it, and both write into `wiki/sources/` there.
Videos also need `brew install yt-dlp ffmpeg`.
Documents need markitdown: `python3 -m pip install --upgrade 'markitdown[all]'`.

## What you get

| Plugin | By | Why |
|---|---|---|
| mattpocock-skills | Matt Pocock | The real work: interviews you, writes specs, TDD, code review |
| codex | OpenAI | A second model that attacks your work instead of agreeing |
| frontend-design | Anthropic | Taste: stops every page looking like the same AI template |
| ui-ux-pro-max | nextlevelbuilder | Inventory: 79 styles, 192 palettes, 74 font pairings to pick from |
| humanizer | blader | Strips the 35 patterns that make writing sound machine-made |
| skill-creator | Anthropic | Builds skills and proves they work with before/after tests |

| File | Why |
|---|---|
| `CLAUDE.md` | Answer first, under 10 lines, say "I don't know" instead of guessing |
| `hooks/reply-check.sh` | Blocks a reply that is too long, names too many files, runs a sentence past 20 words, **or** excuses something without proving it. It says which sentence and where to cut it. A rule gets forgotten mid-session; a hook always runs |
| `rules/web.md` | Design rules that load only when a web file is open |
| `skills/build/` | `/build` — asks, mockups, waits for your yes, has Codex attack the plan, builds, tests |
| `skills/ship/` | `/ship` — Codex reads your diff, docs update, then push |
| `skills/claude-video/` | `/claude-video` — watch a video, file the notes in Obsidian |
| `skills/claude-doc/` | `/claude-doc` — read a PDF or Word file, file the notes in Obsidian |

`bash hooks/reply-check.test.sh` proves the hook. It stays in the repo, not in your
setup.

Small obvious changes skip the pipeline. It is for work where being wrong is expensive.

## The one rule worth stealing

Give the model **the task, the guardrails, and the exit criteria**, then leave it alone.
Do not spell out every step. Over-specifying is the most common way this goes wrong, and
it is worst among people who have been doing this longest.

## Deleting this

Every six months, delete it and see what the model does without it. Models improve;
instructions written for last year's model hold this year's back. Add a line back only
after you watch the model get the same thing wrong twice.

The previous version of this repo is tagged `v1-archive`.

MIT. The plugins belong to their authors under their own licences.
