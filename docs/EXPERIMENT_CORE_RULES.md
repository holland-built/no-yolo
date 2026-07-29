# Experiment: core rules unloaded (started 2026-07-29)

## What was done

`CLAUDE.md` no longer imports `docs/CORE_RULES.md`. The rules file itself is kept,
renamed to `docs/CORE_RULES.md.off` — the `.off` suffix means Claude Code never
loads it, but nothing is lost.

Result: the 35 core rules (think before coding, surgical changes, latest-stable
gate, challenge posture, and the rest) are not in context in any session.

## Why

Boris Cherny's advice, from the YC talk (`vid-boris-cherny-yc-delete` in the KB):
every six months delete your CLAUDE.md, skills and hooks, then see what the model
does. Anthropic cut ~80% of Claude Code's own system prompt when Opus 5 shipped,
because most of it was correcting behaviour the model now gets right unprompted.

The prior state was worse than either option: the file had been renamed away while
`CLAUDE.md` still imported it, so the import silently resolved to nothing. That is
the loss without the test. This makes the deletion deliberate instead.

Caveat recorded in the same KB page: Cherny's next sentence is *"when you use Claude
Code as a product, you do actually want some of these prompts."* Raw capability and
product behaviour are different targets. Expect some rules to earn their way back.

## How to finish the experiment

Work normally for a week or two. Note which rules you find yourself repeating by
hand — those are the ones that earned their place. Then rebuild
`docs/CORE_RULES.md` from the survivors only, and re-add the import.

Do not restore the file wholesale. That skips the point.

## How to restore everything, exactly as it was

```
cd ~/.claude
mv docs/CORE_RULES.md.off docs/CORE_RULES.md
```

Then in `CLAUDE.md`, under `## Core Rules`, replace the comment block with:

```
@docs/CORE_RULES.md
```

## Note for anyone installing this repo

`docs/CORE_RULES.md.off` ships with the repo but is not loaded. If you want the
core rules active in your own setup, run the two restore steps above.

Roughly 20 files still mention `CORE_RULES` in prose (README, several docs, a few
skills). Those are references, not imports — `verify.sh` passes with the file
unloaded. They are left in place so the rules can come back without re-editing
every mention.
