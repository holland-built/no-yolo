---
name: prompt-scan
description: Use this skill when the user types /prompt-scan, says 'scan my prompts', or 'refresh learnings'. Scans system prompt files + fetches current model release notes → appends dated section to learnings.md for /better-prompt.
user-invocable: true
argument-hint: ""
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - WebFetch
---

Scan system prompts and build the learnings reference for `/better-prompt`.

---

## Step 1 — Read System Prompt Files

Read each file in order. If a file is missing, note "(file absent)" for that section and continue — never abort.

| Step | File | What to extract |
|------|------|-----------------|
| 1 | `~/.claude/CLAUDE.md` | All `# <skill>` trigger blocks + pointer table |
| 2 | `~/.claude/docs/CORE_RULES.md` | All 5 Karpathy rules verbatim |
| 3 | `~/.claude/memory/CLAUDE.generated.md` | All compiled working preferences + patterns |
| 4 | `~/.claude/docs/HOOKS.md` | Active hook names + behaviors |
| 5 | `~/.claude/docs/SKILLS.md` | Daily-driver skill table |
| 6 | `~/.claude/docs/NO_YOLO.md` | Authoring standards (eli5, token economy, new-skill checklist) |
| 7 | `~/.claude/docs/UI_MOCKUPS.md` | Slop fingerprint list (lines with banned patterns) |
| 8 | `~/.claude/docs/ANTISLOP.md` | Extra slop rules (skip if absent) |

---

## Step 2 — Detect Model + Fetch Release Notes

**Model detection:**
Parse the model ID from the current session context ("The exact model ID is …"). Extract family + version (e.g. `claude-opus-4-8`, `claude-sonnet-5`, `claude-haiku-4-5`). If unresolvable, write `model: unknown` and skip release notes.

**Release notes — use these DIRECT 2026 URLs (the old `docs.anthropic.com` links now 301→`platform.claude.com`→GitHub, burning WebFetch retries on redirects):**

- **Models overview (WebFetch):** `https://platform.claude.com/docs/en/docs/about-claude/models/overview`
  - Direct hit, no redirect. Extract: what changed in `<model-id>` vs prior model — behavior, context window, max output, thinking mode (extended vs adaptive), pricing tier, knowledge cutoff.
- **Claude Code changelog (Bash curl, NOT WebFetch):** the release-notes doc redirects to GitHub's HTML view which renders no content — pull the raw file instead:
  ```bash
  curl -sL --max-time 15 https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md | head -150
  ```
  - Extract latest ~5 versions' highlights — model behavior, tool use, output defaults, subagent/permission changes.
- If a fetch fails: write "(release notes unavailable — run /prompt-scan again after checking network)" for that source and continue.
- Do NOT retry `docs.anthropic.com/*` or `platform.claude.com/docs/en/release-notes/claude-code` — both redirect; use the two direct sources above.

---

## Step 3 — Write learnings.md

File: `~/.claude/learnings.md`

**Structure — DO NOT append full dated blocks (that repeats §1–5 every scan and bloats the file). The file has two parts:**
1. **Living snapshot (§1–5)** — OVERWRITE in place each scan. These conventions rarely change, so they must NOT compound.
2. **Dated model-delta log (§6)** — PREPEND one entry per scan (newest first). This is the only part that grows. If an entry for `<today>` already exists (e.g. re-scan after a `/model` switch), REPLACE it — never two same-day entries.

**If file does not exist:** Write the full skeleton below.

**If file exists:** Read it, then:
- Rewrite the `## Current conventions — living snapshot (last refreshed: …)` heading + §1–5 with fresh content, updating the date/model stamp.
- Prepend a new `### <today> — <model-id>` entry to the top of the §6 dated log (right under the `## 6. Model delta` header). If a `### <today> — …` entry already exists, replace it instead of adding a second.
- Leave all prior-day §6 entries untouched — they compound intentionally.

**File skeleton:**
```markdown
# Learnings — Claude Code prompt context

> **How this file works:** §1–5 are a LIVING snapshot — /prompt-scan OVERWRITES them each run. §4 is derived from each skill's own SKILL.md `description`. §6 is an append-only dated log — each scan PREPENDS one entry. /better-prompt reads §1–6.

---

## Current conventions — living snapshot (last refreshed: YYYY-MM-DD — model: <model-id>)

### 1. Output conventions
<bullets from CLAUDE.generated.md and CLAUDE.md — format prefs, caveman mode, table vs prose, single-paste rule>

### 2. Scope rules
<from CORE_RULES.md — surgical changes, no unrelated edits, no cleanup, no speculation>

### 3. Planning rules
<from CORE_RULES.md — Opus plans / Sonnet codes, no inline planning, subagent execution>

### 4. Skill triggers
> Derived from each skill's own SKILL.md `description` — the source of truth the harness injects.
> `docs/SKILL_TRIGGERS.md` no longer carries per-skill blocks (they duplicated these descriptions).
> Regenerate on each scan; do not hand-edit.

| Skill | Trigger | When to use |
|-------|---------|-------------|
<one row per tracked skill — generate with:>
<  for f in $(git -C ~/.claude ls-files 'skills/*/SKILL.md'); do>
<    printf '%s\t%s\n' "$(basename $(dirname $f))" "$(grep -m1 '^description:' ~/.claude/$f | cut -d: -f2-)"; done>
<map each to Skill | trigger phrases from its description | condensed when-to-use>

### 5. Slop patterns
<banned patterns from UI_MOCKUPS.md slop fingerprint + ANTISLOP.md if present — one bullet per pattern>

---

## 6. Model delta — dated log (append-only, newest first)

### YYYY-MM-DD — <model-id>
<what changed in <model-id> vs prior model — from release notes fetch>
```

---

## Step 3b — Verify the write (guard /better-prompt)

`/better-prompt` parses sections §1–6. After writing, confirm all six headers exist:
```bash
grep -cE "^### [1-5]\.|^## 6\. Model delta" ~/.claude/learnings.md   # expect 6
```
If the count is not 6, the write is malformed — fix it before confirming.

---

## Step 4 — Confirm

Tell user:
> **learnings.md updated** (`~/.claude/learnings.md`). Run `/better-prompt "[rough prompt]"` to use it.
> Next update: run `/prompt-scan` again when a new Claude model ships.
