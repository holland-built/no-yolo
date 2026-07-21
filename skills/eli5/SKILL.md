---
name: eli5
description: Use this skill when the user types /eli5, and automatically on every completed-work summary, next-actions list, or question to the user. Explains any skill, command, plan, decision, or finished work in plain English, short, no jargon. Mode B: a simple ask/reminder/single next step is ONE plain sentence; a status list (what's done / what's left / options) is a small chart. No mandatory "why" padding.
user-invocable: true
argument-hint: "[skill name, plan text, command, or file path]"
model: haiku
allowed-tools:
  - Bash
  - Read
---

# eli5

Explain what something actually does before the user says yes to it.

## How to run

### Step 0 — no argument

If no argument was provided, run:

```bash
grep -E "^[a-z][a-z0-9-]+\|" ~/.claude/skills/my-skills/STORIES.md | cut -d'|' -f1 | sort
```

Emit as a 2-column table titled **Pick a skill to explain** with columns **Skill** | **Skill** (pair them left-right, 2 per row). Below the table add one line: `Run /eli5 <name> — also works on any command, plan text, or file path.` Then stop. Do not explain anything further.

### Step 1 — gather the input

If the argument looks like a known skill name, run:

```bash
arg="REPLACE_WITH_ARG"
grep "^$arg|" ~/.claude/skills/my-skills/STORIES.md 2>/dev/null | cut -d'|' -f2-
```

If the argument looks like a file path and the file exists, use the Read tool to read it.

If the argument is raw text (a command, a plan snippet, a decision), use it directly.

### Step 2 — pick the mode

Two modes. Pick by what the input IS:

- **Mode A — explain a thing** (a skill, a command, a plan not yet run): the user is deciding whether to say yes.
- **Mode B — explain finished work / next steps** (a completion summary, "what was done", next actions, a question you need answered): the user is catching up and deciding what to do now.

Both modes output a TABLE, never prose paragraphs.

### Mode A — explain a thing

| Question | Plain answer |
|---|---|
| **What is this?** | 1-2 sentences, like the reader has never heard of it. What problem does it solve? |
| **What actually happens?** | Real verbs, concrete steps: "reads X", "runs Y", "pushes to GitHub". No "processes"/"handles". Use `<br>` for multiple steps. |
| **Watch out** | ONLY if irreversible, costs money, or visible to others — e.g. "deletes files permanently", "pushes to GitHub, your team sees it". If nothing risky, OMIT this row entirely — never write "nothing to worry about". |

### Mode B — finished work / next steps

The user is non-technical. Plain, short, no jargon is the constant. **Pick the form by the content:**

**One thing to say — a simple ask, a reminder, or a single next step → ONE plain sentence.** No table.
> Saved and switched on. Next: run `/memory-compile` when you want it live.

**A status list — what's done, what's left, or a set of options → a small chart.** Use it only when there really is a list:

| What | Status | Type this |
|---|---|---|
| Renamed /review to /health | done | — |
| Pick eli5 format | need your call | answer here |
| Live-test the judge | optional | `/design` |

Hard rules for Mode B:
- **Shorter always wins.** A few words per cell, ≤5 rows. Fragments, not sentences.
- **No jargon anywhere.** Translate any technical term inline, or cut it. "md file", "supersede", "compile" → say what it does.
- **No mandatory "why."** Add a reason ONLY if it's short and changes the decision — never a paragraph, never history/justification padding.
- Asks say plainly what you need; options spelled "A: … / B: …" in plain words.
- No prose walls before/after — one lead-in sentence max. When unsure between a sentence and a chart, use the sentence.
