---
name: eli5
description: Use this skill when the user types /eli5, and automatically on every completed-work summary, next-actions list, or question to the user. Explains any skill, command, plan, decision, or finished work in plain English — table format, no jargon. Mode B table always includes "What I'm asking you" and "Where we are" rows.
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

| Question | Plain answer |
|---|---|
| **What just got done** | 1-2 sentences per item, plain English. "Your login page now remembers users" — not "implemented session persistence middleware". |
| **Where we are** | One sentence: how far along the overall job is, what's left. |
| **What I'm asking you** | The single decision or answer needed from the user, phrased as a plain question with the choices spelled out. If nothing is needed, write exactly: "Nothing — just letting you know." |
| **Next actions** | Numbered list. Each line: plain-English what + the exact command to type, e.g. `1. Publish it — type /release`. |

Rules for Mode B:
- The "What I'm asking you" row is the most important one. Never bury the ask in a paragraph. If there are options, list them as "Option A: … / Option B: …" with what each means in plain words.
- Jargon translation is mandatory: every technical term gets replaced or explained inline ("the hook (a script that runs automatically)").
