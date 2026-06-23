---
name: whats-next
description: Session-aware next-action engine. Checks pending task queue first — if tasks exist, runs the next one. If queue empty, scans current project and proposes creative improvements. Never shows a static menu. Activate on "/whats-next", "what's next", "what should I do", "now what".
user-invocable: true
argument-hint: ""
model: haiku
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
---

# whats-next

**Rule: act on session tasks first. When queue is empty, think creatively about the project — never offer a static menu.**

---

## Step 1 — Check session task queue

Read `~/.claude/.pending-tasks.md`. If absent or all items checked → skip to Step 3.

Find the first unchecked line: `- [ ]`

If found → go to Step 2.

---

## Step 2 — Run next pending task

Mark the task `- [x]` in `~/.claude/.pending-tasks.md` (Edit the file first so it's not re-run if interrupted).

Read the task description and execute it:

- If task names a skill (e.g. `/forge`, `/plan-feature`) → invoke that skill with the task's arguments
- If task is a build task (e.g. "build X", "implement Y") → spawn Opus planner then Sonnet agents per CORE_RULES rule 5
- If task is mechanical (trim file, rename, move) → do it inline with Read+Edit

After completing: report done, then re-read `~/.claude/.pending-tasks.md` and show remaining unchecked tasks (if any).

Stop here — do not proceed to Step 3.

---

## Step 3 — Creative suggestion (queue empty)

Queue is empty. First check for unpushed work — that is always more urgent than creative suggestions:

```bash
git status --short 2>/dev/null
git log origin/main..HEAD --oneline 2>/dev/null
```

If there are uncommitted changes or unpushed commits → surface them immediately:
> `Unpushed work: [list files or commits]. Run /ship to push.`
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

Based on what you see, generate **3 creative, project-specific suggestions** — not a generic menu. Each suggestion should:
- Name a specific file, feature, or area in the actual project
- Say what's improvable and why it matters
- Give the exact skill + argument to run it

Format:
```
> Queue empty. Here's what looks interesting:

1. **[specific thing]** — [why it matters]. Run: `/skill [args]`
2. **[specific thing]** — [why it matters]. Run: `/skill [args]`
3. **[specific thing]** — [why it matters]. Run: `/skill [args]`
```

Do NOT offer generic options like "audit codebase" or "review recent changes" without tying them to specific files or patterns you actually observed.
