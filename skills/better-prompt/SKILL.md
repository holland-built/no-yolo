---
name: better-prompt
description: Use this skill when the user types /better-prompt, says 'sharpen this prompt', or 'improve my prompt'. Rewrites a rough prompt against learned conventions in learnings.md. Second mode — refresh — fires on /better-prompt --refresh, 'refresh learnings', 'scan my prompts', or 'a new model shipped'; it rebuilds learnings.md from the rule files plus current release notes.
user-invocable: true
argument-hint: "[rough prompt text to sharpen] | --refresh"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - WebFetch
---

Input: $ARGUMENTS

## Mode select

| Argument | Mode |
|---|---|
| `--refresh`, or the user says "refresh learnings" / "scan my prompts" | **Refresh** — rebuild `learnings.md`, then stop |
| Anything else | **Sharpen** — rewrite the prompt |
| Empty | Stop: `Paste the prompt you want sharpened after /better-prompt, or use --refresh to rebuild the reference.` |

---

# Sharpen mode

## Step 1 — Load the reference

Read `~/.claude/learnings.md`. If missing or empty, stop:
> `⚠️ learnings.md not found — run /better-prompt --refresh first.`

Check staleness, warn but never stop:
```bash
find ~/.claude/learnings.md -mtime +90 2>/dev/null | grep -q . && echo "STALE" || echo "OK"
```
> `⚠️ learnings.md is over 90 days old — run /better-prompt --refresh (a new Claude model may have shipped).`

Parse into working memory: output conventions (§1), scope rules (§2), planning rules (§3),
skill triggers (§4), slop patterns (§5), model delta (§6).

For §7, detect the session model family from context ("The exact model ID is …" →
fable/opus/sonnet/haiku) and load **only** that family's `### <family>` subsection. The
rewrite must follow the rules for the model actually running; ignore the other three.

## Step 2 — Well-formed check

Skip the rewrite if ALL are true:

- Names a concrete target — file, component, function or path, not "the thing" or "it"
- States a success criterion or expected output
- Has an explicit scope boundary, or is trivially single-file
- Specifies an output format, if it asks for analysis or a report
- Routes to a skill consistent with §4, or genuinely needs none

If all pass, output `Prompt is already well-formed — no rewrite needed.` plus one line
naming the criterion that carried it.

## Step 3 — Diagnose

Check all, report only what applies:

| Gap | Looks like |
|---|---|
| Vague verb | "fix", "improve", "look at" with no concrete target |
| Missing scope | No file path, function name, or bounded surface |
| No success criterion | No expected output, no measurable done condition |
| No output format | An analysis ask with no table/bullet/format spec |
| Wrong skill | Names a skill whose §4 triggers don't match the intent |
| Missing skill | A relevant skill exists in §4 but isn't mentioned |
| Slop risk | Would likely produce output matching a §5 pattern |

## Step 4 — Rewrite

ONE copy-pasteable block, no numbered steps inside it. It must carry:

- Concrete target (`file:line` or component name)
- Explicit scope boundary — "only touch X, do not modify Y"
- Success criterion — "done when Z"
- Output format — "respond as a markdown table", "bullets only"
- The correct skill route, if one applies

If the rough prompt names `/X` but §4 says `/Y` fits better, silently swap it.

## Step 5 — Verify

**(a) Structure.** Any failure → fix, re-check once, continue.

- Single fenced block, nothing outside it
- Concrete target present
- Explicit scope boundary present
- Success criterion present
- Output-format clause present when the ask is analytical
- No unresolved placeholders — scan for `<…>`, `TODO`, `TBD`, `FIXME`, `XXX`, `[ ]`, bare `...`

**(b) Slop check.** Read `~/.claude/docs/ANTISLOP.md` and check the rewritten block against
the writing tells. This is a distinct pass over finished text, not a re-read while writing.
Fix anything it catches, then re-run (a).

## Step 6 — Output

The rewritten prompt only. A single fenced block, zero surrounding text. No "Before", no
"Why", no rationale bullets, no "Run with" line.

- Never invent a skill that isn't in §4
- If a skill applies, it is the first word of the rewrite (e.g. `/health ...`)

---

# Refresh mode

## Step 1 — Read the rule files

Missing file → note "(file absent)" and continue. Never abort.

| File | Extract |
|---|---|
| `~/.claude/CLAUDE.md` | Imports and the conditioned pointer list |
| `~/.claude/docs/CORE_RULES.md` | The core rules and the Lessons block |
| `~/.claude/memory/CLAUDE.generated.md` | Compiled working preferences and patterns |
| `~/.claude/docs/CODE_REVIEW.md` | Scope rules — surgical and simplicity filters |
| `~/.claude/docs/SUBAGENTS.md` | Planning rules — model split, dispatch scope, when to delegate |
| `~/.claude/docs/ANTISLOP.md` | **The canonical writing-slop list.** Read its own header for current counts; never assume a number |
| `~/.claude/docs/GUI_SLOP.md` | **The canonical GUI-slop list**, including the mockup-only kill rules. Same rule on counts |

## Step 2 — Detect the model, fetch release notes

Parse the model ID from session context. Extract family + version. If unresolvable, write
`model: unknown` and skip the fetch.

- **Models overview (WebFetch):** `https://platform.claude.com/docs/en/docs/about-claude/models/overview`
  — extract what changed in `<model-id>` vs the prior model: behavior, context window, max
  output, thinking mode, pricing tier, knowledge cutoff.
- **Claude Code changelog (Bash curl, not WebFetch)** — the release-notes doc redirects to a
  GitHub HTML view that renders no content, so pull the raw file:
  ```bash
  curl -sL --max-time 15 https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md | head -150
  ```
- A failed fetch writes "(release notes unavailable)" and continues. Do **not** retry
  `docs.anthropic.com/*` or `platform.claude.com/docs/en/release-notes/claude-code` — both
  redirect and burn retries.

## Step 3 — Write learnings.md

Three parts, each with its own update rule. Getting this wrong is what bloats the file.

| Part | Update rule |
|---|---|
| §1–5 living snapshot | **Overwrite in place.** These rarely change and must not compound |
| §6 model delta | **Prepend** one dated entry, newest first. Same-day entry exists → replace it, never two |
| §7 per-model rules | Update **only** the subsection for the running model. The other three were written by scans on those models |

Skeleton, if the file doesn't exist:

```markdown
# Learnings — Claude Code prompt context

## Current conventions — living snapshot (last refreshed: YYYY-MM-DD — model: <model-id>)

### 1. Output conventions
<from CLAUDE.generated.md and CLAUDE.md — format prefs, plain-English mode, table vs prose, single-paste rule>

### 2. Scope rules
<from CODE_REVIEW.md and CORE_RULES.md — every changed line traces to the ask, no unrelated edits, no speculative refactors>

### 3. Planning rules
<from SUBAGENTS.md — model split, never plan inline, subagent execution, bound the blast radius in every dispatch>

### 4. Skill triggers

| Skill | Trigger | When to use |
|---|---|---|
<one row per skill — generate with:>
<  for f in $(git -C ~/.claude ls-files 'skills/*/SKILL.md'); do>
<    printf '%s\t%s\n' "$(basename $(dirname $f))" "$(grep -m1 '^description:' ~/.claude/$f | cut -d: -f2-)"; done>

### 5. Slop patterns
<from ANTISLOP.md — one bullet per writing tell. Then from GUI_SLOP.md — one bullet per GUI sub-section, with its mockup-only kill rules as a short trailing group. Counts from each file's own header, never from this template.>

## 6. Model delta — dated log (newest first)

### YYYY-MM-DD — <model-id>
<what changed vs the prior model>

## 7. Per-model prompt rules (update only the running model's subsection)

### fable
### opus
### sonnet
### haiku
```

## Step 4 — Verify the write

Sharpen mode parses §1–7. Confirm the headers survived:
```bash
grep -cE "^### [1-5]\.|^## 6\. Model delta|^## 7\. Per-model" ~/.claude/learnings.md   # expect 7
grep -cE "^### (fable|opus|sonnet|haiku)$" ~/.claude/learnings.md                      # expect 4
```
Either count off means the write is malformed. Fix it before confirming.

## Step 5 — Confirm

> **learnings.md updated.** Run `/better-prompt "[rough prompt]"` to use it.
> Refresh again when a new Claude model ships.
