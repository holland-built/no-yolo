---
name: fixloop
description: Use this skill when the user types /fixloop, says 'find and fix them', 'stop telling me just fix it', 'fix loop', 'autonomous fix pass', or 'hunt and fix until clean'. Autonomous find-prove-fix-verify-ship loop that stops narrating findings — it fixes at its own recommended settings, ships each fix, and reports once at the end. Severity-ordered so it hunts wrong-data-presented-as-fact and blind alerting before cosmetics. Hard-stops only on destructive, unbounded-blast-radius, genuinely-blocked-upstream, or product-changing work.
user-invocable: true
argument-hint: "[goal or surface] [--releases N] [--dry]"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - Agent
  - Skill
  - TodoWrite
---

# fixloop

Autonomous defect hunt. The user has explicitly asked NOT to be told what you
find. Find it, prove it, fix it, verify it, ship it, move on. One report at the
end.

## Goal

Default goal when the user gives none: **no surface in this app shows a number,
count, or status that is wrong, stale, truncated-but-unlabelled, or fabricated.**

If the user supplies a goal or a surface, that replaces the default. State the
resolved goal in one line before starting, then go quiet.

## Loop

Repeat until the exit condition:

1. **HUNT.** Pick the highest-severity unfixed defect. Priority order, strict:
   1. wrong data presented as fact
   2. missing or blind alerting / detection
   3. silently truncated or capped data with no label
   4. dead panels, orphaned endpoints, unreachable features
   5. cosmetic
   Without this ladder an autonomous loop drifts to cosmetics because they are
   easy. Do not reorder it.
2. **PROVE IT.** Reproduce against live data. A green test suite is not
   evidence. State the defect internally as observed-value vs true-value before
   touching code; if you cannot state it that way you have not found it yet.
3. **FIX at the source, surgically.** When two options are close, choose the
   smaller blast radius and note the alternative in the commit body.
4. **VERIFY live.** Same reproduction, now showing the correct observed value.
   Add a regression test that fails on the pre-fix code.
5. **GATE.** Run the project's full gate set (tests, vet/typecheck, build, and
   any repo-specific spec). All green or you are not done.
6. **SHIP.** Invoke the `release` skill, bumping the patch version. Release
   notes state plainly any number that will visibly jump, and why.
7. Return to 1.

## Silence contract

- No interim findings lists. No "here is what I noticed". No asking which option
  is preferred. No progress narration between loop iterations.
- Anything deliberately NOT fixed goes in the repo changelog as a named
  follow-up with its reason. The changelog is the log, not the chat.
- Prose is what stops.

## Hard stops — pause and ask ONLY for these

- destructive or irreversible action (data deletion, force-push, teardown)
- a fix whose blast radius you cannot bound
- upstream is genuinely broken with no workaround (say so plainly; never invent
  a substitute value to fill the gap)
- a change that alters what the product IS rather than making it truthful

## Rules that never relax

- If a feature cannot be verified against live data, build the verifiable
  version of the same intent instead. Unverifiable features are where bugs hide.

## Exit condition

Stop when any of these is true:
- a full hunt pass finds nothing above "cosmetic"
- N releases shipped (default 5, override with `--releases N`)
- a hard stop fires

`--dry` runs the hunt and prove phases only, ships nothing, and reports what it
would have fixed.

## Final output — once, at the end

A markdown table:

| version | defect | observed before | observed after | verified how |

Then a short list of what was left undone and why. Nothing else.
