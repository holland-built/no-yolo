---
name: slop
description: Check TypeScript or JavaScript code for the patterns AI agents write and humans do not - unchecked type casts, loose dictionary types, unknown parameters. Use when the user says slop, check for slop, anti-slop, lint this, or asks whether AI-written code in a project is any good.
---

# slop

Run the shared anti-slop rules over a project. Nothing is installed into the project: the
rules, the linter and the config all live in `~/.claude/tools/anti-slop/`, so every project
gets the same check and none of them carry a dependency for it.

```bash
cd ~/.claude/tools/anti-slop && npx oxlint -c slop.config.ts <absolute paths to check>
```

Pass the source folders, not the project root — `src`, `app`, `components`, `lib`. The config
already ignores `node_modules`, `.next`, `dist`, `build` and `coverage`, but pointing at a
whole repo still walks everything else.

## What it is for

The rules catch what an agent writes when it is guessing: a type cast with no evidence behind
it, a parameter typed `unknown`, a dictionary type that accepts anything. Those pass review by
looking normal. They are the reason code "works" until one caller sends something unexpected.

Three rules are off in the shared config — `require-readable-spacing`, `no-runtime-typeof` and
`no-object-parameters`. They are the author's own taste and they fight React and plain
JavaScript. Leave them off unless the user asks.

Every hit is a warning, never an error. This is a review pass, not a build gate, and the user
does not run CI on these projects.

## Reading the result

Group the output by rule and report counts, highest first, because the shape of the list is
the finding. Hundreds of `require-safety-comment-for-type-assertion` means the codebase casts
types without saying why; a dozen `no-array-filter-map` is a performance nitpick.

Say plainly which counts are worth acting on and which are noise, and never fix anything
unless the user asks — a repo can carry thousands of these, and a blanket fix is a large
untested diff.

## Done

Done is the command run, the per-rule counts on screen, and one sentence naming the finding
worth acting on. If the command failed, say so and say what broke; a check that did not run is
"couldn't tell", not a clean result.
