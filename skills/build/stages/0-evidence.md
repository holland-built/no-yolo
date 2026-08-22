# Stage 0: Evidence

Runs for any size above tweak, and it starts while the size gate waits.

It reads the project's source and writes one file of its own, the diagnosis below. The
project's code is untouched until stage 5.

This stage gathers facts so the plan works against reality rather than against a description.
Two paths, depending on whether something is broken.

## Which path

| The work | Path |
|---|---|
| Something behaves wrongly | **Locate the cause.** Sections below |
| Behaviour that does not exist yet | **Read the baseline.** Section at the end |

## Locating a cause

**The cause sits where the measurement breaks, not where the symptom shows.**

## Screens

Open the surface in a real browser at the failing viewport. Dump live numbers: `clientWidth`
against `scrollWidth`, computed `display`, `overflow` and `position`, and every element wider
or taller than its parent.

Walk up from the symptom to the first ancestor where the measurement breaks. That ancestor is
the cause.

State it as **"X breaks because property Y = Z"**, with the measured value.

**Stress it.** Inject worst-case content, a 64-character unbreakable string, and measure
again. Breaking harder confirms you found the load-bearing property, and that reading is
what stage 6 re-runs against the fix.

Read the numbers against the named cause: a measurement that contradicts it means the cause
is wrong, and the walk up the tree starts again.

## Logic and data

Map the real call graph by grepping the callers. Read the function and the code that calls
it. Reproduce with a failing test or a logged value, so you have an observed wrong output
beside the expected one. Read the schema and the types. When the work talks to an MCP server,
call that server's tools through `npx @modelcontextprotocol/inspector` first, so the
reproduction runs against the tool surface the server really exposes.

State it as **"function X produces Y because Z"**, with `file:line`.

## Both

Produce a reproduction you can run on demand. A bug you cannot reproduce, you cannot prove
fixed.

## Write it down

To `brainstorms/<slug>-diagnosis-<date>.md`:

| Part | Content |
|---|---|
| Reproduction | The exact steps or command |
| Measurement | The numbers, as read |
| Location | `file:line` of the single cause |
| Stress result | What happened under worst-case input |
| Success condition | The checkable statement that becomes true when fixed |

The success condition ends in a number or a boolean: `scrollWidth <= clientWidth`,
`fn(x) === 17.5`, `endpoint returns 200 with 4 rows`. It carries through to stage 6, where it
is measured the same way.

## Reading a baseline, for behaviour that does not exist yet

New behaviour has no defect and no cause. It still has a reality the plan must fit, and
reading it is what stops the plan inventing a codebase.

| Part | Content |
|---|---|
| Seam | Where this behaviour attaches: the function, route, or component, with `file:line` |
| Baseline | What happens there today, read rather than assumed. Often "this route returns 404" |
| Neighbours | What already does something similar, so the new thing matches it or reuses it |
| Success condition | The checkable statement that becomes true once it exists |
| Untouched | What keeps working exactly as it does now |

The success condition ends in a number or a boolean the same way: `POST /invoices returns
201 and the row appears in the list`. Stage 6 measures it against the same seam.

Write it to the same diagnosis file.

## Done

This stage has finished when the file exists, its success condition is checkable, and one of
these holds:

- **Cause path:** the cause is named with a `file:line` or a measured property, and the
  reproduction runs on demand.
- **Baseline path:** the seam is named with a `file:line` and the current behaviour there was
  read rather than assumed.

Planning starts after that, never before.
