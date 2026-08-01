---
name: antislop
description: Use this skill when the user types /antislop, says 'check for slop', or 'is this AI slop'. Diagnoses AI writing/GUI slop tells against ANTISLOP.md — violations table + CLEAN/SLOP-DETECTED verdict. Diagnosis only — no rewrite.
user-invocable: true
argument-hint: "[text, code, or output to check]"
model: haiku
effort: low
allowed-tools:
  - Read
  - Bash
---

Check `$ARGUMENTS` for AI slop tells.

---

## Step 1 — Load checklists

Read `~/.claude/docs/ANTISLOP.md`.

Extract by heading **prefix** — never by exact title. Those headings carry counts that change every time the list is trimmed, and an exact match silently returns nothing:
- **Writing tells** — every bullet under the `##` heading beginning `## Writing Tells`, ignoring any `(N)` suffix. Each is a pattern name + examples.
- **GUI slop** — every bullet under the `##` heading beginning `## GUI Slop`, including all its `###` sub-sections. Read the sub-sections as they stand; do not assume a fixed set.

Print one line before continuing: `Loaded: <w> writing tells, <g> GUI tells.`

**Stop if either list came back empty — never judge against a list you failed to read:**
- File absent → `Run /prompt-scan first to build ANTISLOP.md.`
- Heading missing, or its bullets extract to zero → `ANTISLOP.md has no readable "<heading prefix>" section — renamed or moved. Fix it there or here. No verdict.`

A checker that looked in the wrong place has no result to report. `CLEAN` over an empty extraction is the exact failure this stop exists to prevent.

---

## Step 2 — Get target

If `$ARGUMENTS` is non-empty → use it as the target text.

If empty → stop: `Paste the text/output to check after /antislop.`

---

## Step 3 — Check each tell

### Pre-pass — free deterministic detector (source targets only)

If the target is source file paths rather than pasted prose, run the grep-level checker first. No model call, no API key, no cost:

```bash
timeout 30 npx -y impeccable detect --json <paths>
```

It matches mechanical source tells — `text-purple-600`, `nested-cards`, `animate-bounce`, `tight-leading`, `bg-clip-text`, `ai-color-palette` — complementing the judgement calls below, not replacing them.

- **Silent skip on any failure** — `npx` absent, offline, non-zero exit, timeout. Print `impeccable skipped — <reason>.` and carry on. Never block, never error, never retry.
- **Never run `impeccable install`.** It writes `PRODUCT.md` and `DESIGN.md` into the user's project. `detect` only, and it must work in a project never set up for impeccable.
- Its hits are **advisory** — they become rows tagged `detector` and never decide the verdict.

Skip the pre-pass entirely for prose targets; every rule it has is markup or CSS.

### Your own judgement

For every tell in Writing Tells + GUI Slop, mark **Found** if any of these hold:
- An exact forbidden word/phrase appears
- The sentence structure matches the pattern description
- For GUI slop: the described visual pattern is present in markup/CSS/description

Record the shortest excerpt (≤15 words) that demonstrates the violation. Quote the actual text — never describe it.

---

## Step 4 — Output

Emit only rows where Found = yes:

```
| Pattern | Source | Excerpt | Fix |
|---------|--------|---------|-----|
| Filler opener | judgement | "Certainly! I'd be happy to..." | Delete opener, start with the answer |
| ai-color-palette | detector | `text-purple-600` — Hero.tsx:12 | Use a brand token, not the default |
```

**The verdict counts judgement rows only** — `detector` rows are listed but never set it.

No judgement rows:
```
CLEAN — no slop patterns detected.
```
Append ` <n> advisory detector hit(s) listed above.` when the pre-pass found any.

Judgement rows present:
```
SLOP-DETECTED — N violations.
```

**Rules:**
- Diagnosis only — never rewrite the target
- Only show rows with actual violations — no "not found" rows
- Source column: `judgement` for your own calls, `detector` for impeccable hits
- Fix column: one-line instruction, not a rewrite
