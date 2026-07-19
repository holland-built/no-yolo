---
name: eli5
description: Use this skill when the user types /eli5, and automatically on every completed-work summary, next-actions list, or question to the user. Explains any skill, command, plan, decision, or finished work in plain English — table format, no jargon. Mode B is ONE 4-column table (Done/Ask | Why | Left + importance | Type this), ≤12 words per cell, ≤5 rows.
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

ONE table, exactly these 4 columns. One row per item — done items, asks, and leftovers all share it:

| Done / Ask | Why | Left + importance | Type this |
|---|---|---|---|
| Renamed /review to /health | name clash with built-in | nothing — done | — |
| Ask: pick column set | old format failed you | HIGH — blocks eli5 fix | answer here |
| Live-test the judge | unproven path | LOW — optional | `/design` |

Hard rules for Mode B:
- **≤12 words per cell. ≤5 rows.** Bullets/fragments, not sentences. Cut rows before cutting clarity — least important rows go first.
- Ask rows start with "Ask:" and their importance is why the answer matters. Nothing needed from user → no Ask row at all.
- "Why" is mandatory and honest — the concrete reason, or "safe to skip: …".
- "Left + importance" = what remains + HIGH/MED/LOW (or "nothing — done").
- "Type this" = exact command, "answer here" for asks, "—" otherwise.
- No jargon anywhere; translate technical terms inline.
- No prose paragraphs before/after the table — one lead-in sentence max.
