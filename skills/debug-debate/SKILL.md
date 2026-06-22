---
name: debug-debate
description: 6-persona repo-aware debugging debate — six Opus personas read the code and argue competing root-cause theories, then a contradiction map + most likely cause + next diagnostic step. Diagnosis only, no fix. Activate on "/debug-debate", "argue about this bug", "what's breaking and why", "debate the bug".
user-invocable: true
argument-hint: "[describe the bug or unexpected behavior]"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
---

Bug: $ARGUMENTS

Diagnosis only. No code is written or changed. After this, run `/plan-feature` or `/diagnose` to act.

---

## Step 1 — Parse + Context

If $ARGUMENTS is empty: ask "What's the bug or unexpected behavior?" before continuing.

Ask context questions ONE AT A TIME via `AskUserQuestion` (skip any already answered in $ARGUMENTS, max 3 total):
1. Which file(s) or surface is affected?
2. What is the observed vs expected behavior (exact values/errors if possible)?
3. When did it start, or what's the last-known-good state? (offer "unknown" option)

---

## Step 2 — Read Code

Before spawning personas, gather the fact pack:
- Grep for affected symbols/functions across the codebase
- Glob the affected surface (component/module/service)
- Read 2–6 key files + their direct imports
- Cap total reading at ~400 lines; cite every path read

Build a `relevant-code excerpt` bundle to pass to all personas. This is their shared ground truth.

---

## Step 3 — 6 Parallel Opus Personas

Spawn all 6 in ONE parallel call (`model: opus`). Never sequential — parallel prevents theory-anchoring.

Each agent receives: bug description + observed/expected + when-started + code excerpt bundle + their persona brief below.

Each agent MUST:
- Cite `file:line` for their theory
- Answer all 3 of their signature questions
- Return in this exact format (cap ~250 words):
  - **Theory:** root cause in one sentence (`file:line`)
  - **Evidence:** strongest supporting fact from the code
  - **Only I would catch:** the failure mode specific to my lens
  - **Confidence:** N/10

---

### THE DATA-FLOW TRACER
Follows a value from origin to consumer end-to-end.
1. Where does this value originate and where is it last correct?
2. What transform, serialization, or mapping mutates or drops it?
3. Is the shape at the consumer what the producer actually sends?
*Catches:* silent type coercion, null-vs-undefined, off-by-one in the pipeline.

### THE CONCURRENCY/TIMING DETECTIVE
Hunts order violations and race conditions.
1. What two things assume an order that isn't guaranteed?
2. What's awaited vs fired-and-forgot — where is an unhandled promise?
3. What shared state is read or written without a lock, or before initialization?
*Catches:* race conditions, stale closures, unhandled-promise ordering bugs.

### THE CONFIG/ENVIRONMENT AUDITOR
Hunts drift between environments.
1. What env var, flag, or default differs between where it works and where it breaks?
2. What's read at build time vs runtime — and which one is wrong here?
3. What's hardcoded that should be configured, or configured that was silently defaulted?
*Catches:* "works on my machine" config drift, missing/defaulted env vars.

### THE BOUNDARY/CONTRACT SKEPTIC
Questions every integration seam.
1. At each API/module/library boundary, do both sides agree on schema, units, nullability, and error shape?
2. What version mismatch or breaking upstream change fits the timeline?
3. Who owns the data on each side — and is that ownership enforced?
*Catches:* contract mismatch, version skew, wrong assumption about a dependency's behavior.

### THE SILENT-FAILURE HUNTER
Finds errors that are caught and hidden.
1. Where is an exception caught and discarded, or a fallback masking the real failure?
2. What returns a safe default on the unhappy path instead of throwing?
3. What log line should exist here but doesn't?
*Catches:* swallowed exceptions, misleading fallbacks, the bug that hides one layer above the symptom.

### THE STATE/LIFECYCLE INVESTIGATOR
Follows what persists and mutates.
1. What state outlives the request, render, or session it belongs to?
2. What's cached, memoized, or stale — and when was it last invalidated?
3. What init or teardown order is assumed — and is that assumption enforced?
*Catches:* stale cache, leaked or shared mutable state, lifecycle and ordering bugs.

---

## Step 4 — Contradiction Map

After all 6 agents return:

**Conflict table:**
| Theory A | Theory B | Claims that clash | Stronger evidence |
|----------|----------|-------------------|-------------------|

Then answer:
- Which persona has the strongest evidence? Which the weakest? Why?
- What single question, if answered, would resolve the biggest conflict?
- What do ALL 6 agree on? (Likely true — even opponents confirm it.)
- What did NONE address? (The blind spot.)

---

## Step 5 — Final Diagnosis

Collapse the map into one verdict. Do not re-analyze.

> **Most likely root cause:** `file:line` — one sentence.
> **Confidence:** N/10
> **Next diagnostic step:** ONE concrete runnable command or probe (test, log line, git bisect, curl) that confirms or kills this theory.
> **If that's wrong, next suspect:** `file:line` — one line.

Rules: exactly one primary cause, cite `file:line`, next step must be runnable not "investigate further."

---

## Step 6 — Handoff

End with exactly:

> **Diagnosis only — no code changed.** Run `/plan-feature [slug]` to plan a fix, or `/diagnose` for deeper instrumentation.
