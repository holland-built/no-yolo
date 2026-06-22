---
description: Capture a preference/fact into the memory store (auto-detects project vs global) and recompile
argument-hint: <the thing to remember>
---

The user wants to permanently remember: **$ARGUMENTS**

## Step 1 — Infer tier

```bash
CWD=$(pwd)
SLUG=$(echo "$CWD" | sed 's|/|-|g; s|\.|-|g')
# Is this a project dir? (has .git or known project indicators)
git -C "$CWD" rev-parse --git-dir 2>/dev/null && echo "HAS_GIT=true" || echo "HAS_GIT=false"
echo "slug=$SLUG"
```

- `HAS_GIT=true` → infer `tier=project`
- Otherwise → infer `tier=user`

## Step 2 — Show confirm line (REQUIRED — never skip)

- `tier=project`: output exactly: `Saving to project memory for '<slug>' — confirm? (Y / g=save globally instead)`
- `tier=user`: output exactly: `Saving to global memory — confirm? (Y / p=save to project '<slug>' instead)`

Wait for user response. Adjust tier if they override with `g` or `p`.

## Step 3 — Classify the fact

- `type`: `user` | `feedback` (a working preference) | `pattern` (a reusable technique) | `reference` (a pointer/ruleset)

## Step 4 — Check for duplicates / changes

Search the target store:
- `tier=user` → `~/.claude/memory/facts/`
- `tier=project` → `~/.claude/projects/$SLUG/memory/facts/`

Rules:
- Exact match exists → tell the user, do nothing.
- Refines an existing fact → update that fact (`updated:` date, append to body).
- Contradicts an active fact → DO NOT overwrite. Create with `status: needs-review` + `conflicts-with:`, ask user to confirm supersede or drop.

## Step 5 — Write the fact

- `tier=user` → `~/.claude/memory/facts/<id>.md`
- `tier=project` → `~/.claude/projects/$SLUG/memory/facts/<id>.md` (create dirs if needed)

Required frontmatter: `id, tier, type, name, description, status: active, captured: <today>, updated: <today>, confidence: 1.0, provenance (session + date), supersedes: [], superseded-by: null`

`description` is the one-liner the compiler lifts into the view — make it crisp and actionable.

Body: full statement; for feedback/pattern add **Why:** and **How to apply:**. Link related facts with `[[id]]`.

## Step 6 — Compile

```bash
python3 ~/.claude/memory/bin/memory_compile.py
```

If it aborts on `needs-review`, surface the conflict and STOP.

## Step 7 — Confirm to user

Bulleted:
- fact id
- tier (global or project `<slug>`)
- "live next session"
- any conflict needing resolution

Never edit `CLAUDE.generated.md` directly — it is rebuilt from facts.
