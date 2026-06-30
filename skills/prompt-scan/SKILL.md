---
name: prompt-scan
description: Use this skill when the user types /prompt-scan, says 'scan my prompts', or 'refresh learnings'. Scans system prompt files + fetches current model release notes → appends dated section to learnings.md for /better-prompt.
user-invocable: false
argument-hint: ""
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - WebFetch
---

Scan system prompts and build the learnings reference for `/better_prompt`.

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
Parse the model ID from the current session context ("The exact model ID is …"). Extract family + version (e.g. `claude-sonnet-4-6`). If unresolvable, write `model: unknown` and skip release notes.

**Release notes (WebFetch — skip gracefully if unavailable):**
- Fetch: `https://docs.anthropic.com/en/release-notes/claude-code`
- Fetch: `https://docs.anthropic.com/en/docs/about-claude/models/overview`
- Extract: what changed in `<model-id>` vs prior model — behavior, context window, tool use, output defaults
- If fetch fails: write "(release notes unavailable — run /prompt-scan again after checking network)"

---

## Step 3 — Write learnings.md

File: `~/.claude/learnings.md`

**If file does not exist:** Write with header:
```
# Learnings — Claude Code prompt context
```
then append the dated block below.

**If file exists:** Read it, then append the new block after the last `---` separator. Never overwrite prior entries — they compound.

**Dated block structure:**
```markdown
## Scan YYYY-MM-DD — model: <model-id>

### 1. Output conventions
<bullets from CLAUDE.generated.md and CLAUDE.md — format prefs, caveman mode, table vs prose, single-paste rule>

### 2. Scope rules
<from CORE_RULES.md — surgical changes, no unrelated edits, no cleanup, no speculation>

### 3. Planning rules
<from CORE_RULES.md — Opus plans / Sonnet codes, no inline planning, subagent execution>

### 4. Skill triggers
| Skill | Trigger | When to use |
|-------|---------|-------------|
<one row per skill from CLAUDE.md trigger blocks + SKILLS.md daily-driver table>

### 5. Slop patterns
<banned patterns from UI_MOCKUPS.md slop fingerprint + ANTISLOP.md if present — one bullet per pattern>

### 6. Model delta
<what changed in <model-id> vs prior model — from release notes fetch>

---
```

---

## Step 4 — Confirm

Tell user:
> **learnings.md updated** (`~/.claude/learnings.md`). Run `/better_prompt "[rough prompt]"` to use it.
> Next update: run `/prompt-scan` again when a new Claude model ships.
