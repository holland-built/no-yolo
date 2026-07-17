---
name: better-prompt
description: Use this skill when the user types /better-prompt, says 'sharpen this prompt', or 'improve my prompt'. Rewrites a rough prompt against learned conventions from learnings.md.
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
> `⚠️ learnings.md not found — run /prompt-scan first to build the reference.`

If present, check file age:
```bash
find ~/.claude/learnings.md -mtime +90 2>/dev/null | grep -q . && echo "STALE" || echo "OK"
```
If STALE → warn (do NOT stop):
> `⚠️ learnings.md is over 90 days old — consider running /prompt-scan to refresh (a new Claude model may have shipped).`

If present: parse into working memory:
- Output conventions (§1)
- Scope rules (§2)
- Planning rules (§3)
- Skill triggers table (§4)
- Slop patterns (§5)
- Model delta (§6)
- Per-model prompt rules (§7): detect the session model family from context ("The exact model ID is …" → fable/opus/sonnet/haiku) and load ONLY that family's `### <family>` subsection — the rewrite must follow the rules for the model actually running; ignore the other three subsections

---

## Step 2 — Load Prompt

If `$ARGUMENTS` is empty → stop:
> `Paste the prompt you want sharpened after /better-prompt.`

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

Output the rewritten prompt only — a single fenced block, nothing else. No "Before", no "Why", no rationale bullets, no "Run with" line.

```
\```
<rewritten prompt — single block, copy-pasteable>
\```
```

Rules:
- Single fenced block, zero surrounding text
- Never invent skills not in learnings.md Skill triggers
- If a skill applies, include it as the first word of the rewritten prompt (e.g. `/review ...`)
- If wrong skill was named in the rough prompt, silently correct it in the rewrite
