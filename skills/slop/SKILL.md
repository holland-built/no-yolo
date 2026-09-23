---
name: slop
description: Check TypeScript or JavaScript code for the patterns AI agents write and humans do not - type casts stacked on type casts, accumulator copies inside reduce, Reflect.apply and Reflect.get. Use when the user says slop, check for slop, anti-slop, lint this, or asks whether AI-written code in a project is any good.
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

The rules catch what an agent writes when it is guessing: a cast chained onto another cast, a
value widened only so it can be cast again, a `reduce` that copies its accumulator every pass,
`Reflect.apply` or `Reflect.get` where a plain call would do. Those pass review by looking
normal. They are the reason code "works" until one caller sends something unexpected.

Only five rules are on. The comments at the top of `slop.config.ts` list every rule that is
off and why: most are the author's taste or ceremony that flagged correct code. Leave them off
unless the user asks.

Every hit is a warning, never an error. This is a review pass, not a build gate, and the user
does not run CI on these projects.

## Reading the result

Group the output by rule and report counts, highest first, because the shape of the list is
the finding. Many `no-widen-then-assert` hits mean casts are covering for types that are wrong;
a few `no-reflect-get` is a nitpick.

Say plainly which counts are worth acting on and which are noise, and never fix anything
unless the user asks — a repo can carry thousands of these, and a blanket fix is a large
untested diff.

## Done

Done is the command run, the per-rule counts on screen, and one sentence naming the finding
worth acting on. If the command failed, say so and say what broke; a check that did not run is
"couldn't tell", not a clean result.
