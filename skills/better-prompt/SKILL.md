---
name: better-prompt
description: Rewrite a rough prompt to be sharper and aligned with learned conventions. Reads ~/.claude/learnings.md (written by /prompt-scan). Activate on "/better_prompt", "sharpen this prompt", "improve my prompt".
user-invocable: true
argument-hint: "[rough prompt text to sharpen]"
allowed-tools:
  - Read
  - Bash
---

Rough prompt: $ARGUMENTS

---

## Step 1 — Load Reference

Read `~/.claude/learnings.md`.

If missing or empty → stop:
> `Run /prompt-scan first to build the reference.`

If present: parse into working memory:
- Output conventions (§1)
- Scope rules (§2)
- Planning rules (§3)
- Skill triggers table (§4)
- Slop patterns (§5)
- Model delta (§6)

---

## Step 2 — Load Prompt

If `$ARGUMENTS` is empty → stop:
> `Paste the prompt you want sharpened after /better_prompt.`

---

## Step 3 — Well-formed Check

Skip rewrite if ALL of these are true:
- Names a concrete target (file, component, function, or path) — not just "the thing" or "it"
- States a success criterion or expected output
- Has an explicit scope boundary OR is trivially single-file
- Specifies output format if it asks for analysis or a report
- References a skill consistent with learnings.md skill triggers (or genuinely needs none)

If all pass → output:
> `Prompt is already well-formed — no rewrite needed.`
> One line explaining which criterion made it pass.

---

## Step 4 — Diagnose

Identify every gap (check all, report only those that apply):
- **Vague verb** — "fix", "improve", "look at" without a concrete target
- **Missing scope** — no file path, no function name, no bounded surface
- **No success criterion** — no expected output, no measurable done condition
- **No output format** — analysis prompt with no table/bullet/format spec
- **Wrong skill** — prompt names a skill that doesn't match its intent per learnings.md triggers
- **Missing skill** — a relevant skill exists in learnings.md but isn't mentioned
- **Slop risk** — prompt would likely produce output matching a slop pattern from learnings.md

---

## Step 5 — Rewrite

Write ONE copy-pasteable block. Do not use numbered steps inside the rewrite. Include:
- Concrete target (file:line or component name)
- Explicit scope boundary ("only touch X, do not modify Y")
- Success criterion ("done when Z")
- Output format ("respond as a markdown table" / "bullets only" / etc.)
- Correct skill route if one applies

Wrong-skill handling: if the rough prompt names skill `/X` but learnings.md triggers say `/Y` fits better, replace `/X` with `/Y` in the rewrite.

---

## Step 6 — Output

```
**Before:**
\```
<original rough prompt verbatim>
\```

**After:**
\```
<rewritten prompt — single block, copy-pasteable>
\```

**Why:**
- <rationale bullet 1 — cite the learned rule, e.g. "added scope boundary — Scope rules">
- <rationale bullet 2>
- <rationale bullet 3>

**Run with:** `/<skill>` — <one line on why this skill fits>
```

Rules:
- Exactly 3 rationale bullets, each citing the learned rule that drove the change
- Never invent skills not in learnings.md Skill triggers
- Output is fenced blocks + bullets only — no prose paragraphs
- If wrong skill was replaced: one of the 3 bullets must be `routed /<old> → /<new> per Skill triggers`
