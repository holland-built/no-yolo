---
name: review
description: Use this skill when the user types /review, says 'review this', 'check the diff', 'code health', 'run health pass', or 'review before merge'. Unified quality review command. Default: three-pass diff review (correctness/bugs/over-engineering/Karpathy) then offers health pass. --health: full codebase health pass (fallow dead-code/dupes/health/security/audit + trim + improve). --fix: apply Critical+Important findings. --comment: post inline PR comments. --effort low|medium|high|max. Bakes in secret scan and antislop on any .md changes automatically.
user-invocable: true
argument-hint: "[path] [--health] [--fix] [--comment] [--effort low|medium|high|max]"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Grep
  - Glob
  - Agent
---

Arguments: $ARGUMENTS

## Flag Parsing

Parse $ARGUMENTS before doing anything else:
- `--health` present → **health mode** (health pass only; skip diff review and the health gate prompt)
- `--fix` present → apply Critical + Important findings from diff review to working tree after review
- `--comment` present → post inline PR comments for each diff review finding after review
- `--effort <level>` present → pass `<level>` through to all review passes
- `--auto` present → skip all health phase confirmation gates (AFK/unattended mode)
- Any remaining non-flag text → treat as optional path target for health pass (default: `.`)

Extract path target:
```bash
PATH_ARG=$(echo "$ARGUMENTS" | sed 's/--health//g; s/--fix//g; s/--comment//g; s/--effort [a-z]*//g; s/--auto//g' | xargs)
PATH_ARG="${PATH_ARG:-.}"
```

## Routing Announcement

Print exactly one line before any work begins:
- No `--health` flag → `Review mode: diff` (updates to `Review mode: both` if user answers y to health gate)
- `--health` flag present → `Review mode: health`

---

## Baked-in Checks (always run, no user prompt)

Run these before the diff passes. Collect their findings for the merged table in Phase 3.

### Secret Scan (auto)

```bash
git diff $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null || echo "HEAD~1") HEAD 2>/dev/null \
  | grep -niE "(api_key\s*[=:]\s*['\"]?[a-zA-Z0-9_\-]{16,}|apikey\s*[=:]\s*['\"]?[a-zA-Z0-9_\-]{16,}|secret\s*[=:]\s*['\"]?[a-zA-Z0-9_\-]{16,}|password\s*[=:]\s*['\"]?[a-zA-Z0-9_\-]{8,}|passwd\s*[=:]\s*['\"]?[a-zA-Z0-9_\-]{8,}|AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|postgres://[^@\s]+@|mysql://[^@\s]+@|mongodb\+srv://[^@\s]+@|redis://:[^@\s]+@|bearer [a-zA-Z0-9\-_\.]{20,})"
```

If any match → immediately emit a `🔑 SECRETS DETECTED` block, list each match with file and context line. Add a 🔴 Critical row to the findings table for each. Secret findings are NEVER auto-applied by `--fix` — surface to user only, regardless of flags.

If no matches → note `Secret scan: clean` in the final roll-up row.

### Antislop Check on .md Files (auto)

```bash
git diff $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null || echo "HEAD~1") HEAD --name-only 2>/dev/null | grep -iE '\.md$'
```

If any .md files appear in the diff → invoke the `antislop` skill via the Skill tool, passing the content of each changed .md file as context. Collect any SLOP-DETECTED findings and add them to the findings table as `📝 Slop` rows (severity: Minor). If CLEAN → note `Antislop: clean` in roll-up.

If no .md files in diff → note `Antislop: skipped (no .md changes)` in roll-up.

---

## Diff Review (skip entirely if --health flag passed)

### Phase 0 — Load Review Discipline

Read `~/.claude/docs/CODE_REVIEW.md` before doing anything else. These are the active filters for this review.

### Phase 1 — Get the Diff

```bash
git diff $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD main 2>/dev/null || echo "HEAD~1") HEAD
```

If no branch divergence found, diff against `HEAD~1`. Save the diff — all three passes use it.

### Phase 2 — Three Passes (run in parallel)

**Pass A — Correctness & Reuse**

Review the diff for:
- Correctness bugs — logic errors, off-by-ones, null/undefined, wrong conditionals
- Reuse — existing function/component already does this?
- Security — auth, input validation, secrets in diff

Apply `--effort` level if provided: `low` = surface scan, `medium` = standard (default), `high` = deep read every changed call site, `max` = exhaustive cross-file analysis.

**Pass B — Over-Engineering**

Invoke `trim-review` skill via the Skill tool, passing the diff as context.
Captures: what to delete, reinvented stdlib, unneeded deps, speculative abstractions.

**Pass C — Karpathy Filters (from CODE_REVIEW.md)**

- **Surgical** — every changed line traces to the stated request; flag any that don't
- **Simplicity** — would a senior engineer say this is overcomplicated?

### Phase 3 — Merge & Output

Combine all findings from: Pass A + Pass B + Pass C + secret scan results + antislop results, deduplicated, into one table:

```
path:line: <emoji> <severity>: <problem>. <fix>.
```

Severity + emoji:
- 🔴 Critical — breaks correctness or security; fix immediately
- 🟠 Important — fix before proceeding
- 🟡 Minor — log for later
- 🔵 Scope — line not traced to request (surgical violation)
- ⚪ Simplicity — senior engineer would simplify this
- 🟣 Complexity — over-engineered, delete or shrink (trim)
- 🔑 Secret — credential or token found in diff (always Critical, never auto-fixed)
- 📝 Slop — AI writing tell in a changed .md file (Minor)

No praise. No summary prose. Findings only. Sort by severity (Critical first).

---

## Health Pass Gate (only in diff mode — skip if --health flag was passed)

After printing the merged findings table, ask exactly:

**"Health pass? Runs fallow dead-code/dupes/health/security/audit + trim on the whole codebase. (y/n)"**

- If **y** → print `Review mode: both` → proceed to Health Pass below
- If **n** → skip health pass; jump to Apply Findings / Post Comments / Done

---

## Health Pass (runs when --health flag passed OR user answers y to gate above)

**`--auto` behavior:** if `--auto` is in $ARGUMENTS, skip all confirmation gates and the fallow fix prompt. Auto-answers "no" to the fallow fix prompt. Auto-proceeds between phases.

### Pre-flight

Silently run:

```bash
which fallow && fallow --version 2>/dev/null && echo "fallow:ok" || echo "fallow:missing"
ls ~/.agents/skills/ 2>/dev/null | grep -iE "^trim-audit$" && echo "trim-audit:ok" || echo "trim-audit:missing"
ls ~/.agents/skills/ 2>/dev/null | grep -iE "^trim-debt$" && echo "trim-debt:ok" || echo "trim-debt:missing"
ls ~/.agents/skills/ 2>/dev/null | grep -iE "^improve$" && echo "improve:ok" || echo "improve:missing"
ls ~/.agents/skills/ 2>/dev/null | grep -iE "^trim-review$" && echo "trim-review:ok" || echo "trim-review:missing"
```

Output a single status table:

| Tool | Status | Install if missing |
|---|---|---|
| Fallow | ✅ installed / ❌ missing | `npm install -g fallow` |
| Trim (review) | ✅ / ❌ | `npx skills@latest add DietrichGebert/trim` |
| Trim (audit) | ✅ / ❌ | `npx skills@latest add DietrichGebert/trim` |
| Trim (debt) | ✅ / ❌ | `npx skills@latest add DietrichGebert/trim` |
| Improve | ✅ / ❌ | `npx skills@latest add shadcn/improve` |

If Fallow is missing: STOP. Show the status table, tell the user to install Fallow first, exit health pass.
If Trim or Improve missing: note it, continue — those phases will show an install gate and stop there.

### Output Rule (all health phases)

Every finding set is a markdown table. No prose summaries, no bullet lists, no inline commentary. If a command produces zero findings, output a one-row table: `| — | No findings | — |`. Columns below are the spec — match them exactly.

### Phase H0 — Trim Review (diff-scoped, only if changes exist)

```bash
git diff --stat HEAD 2>/dev/null | head -5
git status --short 2>/dev/null | head -5
```

If staged or uncommitted changes exist AND trim-review is installed: invoke the `trim-review` skill via the Skill tool, passing the diff as context. Reformat output as:

| File | Finding | Category | Priority |
|---|---|---|---|
| `path/file.ts` | description | Delete / Shrink / YAGNI | High / Med / Low |

If no diff (clean working tree): skip silently — note `Phase H0: skipped (clean tree)` in final roll-up.
If trim-review not installed: skip silently — note `Phase H0: skipped (not installed)` in final roll-up.

No gate after Phase H0 — continue straight to Phase H1.

### Phase H1 — Fallow (Static Analysis)

Run each command in order. After ALL five complete, show one consolidated table per command. Do not interleave prose.

**H1a — Dead Code**

```bash
fallow dead-code $PATH_ARG 2>&1
```

| File | Symbol | Type | Why Dead |
|---|---|---|---|
| `path/file.ts` | `exportName` | export / import / dep | unused / unreachable / no callers |

**H1b — Duplication**

```bash
fallow dupes $PATH_ARG 2>&1
```

| File A | File B | Lines | Similarity | Note |
|---|---|---|---|---|
| `a.ts:12` | `b.ts:45` | 18 | 94% | copy-paste / structural clone |

**H1c — Health**

```bash
fallow health $PATH_ARG 2>&1
```

| File | Complexity | Maintainability | Hotspot | Flag |
|---|---|---|---|---|
| `path/file.ts` | 24 | D | ✅ | high cyclomatic / low coverage |

**H1d — Security**

```bash
fallow security $PATH_ARG 2>&1
```

| File | Finding | Risk | Note |
|---|---|---|---|
| `path/file.ts` | hardcoded secret / open exec | High / Med / Low | brief context |

**H1e — Audit (diff-scoped, only if in a git repo)**

```bash
git rev-parse --git-dir 2>/dev/null && fallow audit $PATH_ARG 2>&1 || echo "not a git repo — skipping audit"
```

| File | Change Type | Finding | Severity |
|---|---|---|---|
| `path/file.ts` | added / modified | dead export / new dupe | High / Med / Low |

**Phase H1 Summary Table**

| Command | Findings | Auto-fixable | Action |
|---|---|---|---|
| dead-code | N | N | — |
| dupes | N | — | — |
| health | N hotspots | — | — |
| security | N | — | — |
| audit | N | — | — |
| **TOTAL** | **N** | **N** | |

**Gate — auto-fix prompt:**
If `--auto` in $ARGUMENTS: skip fallow fix (treat as "no"), note `auto-skipped fix` in roll-up. Otherwise ask: "Apply `fallow fix` to auto-remove safe unused code? (y/n)"
- If yes: run `fallow fix $PATH_ARG`, show a table of what was removed:

| File | Symbol Removed | Type |
|---|---|---|
| `path/file.ts` | `unusedFn` | export |

- If no: skip fix, note it.

**Hard gate:** If `--auto` in $ARGUMENTS: skip and proceed automatically. Otherwise: "Phase H1 complete. Proceed to Phase H2 — Trim? (y/n)" — stop and wait.

### Phase H2 — Trim (LLM Anti-Over-Engineering Review)

**H2a — Whole-codebase audit**

```bash
ls ~/.agents/skills/ 2>/dev/null | grep -iE "^trim-audit$" || echo "NOT_INSTALLED"
```

If NOT_INSTALLED:
```
⚠️ Trim not installed.
Install: npx skills@latest add DietrichGebert/trim
Once installed, re-run /review --health to continue from Phase H2.
```
STOP Phase H2 here.

If installed: invoke the `trim-audit` skill via the Skill tool. Pass `$PATH_ARG` as context. `trim-audit` scans the ENTIRE codebase and returns a ranked list of what to delete, simplify, or replace. Reformat output as:

| File | Finding | Category | Priority |
|---|---|---|---|
| `path/file.ts` | description | Delete / Shrink / YAGNI / Complexity | High / Med / Low |

Category definitions (use exactly these labels):
- **Delete** — dead/unused, remove entirely
- **Shrink** — exists but can be 3 lines not 30
- **YAGNI** — building for requirements that haven't arrived
- **Complexity** — unnecessary indirection, abstraction for its own sake

Phase H2 summary:

| Category | Count | Files affected |
|---|---|---|
| Delete | N | list |
| Shrink | N | list |
| YAGNI | N | list |
| Complexity | N | list |
| **Total** | **N** | |

**H2b — Debt marker harvest**

```bash
ls ~/.agents/skills/ 2>/dev/null | grep -iE "^trim-debt$" || echo "NOT_INSTALLED"
```

If NOT_INSTALLED: skip silently, note in summary row.

If installed: invoke the `trim-debt` skill via the Skill tool. Pass `$PATH_ARG`. `trim-debt` harvests all `trim:` inline comments into a debt ledger. Reformat as:

| File | Line | Debt Note | Age (if known) |
|---|---|---|---|
| `path/file.ts` | 42 | description from comment | — |

**Hard gate:** If `--auto` in $ARGUMENTS: skip and proceed automatically. Otherwise: "Phase H2 complete. Proceed to Phase H3 — Improve? (y/n)" — stop and wait.

### Phase H3 — Improve (shadcn — Plan Only)

```bash
ls ~/.agents/skills/ 2>/dev/null | grep -iE "^improve$" || echo "NOT_INSTALLED"
```

If NOT_INSTALLED:
```
⚠️ Improve skill not installed.
Install: npx skills@latest add shadcn/improve
Once installed, re-run /review --health to continue from Phase H3.
```
STOP Phase H3 here.

If installed: invoke the `improve` skill via the Skill tool with goal:
- If $PATH_ARG contains a goal description → use it verbatim
- Otherwise → default goal: "reduce over-engineering, token waste, and YAGNI violations found in Phase H1 and Phase H2"

Improve will NOT implement — plan + GitHub issues only. That is correct behavior; do not override it.

| Area | Issue | Type | Effort | GitHub Issue |
|---|---|---|---|---|
| `path/file.ts` | description | Token Waste / YAGNI / Over-engineering / Deterministic | S / M / L | #N (if created) |

Type definitions:
- **Token Waste** — sending to LLM what could resolve deterministically
- **YAGNI** — building for requirements that haven't arrived
- **Over-engineering** — abstraction/complexity beyond current need
- **Deterministic** — logic that can move out of LLM context entirely

Phase H3 summary:

| Type | Count | Total Effort |
|---|---|---|
| Token Waste | N | S/M/L |
| YAGNI | N | S/M/L |
| Over-engineering | N | S/M/L |
| Deterministic | N | S/M/L |
| **Total** | **N** | |

### Health Roll-up Table

After all health phases complete, output one master summary:

| Phase | Tool | Findings | Auto-fixed | Status |
|---|---|---|---|---|
| H0 | Trim review (diff) | N | — | ✅ / skipped (clean tree / not installed) |
| H1a | Fallow dead-code | N | N | ✅ / ⚠️ |
| H1b | Fallow dupes | N | — | ✅ / ⚠️ |
| H1c | Fallow health | N hotspots | — | ✅ / ⚠️ |
| H1d | Fallow security | N | — | ✅ / ⚠️ |
| H1e | Fallow audit | N | — | ✅ / skipped (not a git repo) |
| H2a | Trim audit (codebase) | N | — | ✅ / ⚠️ not installed |
| H2b | Trim debt (markers) | N | — | ✅ / skipped (not installed) |
| H3 | Improve | N | — | ✅ / ⚠️ not installed |
| **Total** | | **N** | **N** | |

Top 5 highest-priority actions across all health phases:

| Priority | Action | Tool | File | Effort |
|---|---|---|---|---|
| 1 | description | Fallow/Trim/Improve | `file.ts` | S/M/L |

---

## Apply Findings (runs if --fix passed)

Apply all Critical + Important findings from the diff review to the working tree. Show a table:

| File | Line | Finding | Applied |
|---|---|---|---|

Rules:
- 🔑 Secret findings are NEVER applied — show them but skip the edit.
- Health pass findings are NOT auto-fixed by `--fix` — they require manual review per phase gates.
- Only diff review findings (Passes A/B/C) are eligible for `--fix`.

---

## Post Inline PR Comments (runs if --comment passed)

Post each diff review finding as an inline PR comment:

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments \
  --method POST \
  --field path="<file>" \
  --field position=<line> \
  --field body="<emoji> <severity>: <problem>. <fix>." \
  --field commit_id="<sha>"
```

Detect owner/repo from `git remote get-url origin`. Detect PR number via `gh pr view --json number`.
Only post diff review findings (Passes A/B/C) — do not post health findings or baked-in check findings as inline comments.

---

## Final Roll-up

After all passes complete, print one master summary:

| Mode | Scope | Findings | Secrets | Slop | Auto-fixed | Status |
|---|---|---|---|---|---|---|
| diff | PR diff | N | clean / 🔑 N | clean / 📝 N | N applied (if --fix) | ✅ |
| health | $PATH_ARG | N | — | — | N (fallow fix if y) | ✅ / partial |

---

## Rules

- Secret findings (🔑) are always shown, never auto-applied by --fix, regardless of flags.
- Antislop runs automatically on every .md in the diff — no user opt-in required.
- Health pass never implements code — fallow fix only on explicit y, improve is plan-only.
- `--auto` skips all health phase gates and fallow fix prompt for unattended/AFK runs.
- $ARGUMENTS empty = diff mode, PATH_ARG = `.`.
- trim-review, trim-audit, trim-debt, improve missing = not a failure; show install gate and stop that sub-phase cleanly.
- Never merge diff review findings with health findings in the same table — they are separate output blocks.
- Never skip a Fallow command in the health pass — run all five even if earlier ones find nothing.
