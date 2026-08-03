---
name: eli5
description: Use this skill when the user types /eli5, says 'as a table', 'table that', 'reprint that', 'again in plain words', or 'in a chart', and automatically on every completed-work summary, next-actions list, or question to the user. Explains any skill, command, plan, decision, or finished work in plain English, no jargon, table-shaped. Mode C reprints the answer just given as a table, with no argument and nothing re-researched.
user-invocable: true
argument-hint: "[skill name, plan text, command, or file path]"
model: haiku
effort: low
allowed-tools:
  - Bash
  - Read
---

# eli5

Explain what something actually does before the user says yes to it.

## How to run

### Step 0a — reprint mode (check this FIRST)

If the user is pointing at the answer you just gave — "as a table", "table that",
"reprint that", "again in plain words", "in a chart", or a bare `/eli5` right after
a prose answer — this is **Mode C**. Do NOT show the skill picker, do NOT read any
file, do NOT re-run any research.

Take the immediately preceding assistant message and re-emit it as a table. Same
facts, nothing added, nothing looked up again. Columns come from the content:
`| Thing | State |`, `| Option | What you get |`, `| File | Problem | Fix |`,
`| Step | Does what |`. Up to 8 rows, a short phrase per cell, no jargon. One short
line of context after the table if it genuinely needs one. Then stop.

If the previous answer had only one fact in it, say that one fact in one sentence
and note there was nothing to tabulate.

### Step 0 — no argument

If Step 0a did not apply and no argument was provided, run:

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

The user is non-technical. Plain words and table shape are both constant. **Pick the form by the content:**

**A genuine single fact — one reminder, one next step → ONE plain sentence.** No table.
> Saved and switched on. Next: run `/memory-compile` when you want it live.

**Everything else — two or more facts, findings, options, files, steps or states → a table.** This is the default, not the exception:

| What | Status | Type this |
|---|---|---|
| Renamed /review to /health | done | — |
| Pick eli5 format | need your call | answer here |
| Live-test the judge | optional | `/design` |

Hard rules for Mode B:
- **A few words per cell, up to 8 rows.** Fragments, not sentences. More than 8 rows means the answer is too broad — cut rows, never spill into prose.
- **No jargon anywhere.** Translate any technical term inline, or cut it. "md file", "supersede", "compile" → say what it does.
- **No mandatory "why."** Add a reason ONLY if it's short and changes the decision — never a paragraph, never history/justification padding.
- Asks say plainly what you need; options spelled "A: … / B: …" in plain words.
- One short line of context, before or after the table — never both, never a paragraph. When unsure between a sentence and a table, use the table.

## Every turn — where we are, how long, what next

<!-- Four rules adapted from ayghri/i-have-adhd (MIT). Only these four — the rest of
     that skill is action-first for a different reader, and table-first stays primary.
     Upstream drift is tracked in docs/THIRD_PARTY_SKILLS.md (pinned d05af1e). -->

These apply in **both** modes, on top of the shape rules above.

| Rule | What it means |
|---|---|
| **Say where we are** | The reader cannot hold "we are on step 3 of 5" between messages. Work that spans turns names its own position every time: what just finished, what is next. Bad: "Done. Ready for the next part?" Good: "Step 3 of 5 done: schema updated. Next: backfill the new column." If a task or checklist tool is already showing the plan, that IS the restating — don't narrate it as prose as well. |
| **Real time estimates** | "A bit of work" and "a few hours" land as the same non-answer. Ballpark in concrete units: "about 15 minutes if tests already cover this, an afternoon if not." When a subagent does the work, aim the estimate at whoever executes the steps. |
| **One next action** | If anything is left open, end with ONE thing doable in under two minutes. Even "open the file" counts. Never "let me know if you want to dig deeper". |
| **Five items, ranked** | A list of ACTIONS or OPTIONS the reader must act on or pick between stops at 5. Past five, split it — "do now" vs "later", or "must" vs "nice to have". Five ranked beats ten unranked. |

**5 and 8 are two different ceilings, not a contradiction.** A table of facts, files
or states may run to 8 rows. A list of things the reader has to do or choose caps at 5.
