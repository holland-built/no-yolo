---
name: design-audit
description: Use this skill when the user types /design-audit, says 'audit this UI', 'review the design', 'find design problems', or 'what's wrong with this UI'. Read-only — zero code, zero mockups, zero edits. 5 parallel lenses -> adversarial verification of every Critical -> ranked violations table + dependency-ordered P0/P1/P2 implementation plan. 'Fix it' afterward redirects to /impeccable.
user-invocable: true
argument-hint: "[surface to audit]"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Agent
---

# design-audit

Target: $ARGUMENTS

**Read-only. No code, no mockups, no edits.** Output is two artifacts the user can hand to
`/design` or `/impeccable`.

## Step 0 — Detect project
```bash
head -20 CLAUDE.md 2>/dev/null
cat package.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('name','?'), d.get('description',''))" 2>/dev/null
```
State one line: `Project: [type] · stack: [X]`. Detect whether a brand DESIGN.md
(Awesome DESIGN.md 9-section format) is in use.

## Step 1 — 5 parallel lens agents
ONE parallel Agent call. Each returns `severity | rule | file:line | observed | expected`.
1. **Taste** — anti-slop fingerprint (FALLBACKS if sub-skill absent).
2. **Swiss** — grid / type scale / color count.
3. **UIwiki** — 20 rules scored.
4. **WCAG 2.1 AA** — contrast, focus-visible, keyboard, aria, reduced-motion.
5. **CSS health** — hardcoded values, magic numbers, inconsistent tokens.
If a brand DESIGN.md is in use, add a **6th lens**: compare the UI against that brand's
do's/don'ts and component states.

## Step 2 — Adversarial verify
Spawn an independent agent that challenges every **Critical** finding. Each Critical must be
confirmed with file:line evidence or downgraded. Record the verdict per finding.

## Step 3 — Two output artifacts
1. **Ranked violations table:** `| # | Lens | Finding | Severity | file:line |`
   (Critical / High / Medium / Low).
2. **Dependency-ordered implementation plan:** `| Priority | Change | Depends on | Scope (S/M/L) |`
   grouped P0 / P1 / P2.
Then run `/eli5` on the summary.

## Redirect
If the user says "fix it" / "apply these" after the audit -> run `/impeccable` (or `/design`
for a clean-sheet redesign). This skill never edits.

---

## FALLBACKS
Same Taste / Swiss / UIwiki rule text as `/design`.
