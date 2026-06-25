---
name: diagnose
description: Use this skill when the user types /diagnose, says 'debug this', 'can't figure out why', 'something's broken', 'argue about this bug', or 'debate the bug'. Two modes: default = systematic 6-phase diagnosis (reproduce → minimize → hypothesize → instrument → fix → regression-test); --debate = 6 parallel Opus personas argue competing root-cause theories → contradiction map → diagnosis + next step. Diagnosis only in debate mode, no fix.
user-invocable: true
argument-hint: "[describe the bug or paste the error] [--debate]"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Agent
  - AskUserQuestion
---

**Mode detection:** If `$ARGUMENTS` contains `--debate` → run **Debate mode** below. Otherwise → run **Systematic mode**.

---

## DEBATE MODE (`--debate`)

Bug: $ARGUMENTS

Diagnosis only. No code is written or changed.

### Step D1 — Parse + Context

If $ARGUMENTS (minus `--debate`) is empty: ask "What's the bug or unexpected behavior?" before continuing.

Ask context questions ONE AT A TIME via `AskUserQuestion` (skip any already answered, max 3 total):
1. Which file(s) or surface is affected?
2. What is the observed vs expected behavior (exact values/errors if possible)?
3. When did it start, or what's the last-known-good state? (offer "unknown" option)

### Step D2 — Read Code

Gather fact pack before spawning personas:
- Grep for affected symbols/functions
- Read 2–6 key files + their direct imports
- Cap ~400 lines total; cite every path read

Build a `relevant-code excerpt` bundle — shared ground truth for all personas.

### Step D3 — 6 Parallel Opus Personas

Spawn all 6 in ONE parallel call (`model: opus`). Never sequential — prevents theory-anchoring.

Each agent receives: bug description + observed/expected + when-started + code excerpt bundle + their persona brief.

Each agent MUST return: **Theory** (file:line), **Evidence**, **Only I would catch**, **Confidence** N/10. Cap ~250 words.

**THE DATA-FLOW TRACER** — follows a value origin to consumer. Catches: silent type coercion, null-vs-undefined, off-by-one.

**THE CONCURRENCY/TIMING DETECTIVE** — hunts order violations, race conditions. Catches: stale closures, unhandled-promise ordering.

**THE CONFIG/ENVIRONMENT AUDITOR** — hunts env drift. Catches: "works on my machine", missing env vars.

**THE BOUNDARY/CONTRACT SKEPTIC** — questions every integration seam. Catches: contract mismatch, version skew.

**THE SILENT-FAILURE HUNTER** — finds errors caught and hidden. Catches: swallowed exceptions, misleading fallbacks.

**THE STATE/LIFECYCLE INVESTIGATOR** — follows what persists and mutates. Catches: stale cache, leaked mutable state, lifecycle bugs.

### Step D4 — Contradiction Map

| Theory A | Theory B | Claims that clash | Stronger evidence |

Then: strongest persona, weakest, one question that resolves the biggest conflict, what ALL 6 agree on, what NONE addressed.

### Step D5 — Final Diagnosis

> **Most likely root cause:** `file:line` — one sentence.
> **Confidence:** N/10
> **Next diagnostic step:** ONE runnable command or probe that confirms or kills this theory.
> **If that's wrong, next suspect:** `file:line` — one line.

### Step D6 — Handoff

> **Diagnosis only — no code changed.** Run `/plan [slug]` to plan a fix, or `/diagnose` for deeper instrumentation.

---

## SYSTEMATIC MODE

Systematic bug diagnosis. Problem: $ARGUMENTS

## Phase 1 — Build a Feedback Loop (highest leverage)

Before anything else, find the fastest way to observe the bug reliably. Rank the options and pick the best available:

1. **Failing automated test** — write or find one that reproduces the bug; run it in <5s
2. **Short script** — minimal Node/Python/bash that triggers the bug directly
3. **Curl / API call** — for server-side issues, a single command that shows the wrong behavior
4. **Dev-server + browser** — load the page, observe the symptom
5. **Log scrape** — grep for the error in existing logs
6. **Manual UI steps** — last resort; describe the exact click path that triggers it

**Do not proceed to Phase 2 until the feedback loop is running.** A loop you can run in <10s is worth more than 30 minutes of reading code.

State: "Feedback loop: `<command>` → reproduces the bug with output: `<output>`"

## Phase 2 — Minimize

Strip away everything that isn't load-bearing for the bug. Goal: smallest failing case.

- Remove unrelated code paths, config, env vars
- Bisect if the bug appeared in a recent commit: `git bisect start && git bisect bad && git bisect good <hash>`
- Narrow to one file, one function, one call if possible

State the minimal reproducer before continuing.

## Phase 3 — Hypothesize

Generate 3–5 distinct hypotheses. For each:
- What would have to be true for this hypothesis to explain the bug?
- What evidence already confirms or rules it out?
- What one observation would eliminate it?

Do not pick a favorite yet. List all live hypotheses.

## Phase 4 — Instrument

Add targeted observability to distinguish between hypotheses — without changing behavior:

- `console.log` / `console.error` at branch points
- Assertions that should always hold: `if (x !== expected) throw new Error(...)`
- Read relevant config, env, and state values at the failure point
- For network bugs: log request/response headers and bodies
- For type errors: log `typeof`, `.constructor.name`, or run the TypeScript compiler on the file

Run the feedback loop. Eliminate hypotheses. Repeat until one survives.

## Phase 5 — Fix

Fix only the confirmed root cause. No collateral cleanup.

- State the root cause in one sentence before writing any code
- Change the minimum lines that address it
- If the fix feels large, question whether phase 3 was complete

## Phase 6 — Regression Test

Lock the bug out permanently:

- Write a test that would have caught this bug before it was fixed
- Run it against the broken version (should fail), then the fixed version (should pass)
- Add it to the test suite; if no suite exists, add it to a `__tests__/` or `*.test.ts` file

---

**Rule:** If you get stuck at any phase, go back to Phase 1 and improve the feedback loop. A better loop almost always unblocks you.
