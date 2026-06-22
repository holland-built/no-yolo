---
name: antislop
description: Diagnose AI writing/GUI slop tells in any text, code, or UI output. Checks input against ANTISLOP.md writing tells + GUI slop list. Outputs violations table + CLEAN/SLOP-DETECTED verdict. Diagnosis only — no rewrite. Activate on "/antislop", "check for slop", "is this AI slop".
user-invocable: true
argument-hint: "[text, code, or output to check]"
allowed-tools:
  - Read
  - Bash
---

Check `$ARGUMENTS` for AI slop tells.

---

## Step 1 — Load checklists

Read `~/.claude/ANTISLOP.md`.

Extract:
- **Writing tells**: all bullets under `## Writing Tells (25)` — each is a pattern name + examples
- **GUI slop**: all bullets under `## GUI Slop`

If file absent → stop: `Run /prompt-scan first to build ANTISLOP.md.`

---

## Step 2 — Get target

If `$ARGUMENTS` is non-empty → use it as the target text.

If empty → stop: `Paste the text/output to check after /antislop.`

---

## Step 3 — Check each tell

For every tell in Writing Tells + GUI Slop:

Scan the target for the pattern. Mark **Found** if any of these:
- An exact forbidden word/phrase appears
- The sentence structure matches the pattern description
- For GUI slop: the described visual pattern is present in markup/CSS/description

Record the shortest excerpt (≤15 words) that demonstrates the violation.

---

## Step 4 — Output

Emit only rows where Found = yes:

```
| Pattern | Excerpt | Fix |
|---------|---------|-----|
| Filler opener | "Certainly! I'd be happy to..." | Delete opener, start with the answer |
| Em-dash spam | "The fix—which is simple—needs—testing" | Use commas or restructure |
```

If no violations found:
```
CLEAN — no slop patterns detected.
```

If violations found:
```
SLOP-DETECTED — N violations.
```

**Rules:**
- Diagnosis only — never rewrite the target
- Only show rows with actual violations — no "not found" rows
- Excerpt must quote the actual text, not describe it
- Fix column: one-line instruction, not a rewrite
