---
description: Unified memory manager — view, add, move, delete, and audit facts
argument-hint: [a <fact> | d <id> | m <id> | audit | compile]
---

You are the memory manager. Handle the argument: **$ARGUMENTS**

---

## Step 1 — Detect context

Run these to establish paths:

```bash
CWD=$(pwd)
SLUG=$(echo "$CWD" | sed 's|/|-|g; s|\.|-|g')
echo "cwd=$CWD"
echo "slug=$SLUG"
echo "--- GLOBAL FACTS ---"
ls ~/.claude/memory/facts/*.md 2>/dev/null || echo "(none)"
echo "--- PROJECT FACTS (formal) ---"
ls ~/.claude/projects/$SLUG/memory/facts/*.md 2>/dev/null || echo "(none)"
echo "--- PROJECT MEMORY (auto) ---"
ls ~/.claude-work/projects/$SLUG/memory/*.md 2>/dev/null | grep -v MEMORY.md | grep -v SCHEMA.md || echo "(none)"
```

---

## Step 2 — Route by argument

### No argument → show table

Read every fact file found above. Output two tables:

**Global facts** (`~/.claude/memory/facts/`)

| id | type | status | description |
|----|------|--------|-------------|
| … | … | … | … |

**Project facts for `<slug>`** (formal facts/ + auto-memory files)

| id/file | source | status | summary |
|---------|--------|--------|---------|
| … | … | … | … |

Then show the action menu:
```
Actions: a <fact>  d <id>  m <id>  audit  compile
```
Stop. Wait for next input.

---

### `a <fact>` — Add a fact

1. **Infer tier** from cwd:
   - Inside a known project dir (has `.git` or project indicators) → `tier=project`
   - Otherwise → `tier=user`

2. **Show confirm line before writing** — do not skip this:
   - `tier=project`: `Saving to project memory for '<slug>' — confirm? (Y / g=save globally instead)`
   - `tier=user`: `Saving to global memory — confirm? (Y / p=save to project '<slug>' instead)`
   - Wait for user response. Adjust tier if they override.

3. **Check for duplicates** in the target store:
   - Exact match → tell user, stop.
   - Refines existing → update that fact, append to body, bump `updated:`.
   - Contradicts active fact → create with `status: needs-review`, `conflicts-with:`, stop and ask user to resolve.

4. **Classify** the fact:
   - `type`: `user` | `feedback` | `pattern` | `reference`

5. **Write fact file**:
   - `tier=user` → `~/.claude/memory/facts/<id>.md`
   - `tier=project` → `~/.claude/projects/$SLUG/memory/facts/<id>.md` (create dirs if needed)
   - Schema: `id, tier, type, name, description, status: active, captured: <today>, updated: <today>, confidence: 1.0, provenance, supersedes: [], superseded-by: null`

6. **Compile**:
   - `tier=user` → run `python3 ~/.claude/memory/bin/memory_compile.py`
   - `tier=project` → run `python3 ~/.claude/memory/bin/memory_compile.py` (it handles both)

7. Confirm: `Saved <id> (tier=<tier>) — live next session.`

---

### `d <id>` — Delete / supersede a fact

1. Find the fact file by id (search both global and project stores).
2. Show confirm: `Mark <id> as superseded? This removes it from compiled views. (Y/n)` — wait.
3. On Y: set `status: superseded`, `updated: <today>` in frontmatter. Do NOT delete the file.
4. Recompile: `python3 ~/.claude/memory/bin/memory_compile.py`
5. Confirm: `<id> marked superseded — removed from next session.`

---

### `m <id>` — Move fact between tiers

1. Find the fact by id.
2. Determine current tier and target tier (opposite).
3. Show confirm: `Move <id> from <current-tier> → <target-tier>? (Y/n)` — wait.
4. On Y:
   - Write fact to new location with `tier` updated.
   - Mark old file `status: superseded`, `superseded-by: <id>`.
5. Recompile.
6. Confirm: `<id> moved to <target-tier> — live next session.`

---

### `audit` — Flag stale and duplicate facts

Read all facts (global + all projects). Report as a table:

| id | issue | detail |
|----|-------|--------|
| … | stale-path | references path that doesn't exist |
| … | possible-duplicate | near-identical name+type as <other-id> |
| … | superseded | status=superseded, safe to delete file |
| … | old | captured > 180 days ago, verify still relevant |
| … | needs-review | unresolved conflict — blocks compile |

After table: `Run /memory d <id> to suppress, or /memory m <id> to relocate.`

---

### `compile` — Recompile all views

Run:
```bash
python3 ~/.claude/memory/bin/memory_compile.py
```

Show output. Done.

---

## Rules

- Never write to `CLAUDE.generated.md` directly — always recompile.
- Never skip the confirm step on any write, move, or delete.
- Project facts go to `~/.claude/projects/$SLUG/memory/facts/` (formal schema), not `~/.claude-work/`.
- Auto-memory files in `~/.claude-work/projects/$SLUG/memory/` are read-only in this command — show in table but don't write there. Direct user to promote them with `a` if they want them in the formal store.
