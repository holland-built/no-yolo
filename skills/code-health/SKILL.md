---
name: code-health
description: Use this skill when the user types /code-health, says 'code health', 'run health pass', or 'fallow pass'. Three-phase health pass: Fallow (static analysis) → Trim (YAGNI review) → Improve (shadcn, token waste + YAGNI plan). All output as tables.
user-invocable: true
argument-hint: "[path/goal, or --auto to skip confirmation gates for AFK use]"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

Target: $ARGUMENTS (default: current directory)

**Flag:** `--auto` in $ARGUMENTS skips all confirmation gates (AFK/unattended mode). Auto-answers "no" to fallow fix prompt and auto-proceeds between phases. Without `--auto`, gates block as normal.

## Output Rule (ALL phases)

Every finding set is a markdown table. No prose summaries, no bullet lists, no inline commentary. If a command produces zero findings, output a one-row table: `| — | No findings | — |`. Numbers in monospace. Columns below are the spec — match them exactly.

---

## Pre-flight

Before Phase 1, silently run:

```bash
which fallow && fallow --version
ls ~/.agents/skills/ | grep -i "^trim-audit$" 2>/dev/null && echo "trim-audit:ok" || echo "trim-audit:missing"
ls ~/.agents/skills/ | grep -i "^trim-debt$" 2>/dev/null && echo "trim-debt:ok" || echo "trim-debt:missing"
ls ~/.agents/skills/ | grep -i "^improve$" 2>/dev/null && echo "improve:ok" || echo "improve:missing"
ls ~/.agents/skills/ | grep -i "^trim-review$" 2>/dev/null && echo "trim-review:ok" || echo "trim-review:missing"
```

Output a single status table:

| Tool | Status | Install if missing |
|---|---|---|
| Fallow | ✅ installed / ❌ missing | `npm install -g fallow` |
| Trim (review) | ✅ installed / ❌ missing | `npx skills@latest add DietrichGebert/trim` |
| Trim (audit) | ✅ installed / ❌ missing | `npx skills@latest add DietrichGebert/trim` |
| Trim (debt) | ✅ installed / ❌ missing | `npx skills@latest add DietrichGebert/trim` |
| Improve | ✅ installed / ❌ missing | `npx skills@latest add shadcn/improve` |

If Fallow is missing: STOP. Show the status table, tell the user to install Fallow first.
If Trim or Improve are missing: note it, continue — those phases will show an install gate and stop there.

---

## Phase 0 — Trim Review (diff-scoped, only if changes exist)

```bash
git diff --stat HEAD 2>/dev/null | head -5
git status --short 2>/dev/null | head -5
```

**If staged or uncommitted changes exist AND trim-review is installed:** invoke the `trim-review` skill. It reviews the diff and finds what to delete from your changes specifically.

Reformat output as a table:

| File | Finding | Category | Priority |
|---|---|---|---|
| `path/file.ts` | description | Delete / Shrink / YAGNI | High / Med / Low |

**If no diff (clean working tree):** skip silently — note "Phase 0: skipped (clean tree)" in the final roll-up.

**If trim-review not installed:** skip silently — note "Phase 0: skipped (not installed)" in the final roll-up.

No gate after Phase 0 — continue straight to Phase 1.

---

## Phase 1 — Fallow (Static Analysis)

Run each command in order. After ALL Fallow commands complete, show one consolidated table per command. Do not interleave prose.

### 1a — Dead Code

```bash
fallow dead-code $ARGUMENTS 2>&1
```

Table format:

| File | Symbol | Type | Why Dead |
|---|---|---|---|
| `path/file.ts` | `exportName` | export / import / dep | unused / unreachable / no callers |

### 1b — Duplication

```bash
fallow dupes $ARGUMENTS 2>&1
```

Table format:

| File A | File B | Lines | Similarity | Note |
|---|---|---|---|---|
| `a.ts:12` | `b.ts:45` | 18 | 94% | copy-paste / structural clone |

### 1c — Health

```bash
fallow health $ARGUMENTS 2>&1
```

Table format:

| File | Complexity | Maintainability | Hotspot | Flag |
|---|---|---|---|---|
| `path/file.ts` | 24 | D | ✅ | high cyclomatic / low coverage |

### 1d — Security

```bash
fallow security $ARGUMENTS 2>&1
```

Table format:

| File | Finding | Risk | Note |
|---|---|---|---|
| `path/file.ts` | hardcoded secret / open exec | High / Med / Low | brief context |

### 1e — Audit (diff-scoped, only if in a git repo)

```bash
git rev-parse --git-dir 2>/dev/null && fallow audit $ARGUMENTS 2>&1 || echo "not a git repo — skipping audit"
```

Table format:

| File | Change Type | Finding | Severity |
|---|---|---|---|
| `path/file.ts` | added / modified | dead export / new dupe | High / Med / Low |

### Phase 1 Summary Table

After all five commands, output a single summary:

| Command | Findings | Auto-fixable | Action |
|---|---|---|---|
| dead-code | N | N | — |
| dupes | N | — | — |
| health | N hotspots | — | — |
| security | N | — | — |
| audit | N | — | — |
| **TOTAL** | **N** | **N** | |

**Gate — auto-fix prompt:**
If `--auto` in $ARGUMENTS: skip fallow fix (treat as "no"), note "auto-skipped fix" in roll-up. Otherwise ask: "Apply `fallow fix` to auto-remove safe unused code? (y/n)"
- If yes: run `fallow fix $ARGUMENTS`, show a table of what was removed:

| File | Symbol Removed | Type |
|---|---|---|
| `path/file.ts` | `unusedFn` | export |

- If no: skip fix, note it.

**Hard gate:** If `--auto` in $ARGUMENTS: skip this gate and proceed automatically, note "auto" in roll-up. Otherwise: "Phase 1 complete. Proceed to Phase 2 — Trim? (y/n)" — stop and wait.

---

## Phase 2 — Trim (LLM Anti-Over-Engineering Review)

### Phase 2a — Whole-codebase audit

First check:

```bash
ls ~/.agents/skills/ | grep -i "^trim-audit$" || echo "NOT_INSTALLED"
```

If NOT_INSTALLED:
```
⚠️ Trim not installed.
Install: npx skills@latest add DietrichGebert/trim
Once installed, re-run /code-health to continue from Phase 2.
```
STOP Phase 2 here.

If installed: invoke the `trim-audit` skill via the Skill tool. Pass the target path from $ARGUMENTS as context. `trim-audit` scans the ENTIRE codebase (not a diff) and returns a ranked list of what to delete, simplify, or replace with stdlib/native equivalents.

Capture trim-audit output and reformat as a table:

| File | Finding | Category | Priority |
|---|---|---|---|
| `path/file.ts` | description | Delete / Shrink / YAGNI / Complexity | High / Med / Low |

Category definitions (use exactly these labels):
- **Delete** — dead/unused, remove entirely
- **Shrink** — exists but can be 3 lines not 30
- **YAGNI** — "you ain't gonna need it" — error states, abstractions for future requirements that haven't arrived
- **Complexity** — unnecessary indirection, abstraction for its own sake

Phase 2 summary:

| Category | Count | Files affected |
|---|---|---|
| Delete | N | list |
| Shrink | N | list |
| YAGNI | N | list |
| Complexity | N | list |
| **Total** | **N** | |

### Phase 2b — Debt marker harvest

Check:

```bash
ls ~/.agents/skills/ | grep -i "^trim-debt$" || echo "NOT_INSTALLED"
```

If NOT_INSTALLED: skip silently, note in summary row.

If installed: invoke the `trim-debt` skill via the Skill tool. Pass the target path from $ARGUMENTS. `trim-debt` harvests all `trim:` inline comments into a debt ledger.

Reformat output as a table:

| File | Line | Debt Note | Age (if known) |
|---|---|---|---|
| `path/file.ts` | 42 | description from comment | — |

**Hard gate:** If `--auto` in $ARGUMENTS: skip this gate and proceed automatically, note "auto" in roll-up. Otherwise: "Phase 2 complete. Proceed to Phase 3 — Improve? (y/n)" — stop and wait.

---

## Phase 3 — Improve (shadcn — Plan Only)

First check:

```bash
ls ~/.agents/skills/ | grep -i "^improve$" || echo "NOT_INSTALLED"
```

If NOT_INSTALLED:
```
⚠️ Improve skill not installed.
Install: npx skills@latest add shadcn/improve
Once installed, re-run /code-health to continue from Phase 3.
```
STOP Phase 3 here.

If installed: invoke the `improve` skill via the Skill tool with the goal:
- If $ARGUMENTS contains a goal description → use it verbatim
- Otherwise → default goal: "reduce over-engineering, token waste, and YAGNI violations found in Phase 1 and Phase 2"

Improve will NOT implement — plan + GitHub issues only. That is correct behavior; do not override it.

Capture Improve's output and reformat as a table:

| Area | Issue | Type | Effort | GitHub Issue |
|---|---|---|---|---|
| `path/file.ts` | description | Token Waste / YAGNI / Over-engineering / Deterministic | S / M / L | #N (if created) |

Type definitions:
- **Token Waste** — sending to LLM what could resolve deterministically
- **YAGNI** — building for requirements that haven't arrived
- **Over-engineering** — abstraction/complexity beyond current need
- **Deterministic** — logic that can move out of LLM context entirely

Phase 3 summary:

| Type | Count | Total Effort |
|---|---|---|
| Token Waste | N | S/M/L |
| YAGNI | N | S/M/L |
| Over-engineering | N | S/M/L |
| Deterministic | N | S/M/L |
| **Total** | **N** | |

---

## Final Roll-up Table

After all phases complete, output one master summary:

| Phase | Tool | Findings | Auto-fixed | Status |
|---|---|---|---|---|
| 0 | Trim review (diff) | N | — | ✅ / skipped (clean tree / not installed) |
| 1a | Fallow dead-code | N | N | ✅ / ⚠️ |
| 1b | Fallow dupes | N | — | ✅ / ⚠️ |
| 1c | Fallow health | N hotspots | — | ✅ / ⚠️ |
| 1d | Fallow security | N | — | ✅ / ⚠️ |
| 1e | Fallow audit | N | — | ✅ / skipped |
| 2a | Trim audit (codebase) | N | — | ✅ / ⚠️ not installed |
| 2b | Trim debt (markers) | N | — | ✅ / skipped |
| 3 | Improve | N | — | ✅ / ⚠️ not installed |
| **Total** | | **N** | **N** | |

Top 5 highest-priority actions across all phases, as a table:

| Priority | Action | Tool | File | Effort |
|---|---|---|---|---|
| 1 | description | Fallow/Trim/Improve | `file.ts` | S/M/L |

---

## Rules

- Never implement. Flag findings, show tables, gate between phases. Human decides what to act on.
- Never skip a Fallow command — run all five even if earlier ones find nothing.
- Never merge Fallow + Trim findings — they are separate tables.
- Trim and Improve missing = not a failure. Show install gate and stop that phase cleanly.
- $ARGUMENTS empty = run against `.` (current directory).
- `--auto` skips all gates and the fallow fix prompt for unattended/AFK runs.
