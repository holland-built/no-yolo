# Writing a file an agent reads

Read before creating or editing a skill, `CLAUDE.md`, or any rules doc.

Adapted from `mattpocock/skills` → `writing-for-agents`. The vocabulary below is theirs; the
examples are from this setup.

For the full treatment, the `writing-for-agents` skill carries that vocabulary at length, and
its `SKILL-MECHANICS.md` covers frontmatter, invocation choice, and router skills, which this
file does not. It installs from `mattpocock/skills`; when it is absent, this file is the whole
standard.

## The two budgets

Every line you add spends one of two things:

| Budget | Who pays | Spent by |
|---|---|---|
| **Context** | The model, every single turn | Anything always loaded: `CLAUDE.md`, a skill description |
| **Attention** | The owner | Knowing which file exists and when to reach for it |

Material behind a pointer costs only the pointer's own line. That is the whole reason
pointers exist.

## The ladder

Three rungs, ranked by how immediately the agent needs the material:

1. **A step in the file.** What the agent does, in order.
2. **Reference in the file.** Consulted on demand. A flat list of peers is a fine shape.
3. **Reference behind a pointer.** Loaded only when the condition fires.

**The branching test decides the rung.** Inline what every run needs. Push behind a pointer
what only some runs reach.

**Co-location** decides what sits beside a piece once its rung is settled. A concept's
definition, its rules, and its caveats belong under one heading, so reading one part brings
its neighbours along. Scattering a single meaning across a file is its own fault, distinct
from stating that meaning twice.

**Sprawl** is the failure here: a file so long that attention thins across it, even when
every line is live. The cure is the ladder, not tighter prose.

## Pointers

A pointer states what the material is and names the condition that reaches it. Its wording,
not its target, decides whether the agent gets there.

- Lead with the word that does the triggering.
- One trigger per branch. Two words for the same case is one case written twice.
- Drop identity the target already carries.

## Every step ends on a checkable condition

Two properties make the ending line work:

- **Clarity.** Can the agent tell done from not-done? "Understanding reached" cannot be
  checked, so the agent stops early and moves on. Sharpen the wording first. Split the
  sequence only when the wording is genuinely unsharpen-able and you have watched it rush.
  A split earns its cost across a real context boundary, a handoff or a subagent dispatch;
  an inline call leaves the later steps sitting in context and hides nothing.
- **Demand.** How much the wording asks for. "Every changed file accounted for" produces
  digging that "produce a change list" does not.

The strongest endings are both checkable and exhaustive.

## Leading words

A leading word is a compact idea already in the model's training that anchors a whole region
of behaviour in one token. Used as a token, repeated, never re-explained: *red*, *surgical*,
*tracer bullet*. A word you coin yourself recruits nothing, so you pay in definitions what a
known word gives free. Reach for the existing word.

A leading word anchors twice. In the body it steers execution; in a pointer it steers
invocation, so a word that already lives in the prompts, the docs, and the code brings the
agent to the material more often than a word used in one place alone.

Hunt for passages that collapse into one: a three-part phrase spelled out at three sites, a
pointer spending a sentence to gesture at one idea.

## State the target, not the ban

Naming a behaviour makes it available to the model, so a prohibition half-reads as an
instruction. Write what to do; the unwanted behaviour never enters the text.

| Reads as a ban | Reads as a target |
|---|---|
| "Never skip the changelog" | "Each release opens with its changelog entry" |
| "Do not leave the branch dirty" | "The branch ends every session committed" |
| "Avoid vague variable names" | "A name says what the value holds" |

A prohibition earns its place only as a hard guardrail with no positive phrasing available,
and even then it carries the positive target beside it.

## Pruning

- **One meaning, one place.** Changing a behaviour should be a one-file edit. The same rule
  in two files drifts: this setup's four-mockup count disagreed across two files for two days.
- **The environment is a source of truth.** `package.json` scripts, config files, `--help`
  output. Restating one is a copy that goes stale. Write down what a lookup cannot give: the
  unwritten convention, the reason behind a choice, the gotcha.
- **Check every line for relevance.** A line earns its place by bearing on what the file
  does. Without pruning, files accumulate layers nobody dares remove.
- **Hunt no-ops sentence by sentence.** An instruction the model already follows by default
  pays context and buys nothing. The test is behavioural: does the file act differently
  without this line? Settle a disagreement by running it, not by arguing. When a sentence
  fails, delete the sentence whole.

## Checking your work

Run `agnix` and `@yawlabs/ctxlint` over the file, each taking a path. They read rule files
mechanically and report broken references, dead commands, and structural faults. A finding
they raise is a fact; a clean result means those two classes are clear, and says nothing about
the rest.

Naming an outside tool is itself a claim. Query it before you write it (`CLAUDE.md` rule 5),
add it to `hooks/externals.txt` with the project it resolves to, and `hooks/external-check.sh`
will hold you to it. This paragraph named a tool as `Ctxlint`, which is neither its package
name nor its capitalisation, and stood that way from the day it was written.
