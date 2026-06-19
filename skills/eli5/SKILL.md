---
name: eli5
description: Explain anything in plain English before you commit to it. Paste a skill name, plan, command, or decision and get a wife-readable breakdown. No jargon. Activate on "/eli5".
user-invocable: true
argument-hint: "[skill name, plan text, command, or file path]"
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

### Step 2 — output exactly this structure

**What this is:**
2-3 sentences. Plain English. Explain it like the person reading has never heard of this before. What problem does it solve? What does it actually touch on the computer?

**What actually happens:**
3-5 bullets. Real verbs, concrete steps. "It reads X", "It runs Y", "It writes to Z", "It sends to GitHub." No vague words like "processes" or "handles."

**Watch out for:**
Only include this section if something in this action is irreversible, costs real money, touches something others can see, or can't be undone. One line per risk. Plain language. Examples: "This deletes files permanently." "This charges your Anthropic account." "This pushes to GitHub — your team will see it." "This overwrites the existing file."

If nothing is risky: skip the Watch out section entirely. Do not write "nothing to worry about" or any equivalent. Just end after What actually happens.
