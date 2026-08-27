# Stage 5: Build

This file is the build-specific procedure. It runs here unless the owner has asked for
agents; if they have, the dispatch rules, the brief's contents, and the model-per-job table
live in `docs/DELEGATION.md`, and the "Before dispatching" section below applies.

## One slice at a time

Stage 4 handed over the agreed seam and the first failing test. Each remaining behaviour in
the plan goes through the same loop: write the failing test, watch it go red for the intended
reason, write the least code that turns it green, confirm green, then the next one.

The loop itself and what makes a test worthless are in `docs/TESTING.md`.

## Before dispatching, when the owner has asked for agents

Read every target file and its direct imports yourself. Write one brief per agent, each
carrying the target path, the exact change quoted from its plan step, the
`Already exists, do NOT recreate` note, and the blast radius.

Briefs for backend steps are drafted at plan approval, since they read the plan and the
target files and nothing from stages 3 or 4. UI briefs wait for the chosen variant and its
sourcing rows. Either way, re-read a brief against the agreed seam before dispatching it.

UI work: the brief names the variant section to match and its sourcing rows. Agents import
the mapped components rather than hand-rolling them.

## Dispatch by wave

Stage 2 grouped the plan's steps into waves from their `Depends on` lines. Dispatch wave 1 in
one call, up to five agents at a time; when every agent in it has returned and its edits are
in the tree, dispatch wave 2. A step whose dependency failed does not go out.

A wave holding one step is one agent, and that is the plan reporting real serial work rather
than a dispatch to fix.

## Reuse before writing

For every new symbol the build would introduce, search the tree for an existing one with the
same name or role. A sibling already doing the job means using it. The plan names most of
those symbols, so the search runs at plan approval, over the names the plan proposes:

```bash
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/dupe-check.sh" --symbols name1 name2
```

Each `DUPLICATE SYMBOL:` line is a candidate to read before the brief is written. A symbol
that appears later, from the chosen variant or from an agent mid-build, gets the same search
the moment it is proposed, not a pass on the grounds that the early search ran.

In a tree bigger than a grep can hold, search by role rather than by name: the symbol you
would introduce is rarely called what the existing one is called. Read the importers of a
candidate before reusing it, because a sibling that fits the name and not the job costs more
than writing the thing. When the `codebase-design` skill is installed, judge the candidate by
its depth, the behaviour it carries per unit of interface a caller has to learn; absent it,
the role test above stands on its own.

This paragraph named a package called `cxpak` until 2026-08-21, said it built a dependency
graph, and told you to run it. No package of that name has ever existed on any registry.

## The rival implementation

Fires when the plan names three or more target files, or when stage 2 accepted a blocking
finding. Otherwise it does not run.

Launch it the moment the plan is approved, beside the Codex edge-case job, because it reads
the plan and nothing later: both fire conditions (file count, a blocking finding) are known at
approval. The exception is a UI change, whose rival would be authoring against a variant
nobody has chosen; that one launches at the stage 3 pick, with the variant and the sourcing
rows named in the prompt. Either way it authors against the pre-build tree; stage 4's one test
file arrives in between, and `git apply --check` below is what catches a diff that no longer
fits. Background it so the stages between run while it works:

```bash
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/codex.sh" \
  "Read brainstorms/<slug>-plan-<date>.md — an approved implementation plan for this repository. Author a rival implementation of its ordered steps as ONE unified diff against the current tree: your own approach, not a guess at another author's. Honour the plan's blast-radius list and end at its success condition. At most 3 files and 200 changed lines; diff only the steps you would do differently if the plan is larger, and say which you skipped. Return only the unified diff, or BLOCKED: <reason>. No preamble." \
  "brainstorms/<slug>-rival-<date>.md" &
```

Read it after the build agents return. The runner buffers its whole session and prints it in
one write, so an empty file means still running.

Take the last block and strip everything before its first `diff --git`. Validate with `git
apply --check` in a throwaway worktree before reading it. Anything that fails to apply, times
out, or returns `BLOCKED:` is recorded as `rival: not run — <reason>` and the build proceeds.

Applies clean: read it hunk by hunk against what was built. For each divergence, pick one
with a one-line reason. Adopted hunks land through normal edits.

## After the agents return

Merge any worktree branches, run the build or typecheck command, and fix errors before
testing.

## Regression gate

Run the full suite. Any failure starts a fix loop: an Opus agent produces a fix plan scoped
to the broken behaviour, Opus agents apply it, the suite re-runs.

Three iterations is the cap. Still red after three: hand it to Codex once, with the failing
output, the diff, and the located cause. Fresh eyes from another model family is exactly the
stuck-loop case. Still red after that, stop and say so.

## Quality gates

Fan these out in one call once the suite is green. The secret scan and the lint run during
the fix loop instead, since neither reads a test result.

**Every time:**

| Gate | Passes when |
|---|---|
| Lint and typecheck | Zero new errors, warnings triaged |
| Duplicate scan | `hooks/dupe-check.sh --since <base-ref>` exits 0 |
| Secret scan | Nothing secret in the diff |
| Standards review | An agent that has not seen the plan finds no correctness or edge-case defect |
| Spec review | A separate agent confirms the diff is what was asked for, with no missing requirement and no scope creep |

**The standards reviewer reads the whole file, not only the diff.** A hunk can be correct
line by line and still be wrong for the file it lands in: a helper used once, a wrapper around
a wrapper, a flag added so one caller can skip the check everything else obeys. None of that
is visible in a diff, because the thing it clashes with is the code around it. The brief says
to open each changed file whole and judge the change against the conventions already there.

Its checklist, from reading `boudra/unslop` on 2026-08-25 against these gates and keeping only
what the duplicate scan cannot see:

| Look for | Because |
|---|---|
| A helper with one caller | It is a name and an indirection standing where three lines would read plainly |
| A coordinator calling a coordinator | Each layer that only forwards is a layer that has to be read |
| An escape-hatch flag | One caller opting out of the rule the rest obey, which is how a rule dies |
| `any`, `ts-ignore`, an empty catch | The type or the error was inconvenient, so the information was thrown away |
| `throw new Error("failed")` | The context the caller needs to act is in the variables, not in the string |
| A test asserting the implementation | It pins how the code works, so the next refactor breaks a test that found no defect |

The last two run as separate agents that cannot see each other. A change passes one and fails
the other, and merged reviewers hide that.

The duplicate scan is one command, run from the project root with the branch's base ref:

```bash
bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/dupe-check.sh" --since <base-ref>
```

It makes two passes: jscpd over the touched files for a block copied and edited, and a name
pass for a new top-level symbol already defined elsewhere in the tree. Its status decides the
row: 0 passes, 1 is a finding to resolve or waive under **Disagreement** below, and 3 is the
gate reporting it could not run, which is a flag rather than a pass. A run that prints
`jscpd: did not run` and exits 0 or 1 is the name pass answering alone; say which half ran.

**When the diff touches it:** auth, routes, secrets, queries or user input get a security
pass. A UI change gets an accessibility pass. A hot path gets a before-and-after measurement.

## Disagreement

A finding closes by fixing the code or by the owner waiving it. A gate does not close its own
finding by deciding it was wrong.

Two gates disagreeing about the same code is a flag, and the stricter verdict wins.

Disagreeing with a finding: say so in one line, then surface it anyway as
`GATE FLAG — <gate>: <finding>. My read: <why>. Ship anyway? (y/n)` and wait.

A gate that could not run is a flag, not a pass.

## Done

This stage has finished when the suite is green, every gate has reported a result or a reason
it did not run, and every open flag has been fixed or waived by the owner.
