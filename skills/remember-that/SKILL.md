---
name: remember-that
description: Use this skill when the user types /remember-that, says 'remember that', 'save this to memory', or 'forget that'. Unified memory manager — add facts, extract from context, delete, move, audit, compile.
user-invocable: true
argument-hint: "<fact> | d <id> | m <id> | audit | compile | (empty=extract from context)"
model: haiku
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
---

Argument: **$ARGUMENTS**

---

## Step 1 — Establish context (always run first)

```bash
CWD=$(pwd)
SLUG=$(echo "$CWD" | sed 's|/|-|g; s|\.|-|g')
HAS_GIT=$(git -C "$CWD" rev-parse --git-dir 2>/dev/null && echo true || echo false)
echo "cwd=$CWD slug=$SLUG git=$HAS_GIT"
echo "--- GLOBAL ---"
ls ~/.claude/memory/facts/*.md 2>/dev/null || echo "(none)"
echo "--- PROJECT FORMAL ---"
ls ~/.claude/projects/$SLUG/memory/facts/*.md 2>/dev/null || echo "(none)"
echo "--- PROJECT AUTO ---"
ls ~/.claude-work/projects/$SLUG/memory/*.md 2>/dev/null | grep -v "MEMORY.md\|SCHEMA.md" || echo "(none)"
```

---

## Step 2 — Route on argument

Match **first token** in this order:

| First token | Action |
|---|---|
| *(empty)* | EXTRACT |
| `d` + second token present | DELETE `<id>` |
| `m` + second token present | MOVE `<id>` |
| `audit` (exact, only token) | AUDIT |
| `compile` (exact, only token) | COMPILE |
| anything else | ADD (strip optional leading `a ` from fact text) |

**Edge case:** if argument is exactly one of the reserved words (`audit`, `compile`) but the user seems to want it saved as a fact, ask: `"audit" — run audit, or save as fact? (audit / save)`. Wait for answer.

---

## ADD

1. **Infer tier**: `HAS_GIT=true` → `tier=project`; else `tier=user`

2. **Confirm (REQUIRED — never skip)**:
   - `tier=project` → output: `Saving to project memory for '<slug>' — confirm? (Y / g=save globally instead)`
   - `tier=user` → output: `Saving to global memory — confirm? (Y / p=save to project '<slug>' instead)`
   - Wait. Honor `g` or `p` override to flip tier.

3. **Dup check** in target store (`~/.claude/memory/facts/` or `~/.claude/projects/$SLUG/memory/facts/`):
   - Exact match → tell user, stop.
   - Refines existing → update that file: append to body, bump `updated:`.
   - Contradicts active → write new fact with `status: needs-review` + `conflicts-with: <id>`. Stop and ask user to resolve.

3b. **Canon-duplication guard** (global `user`/`feedback` facts): before writing, read `~/.claude/docs/CORE_RULES.md` and `~/.claude/CLAUDE.md` and judge whether the fact's rule is already stated there. If it is, **do NOT save** — canon is authoritative and both load every session, so a fact restating it is pure always-loaded waste (this is how `user-no-confirmation-questions` + `feedback-skill-triggers-location` duplicated rules 1/6 and the HARD RULE). Tell the user: `Already covered by <CORE_RULES rule N | CLAUDE.md HARD RULE> — not saving a duplicate. Edit canon instead if you want to change it.` Only save when the fact adds something canon does not already say.

4. **Classify** `type`: `user` | `feedback` | `pattern` | `reference`

5. **Write** `<id>.md` to target store (create dirs if needed). Use the full schema from `~/.claude/memory/SCHEMA.md`. Required frontmatter fields: `id, tier, type, name, description, status: active, captured: <today>, updated: <today>, confidence: 1.0, provenance (session + date), supersedes: [], superseded-by: null`.

   Body: full statement. For `feedback`/`pattern`: add **Why:** and **How to apply:** lines. Link related facts with `[[id]]`.

6. **Compile**: `python3 ~/.claude/memory/bin/memory_compile.py`

7. **Confirm**: `Saved <id> (tier=<tier>) — live next session.`

---

## EXTRACT (no-args default)

1. **Scan recent conversation context** — identify facts worth saving: decisions made, preferences stated, patterns discovered, architecture choices, constraints established. Ignore ephemeral task detail.

2. **Propose each candidate** one at a time:
   - Infer tier: inside a project repo (`HAS_GIT=true`) → `project`; else `global`
   - Output exactly this block per candidate:
     ```
     Found: "<crisp one-line description of the fact>"
     tier: global | project (<slug>)   type: feedback | pattern | user | reference
     Save? (Y / g=global / p=project / skip / done)
     ```
   - Wait for response. On Y or tier override → run ADD flow for that fact. On `skip` → next candidate. On `done` → stop proposing.

3. If no candidates found: output `Nothing new to save from this session.`

4. After all candidates processed (or `done`), always show the action menu grayed out:
   ```
   ─────────────────────────────────────────────
   Other actions: /remember-that <fact>  d <id>  m <id>  audit  compile
   ```

---

## DELETE

1. Find fact file by id (search global + project stores).
2. Confirm: `Mark <id> as superseded? Removes from compiled views. (Y/n)` — wait.
3. On Y: set `status: superseded`, `updated: <today>` in frontmatter. Do NOT delete the file.
4. Compile.
5. Confirm: `<id> marked superseded — removed from next session.`

---

## MOVE

1. Find fact by id. Note current tier.
2. Target = opposite tier.
3. Confirm: `Move <id> from <current-tier> → <target-tier>? (Y/n)` — wait.
4. On Y:
   - Write fact to new location with `tier` updated.
   - Mark old file `status: superseded`, `superseded-by: <id>`.
5. Compile.
6. Confirm: `<id> moved to <target-tier> — live next session.`

---

## AUDIT

Read all facts (global + all project stores). Output table:

| id | issue | detail |
|----|-------|--------|
| … | stale-path | references path that no longer exists |
| … | possible-duplicate | near-identical name+type as `<other-id>` |
| … | superseded | file still on disk, safe to archive |
| … | old | captured >180 days ago — still relevant? |
| … | needs-review | unresolved conflict — blocks compile |

Footer: `Use /remember-that d <id> to suppress, m <id> to relocate.`

Read-only — no writes.

---

## COMPILE

```bash
python3 ~/.claude/memory/bin/memory_compile.py
```

Show output. Done.

---

## Rules (always apply)

- Never edit `CLAUDE.generated.md` directly — it is rebuilt by compile.
- Never skip the confirm step on any write, move, or delete.
- Auto-memory files (`~/.claude-work/projects/*/memory/`) are read-only — show in table only. To promote to formal store, use ADD.
- If compile aborts on `needs-review`, surface the conflict and STOP.
