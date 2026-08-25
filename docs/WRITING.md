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

**The context budget has a number: 2,200 words.** It covers the four files loaded on every
session, `CLAUDE.md`, `rules/codex.md`, `rules/mockups.md` and `output-styles/plain.md`, and
`verify.sh` fails when they exceed it.

The number is a ratchet, not a target: it stops growth without claiming the current size is
right, so an addition means a deletion. It is a local choice measured on this repo, and not a
published benchmark. What it measured and what it is not, in `docs/DECISIONS.md`.

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

Pick one familiar word for each behaviour and reuse it everywhere: *surgical* for a narrow
edit, *tracer bullet* for a thin end-to-end slice, *red* for a failing test.

**Why a familiar word and not one you invent.** The model has already read a million uses of
*surgical*, so the word arrives carrying its own instructions and you spend nothing defining
it. A coined word arrives empty. You pay for its meaning in every file that uses it, and you
pay again each time one of those definitions drifts.

Use the same word in the body and in the pointer that reaches the file. The body one steers
execution, the pointer one steers invocation, and a word living in both brings the agent to
the material more often than a word used in one place.

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

## Adding a skill

Three edits, and they are one action. A skill added without the other two turns `verify.sh`
red, because the `README skills inventory` row reads the table and the count as the record of
what exists.

1. Write `skills/<name>/SKILL.md` with `user-invocable: true`, and put the phrases that should
   trigger it in that same `description`.
2. Add a row to the skills table in `README.md`.
3. Update the spelled number in the sentence above that table.

Then prove all three landed:

```bash
bash verify.sh
```

The `README skills inventory` row compares names in both directions, so a renamed skill fails
it even when the count still looks right.

Before adding one, ask whether an existing skill should gain a mode instead. Six commands with
modes beat twenty-six commands, and `docs/DECISIONS.md` records what the twenty-six cost.

## Checking your work

Run `agnix` and `@yawlabs/ctxlint` over the file, each taking a path. They read rule files
mechanically and report broken references, dead commands, and structural faults. A finding
they raise is a fact; a clean result means those two classes are clear, and says nothing about
the rest.

Naming an outside tool is itself a claim. Query it before you write it (`CLAUDE.md` rule 5),
add it to `hooks/externals.txt` with the project it resolves to, and `hooks/external-check.sh`
will hold you to it on every run of `verify.sh`. This paragraph got one of those two names
wrong for its whole life, which `docs/DECISIONS.md` records.
