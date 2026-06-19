---
description: Scan recent session for corrections and patterns, write as memory facts to ~/.claude/memory/facts/
---

# Log Learnings → Memory

Scan the last 30 turns for learnable moments. Write each as a fact file to `~/.claude/memory/facts/`. Recompile views when done.

## What to capture

**feedback** — corrections AND confirmations:
- Corrections: user said "no", "don't", "stop doing X", "actually Y", "wrong approach"
- Confirmed patterns: "yes exactly", "perfect keep doing that", accepted unusual choice without pushback

**user** — new info about role, stack, preferences, working style

**pattern** — recurring workflow or code approach worth preserving

**Skip:** one-off fixes, things derivable from code, simple typos

## Steps

1. **Scan** last 30 turns. List candidate learnings (1 sentence each).

2. **Dedupe** — check existing slugs:
   ```bash
   ls ~/.claude/memory/facts/
   ```
   Skip any candidate that maps to an existing fact. If an existing fact needs strengthening, note it but don't create a duplicate.

3. **For each new learning**, write `~/.claude/memory/facts/<slug>.md`:

   ```yaml
   ---
   id: <kebab-case-slug>
   tier: user
   type: feedback | user | pattern | project | reference
   name: Short human title
   description: One line — used to decide relevance in future sessions
   status: active
   captured: YYYY-MM-DD
   updated: YYYY-MM-DD
   confidence: 1.0
   provenance:
     - session: manual-log
       date: YYYY-MM-DD
       note: logged via /log
   supersedes: []
   superseded-by: null
   ---

   <rule or fact>

   **Why:** <reason user gave, or inferred from pushback>

   **How to apply:** <when this kicks in, edge cases>
   ```

4. **Recompile** views:
   ```bash
   python3 ~/.claude/memory/bin/memory_compile.py
   ```

5. **Report** — bullet per finding:
   - ✅ Written: `<slug>` — `<one-line summary>`
   - ⏭ Skipped: `<slug>` — already exists / one-off / not worth keeping

If 0 new learnings: output `No new learnings this session.`
