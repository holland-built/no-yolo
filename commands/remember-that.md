---
description: Capture a preference/fact into the curated global memory store and recompile
argument-hint: <the thing to remember>
---

The user wants to permanently remember: **$ARGUMENTS**

Run the capture pipeline:

1. **Classify** the fact:
   - `tier`: `user` if it holds true across all projects (identity, preferences, transferable lessons); `project` if it names a specific repo/path/branch/product/schema.
   - `type`: `user` | `feedback` (a working preference) | `pattern` (a reusable technique) | `reference` (a pointer/ruleset).

2. **Check for duplicates / changes** in `~/.claude/memory/facts/` (and the active project's `memory/facts/` if tier=project):
   - Exact match exists → tell the user, do nothing.
   - Refines an existing fact → update that fact (`updated:` date, append to body).
   - Contradicts an active fact → DO NOT overwrite. Create the new fact with `status: needs-review` + `conflicts-with:`, and ask the user to confirm supersede or drop.

3. **Write the fact** to `~/.claude/memory/facts/<id>.md` (tier=user) or the project's `memory/facts/<id>.md` (tier=project), using the schema in `~/.claude/memory/SCHEMA.md`:
   - Required frontmatter: `id, tier, type, name, description, status: active, captured: <today>, updated: <today>, confidence: 1.0, provenance (session + date), supersedes: [], superseded-by: null`.
   - `description` is the one-liner the compiler lifts into the view — make it crisp and actionable.
   - Body: full statement; for feedback/pattern add **Why:** and **How to apply:**. Link related facts with `[[id]]`.

4. **Compile**:
   ```bash
   python3 ~/.claude/memory/bin/memory_compile.py
   ```
   If it aborts on `needs-review`, surface the conflict and STOP.

5. **Confirm** to the user (bulleted): the fact id, tier, and "live next session" — plus any conflict needing their decision.

Never edit `CLAUDE.generated.md` directly — it is rebuilt from facts. Edit facts only.
