# no-yolo

A small Claude Code setup. Four plugins other people maintain, five files you own.

It fixes four things Claude does badly out of the box: it talks too much, it makes
ugly websites, it forgets what you told it, and it marks its own homework.

Nothing here is a copy of anyone else's code. The plugins are installed from their
authors. The five files are the ones I wrote.

## Install

Three commands, then copy five files.

```bash
claude plugin marketplace add openai/codex-plugin-cc
claude plugin install codex@openai-codex
claude plugin install mattpocock-skills frontend-design skill-creator
```

```bash
git clone https://github.com/holland-built/no-yolo.git /tmp/no-yolo
cp -r /tmp/no-yolo/{CLAUDE.md,rules,hooks,skills} ~/.claude/
chmod +x ~/.claude/hooks/reply-check.sh
```

Then open `~/.claude/settings.json` and paste in the two blocks from
`settings.snippet.json`. Restart Claude Code. That is the whole install.

Needs `git`, `jq`, `node` 20+, `python3`. For videos: `brew install yt-dlp ffmpeg`.
For the second opinion: `npm install -g @openai/codex`, then `codex login`.

## What each plugin is for

| Plugin | Author | Why |
|---|---|---|
| mattpocock-skills | Matt Pocock | The actual work: interviewing you, writing specs, TDD, code review. 25 skills |
| codex | OpenAI | A second model that attacks your work instead of agreeing with it |
| frontend-design | Anthropic | Stops every page looking like the same AI template |
| skill-creator | Anthropic | Builds new skills, and proves they work with before/after tests |

## What each file is for

| File | Why |
|---|---|
| `CLAUDE.md` | Answer first. Under 10 lines. Say "I don't know" instead of guessing |
| `hooks/reply-check.sh` | Blocks a reply that is too long **or** names too many files. A rule gets forgotten mid-session; a hook always runs |
| `rules/web.md` | Design rules that load only when a web file is open, so they cost nothing the rest of the time |
| `skills/build/` | `/build` — the order of a job, so nobody has to remember it |
| `skills/ship/` | `/ship` — check with Codex, update docs, push |
| `skills/claude-video/` | `/claude-video` — watch a video, file the notes in Obsidian |

## The two commands

**`/build <thing>`** — asks you questions until it understands, writes a spec, shows a
mockup, waits for your yes, has Codex attack the plan, then builds and tests it. It
writes the finish line before it starts and checks it at the end.

**`/ship`** — Codex reads your diff and tries to break it. Real findings get fixed,
docs get updated, then it branches and pushes.

Small obvious changes skip the pipeline. It is there for work where being wrong is expensive.

## The one rule worth stealing

Give the model **the task, the guardrails, and the exit criteria** — then leave it alone.
Do not spell out every step. Over-specifying is the most common way this goes wrong, and
it is worst among people who have been doing this longest.

## Deleting this

Every six months, delete it and see what the model does without it. Models get better;
instructions written for last year's model hold this year's back. Add a line back only
when you watch the model get the same thing wrong twice.

The previous version of this repo is tagged `v1-archive` if you need it.

## Licence

MIT. The plugins belong to their authors under their own licences.
