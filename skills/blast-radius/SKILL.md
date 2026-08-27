---
name: blast-radius
description: Use immediately after a defect's cause is located, before it is fixed, and when the owner says "blast radius", "where else", "is this wrong anywhere else", or "did we fix all of them". Searches the codebase for the same mistake in other places and records what was searched, what matched, and what proves each fix.
user-invocable: true
argument-hint: "[file:line of the located cause]"
allowed-tools: Read, Grep, Glob, Bash
---

# blast-radius

One bug is almost never one bug. The same wrong assumption gets typed in several places by
the same person on the same afternoon, and fixing the one that got reported leaves the rest
to be found by whoever hits them next.

This runs by itself at the end of `skills/build/stages/0-evidence.md`, cause path, before any
fix is written. It is not something the owner has to remember to ask for. They have said they
cannot remember to ask for anything.

## Why before the fix, not after

Searching after the fix means searching for a pattern that no longer matches the code you
just corrected, and it means the fix was designed around one site rather than all of them.
Two sites with the same cause often want one shared fix. You cannot see that once the first
is already patched.

## Steps

**1. Name the mistake, not the symptom.** Stage 0 wrote "function X produces Y because Z".
The searchable thing is Z. `parseInt` without a radix, a date treated as a string, an unawaited
promise, a hardcoded `localhost`. Write it as one sentence before searching.

**2. Search at least three ways.** One search finds one spelling. Vary the angle, and send all
three as one wave, since no angle reads another's hits:

| Angle | Example |
|---|---|
| The exact call or token | `grep -rn "parseInt(" --include='*.ts'` |
| The shape around it | the same argument order, the same missing second argument |
| The neighbours | every other caller of the same function, every sibling in the directory |

Record each command verbatim. A search nobody can re-run is not evidence.

**3. Judge every match by reading it.** A match is a candidate, never a finding. Open the line
and decide: same cause, different cause, or already correct. A count of grep hits presented as
a count of bugs is the failure mode this skill exists to avoid.

**4. Do not trust this session's own summary.** Whatever was said earlier in the conversation
about how the code works is a claim, not a fact. Prove the one or two things the conclusion
rests on by running code: a test, a log line, a value printed. Cite the command.

**5. Write it into the diagnosis file** that stage 0 created, as a table:

| Location | Same cause? | Evidence read | Fix |
|---|---|---|---|
| `file:line` | yes / no / already correct | what the line actually does | the change, or why none |

**6. Report the shape, not the list.** To the owner: how many places, how many are real, and
the one thing they need to decide. The table stays in the file.

## When it finds nothing

Say so as a fact about the search: "I looked for Z three ways (`<commands>`) across `<n>`
files and found only the reported site." An empty result that is reported as silence is
indistinguishable from a search that never ran.

## Boundaries

Stops at reporting. It does not fix anything: stage 5 does that, from a plan that now knows
how many sites there are.

Never widens the job on its own. Four sites with the same cause is a finding for the owner,
not a licence to edit four files.
