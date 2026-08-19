---
name: whats-next
description: Use this skill when the user types /whats-next, says 'what's next', 'what should I do', or 'now what'. Session-aware next-action engine that checks the task queue first; if empty, scans project and proposes improvements.
user-invocable: true
argument-hint: ""
model: haiku
effort: low
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - TaskList
  - TaskUpdate
---

# whats-next

**Rule: act on session tasks first. When queue is empty, think creatively about the project.**

---

## Step 1: Check session task queue

Run `TaskList`. If it returns nothing, or every task is `completed` → skip to Step 3.

Otherwise take the first task that is still `pending` and go to Step 2.

The queue is the harness's own task list, not a file. An earlier version of this step read
`~/.claude/.pending-tasks.md`, which nothing in this setup has ever written, so Steps 1 and 2 <!-- gone-on-purpose -->
could never fire, and `/whats-next` silently behaved as though the queue were always empty.
Never reintroduce a hand-maintained queue file; this repo derives state, it does not store it.

---

## Step 2: Run next pending task

Set the task to `in_progress` with `TaskUpdate` before doing anything else, so an interrupted
run doesn't start it twice. Mark it `completed` when it finishes.

Read the task description and execute it:

- If task names a skill (e.g. `/build`, `/build --plan-only`) → invoke that skill with the task's arguments
- If task is a build task (e.g. "build X", "implement Y") → never code inline: spawn a Fable planning agent, then Opus agents for the implementation
- If task is mechanical (trim file, rename, move) → do it inline with Read+Edit

After completing: report done, then run `TaskList` again and show the remaining pending tasks (if any).

Stop here, do not proceed to Step 3.

---

## Step 3: Creative suggestion (queue empty)

Queue is empty. First check for unpushed work. That is always more urgent than creative suggestions:

```bash
git status --short 2>/dev/null
git log origin/main..HEAD --oneline 2>/dev/null
```

If there are uncommitted changes or unpushed commits → surface them immediately:
> `Unpushed work: [list files or commits]. Run /release to push.`
Stop here. Do not proceed to scan below.

If working tree is clean and nothing unpushed, scan for signal:

```bash
# What's the project?
ls -1 2>/dev/null | head -20
git log --oneline -10 2>/dev/null
git diff HEAD~3 HEAD --stat 2>/dev/null | tail -20
# Recent test failures?
find . -name "*.log" -newer . -not -path "*/.git/*" 2>/dev/null | head -5
```

Based on what you see, generate **3 creative, project-specific suggestions**, not a generic menu. Each suggestion should:
- Name a specific file, feature, or area in the actual project
- Say what's improvable and why it matters
- Give the exact skill + argument to run it

Format, eli5 Mode B: a small chart, since this is a list of options (plain, short, no jargon):

```
> Queue empty. Suggestions:

| What | Why it matters | Type this |
|---|---|---|
| [specific improvement 1] | [plain-words payoff] | `/skill [args]` |
| [specific improvement 2] | [plain-words payoff] | `/skill [args]` |
| [specific improvement 3] | [plain-words payoff] | `/skill [args]` |
```

Rules:
- The Step 2 "report done + remaining tasks" output uses the same small chart: one row per remaining task.
