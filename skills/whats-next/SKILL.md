---
name: whats-next
description: Use when the owner types /whats-next, says "what's next", "what should I do", "now what", "what should I work on", or asks for suggestions on this project. Reads the session task list, then unfinished work in the repo, then proposes three specific improvements.
user-invocable: true
model: haiku
effort: low
allowed-tools: [Bash, Read, Grep, Glob, TaskList, TaskUpdate, Agent]
---

# whats-next

Three sources, in order. Answer from the first one that has something and stop there.

## 1. The session task list

Run `TaskList`.

A pending task exists: mark it `in_progress` with `TaskUpdate` first, so an interrupted run
resumes rather than restarts. Then run it.

| The task | How it runs |
|---|---|
| Names a command (`/build X`) | Invoke that command with those arguments |
| Describes work to build | Dispatch a Fable agent to plan, then Opus agents to build. See `docs/AGENTS.md` |
| Mechanical (rename, move, trim) | Do it here |

Mark it `completed`, report what happened in one line, and list what remains.

The list comes from the harness. This setup derives its state rather than storing it, so
there is no queue file to read.

## 2. Unfinished work in the repo

The list is empty. Work already started outranks anything new:

```bash
git status --short 2>/dev/null
git log origin/main..HEAD --oneline 2>/dev/null
```

Anything uncommitted or unpushed: name it and stop.

> Unpushed: `<files or commits>`. Type `/release` to push it.

## 3. Three suggestions

The tree is clean. Look before proposing:

```bash
ls -1 2>/dev/null | head -20
git log --oneline -10 2>/dev/null
git diff HEAD~3 HEAD --stat 2>/dev/null | tail -20
```

Read enough of what you find to name real things. A suggestion earns its row by naming a
file, feature, or area that exists in this repo, saying what is weak about it in plain
words, and giving the exact thing to type.

| What | Why it matters | Type this |
|---|---|---|
| | | `/command args` |

Three rows. A generic menu that would fit any project is a failed answer: go back and read
more of the code.

## Done

This command has answered when the owner has one thing they could start in under two
minutes, drawn from whichever source fired.
