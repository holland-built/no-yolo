# DESIGN_REFS: shared reference routing for design pipelines

Read-only reference index for `/design`, `/design` (audit mode), `/build`, and any UI work.
Every path below is **reference text, never invoked as a skill**. Rules:

- **READ, never invoke.** Two are `disable-model-invocation: true` (`pick-ui-library`, `review-animations`), the Skill tool will refuse them.
- **Missing path = skip silently.** A reference that isn't on disk never blocks, never errors, never gets mentioned.
- **The project's own tokens always win.** No reference's palette, typeface, or opinion overrides tokens extracted from the project.
- **Read only what this task needs.** Never all nine. Match the WHEN heading, read that row, stop.

## Coherence: making a screen look shaped by one mind

Read this row FIRST on any surface with more than a couple of components. It is the
chosen design authority, picked by the owner on 2026-08-20 over UI Craft after a
head-to-head on the same screen. One authority only: nothing else in this file gets to
overrule it on radius, spacing, shadow, icon style, type scale, motion or control height.

| Path | Read it for | Ignore |
|---|---|---|
| `~/.claude/.agents/styleseed-engine/VISUAL-CRAFT.md` | §C0 the coherence laws: pick ONE family per axis (radius, shadow, colour roles, 8px spacing, icon style, type scale, easing, border weight, state layers, control height) and treat a mixed axis as a lint error. Then the numeric craft defaults below it | Its "read before scaffolding" framing. Read the axis table even mid-task |
| `~/.claude/.agents/styleseed-engine/RULESETS.md` | Choosing one output grammar for the surface, before any colour or type decision | Anything once a grammar is already locked for this project |
| `~/.claude/.agents/styleseed-engine/DESIGN-LANGUAGE.md` | The full 74-rule set. Big (2858 lines): open it only for the specific rule you are checking, never end to end | Reading it as an overview. Use VISUAL-CRAFT for that |
| `~/.claude/.agents/styleseed-engine/PALETTE-RECIPES.md` · `BRAND-RECIPES.md` | Deriving a semantic palette that is not the default indigo | The project's own tokens always win over any recipe |

**Vendored, not installed as skills.** `PROVENANCE.txt` in that folder pins the upstream
revision. The 23 `ss-*` skills the installer created were deliberately removed from the
loaded path: `docs/DESIGN_SURFACES.md` allows three doors and StyleSeed would have added
twenty-three. The rules are reference here; `/design` stays the door.

**The scored gate is per-project, and is NOT wired up.** `ss-score`'s checker
(`~/.claude/.agents/skills/ss-score/scripts/styleseed-check.mjs`) needs a `.styleseed/`
registry that `ss-setup` writes into a specific project. Run against a bare folder it
returns one finding, `SS000 registry is missing`, and no score. Measured 2026-08-20. So
today StyleSeed contributes rules, not enforcement. Do not describe a screen as "scored"
unless that registry actually exists in the project you are working in.

## Picking a visual direction
| Path | Read it for | Ignore |
|---|---|---|
| `~/.claude/skills/interface-design/SKILL.md` | Domain / colour-world / signature exploration; squint, swap, signature and token tests; concentric corner radius; surface-elevation percentages | Marketing pages, landing pages, campaigns (product UI only (dashboards, admin, settings) READ only) `disable-model-invocation: true` |
| `~/.claude/skills/design/TASTE_CORE.md` | The three dials (`DESIGN_VARIANCE` / `MOTION_INTENSITY` / `VISUAL_DENSITY`); brief → real-design-system map |, |

## Structuring component rules and QA criteria
| Path | Read it for | Ignore |
|---|---|---|
| `~/.agents/skills/impeccable/SKILL.md` | Guideline authoring workflow, required output structure, component rule expectations, quality gates | **`## Brand`, `## Style Foundations`, `## Rules: Do`, `## Rules: Don't`, and NEVER read the sibling `DESIGN.md`.** They impose a foreign palette (#CC8800, cream) and typeface (Chakra Petch). Shapes how rules are written, never the visual direction |

## Deciding whether and how something animates
| Path | Read it for | Ignore |
|---|---|---|
| `~/.claude/skills/find-animation-opportunities/SKILL.md` | Read FIRST when the question is *should this animate at all* (formal 4-question gate, required rejected-candidates list | READ only) `disable-model-invocation: true` |
| `~/.claude/skills/improve-animations/SKILL.md` | A whole codebase's motion, not one diff: prioritized audit plus self-contained implementation plans | READ only: `disable-model-invocation: true` |
| `~/.claude/skills/apple-design/SKILL.md` | Gesture/physical motion: momentum-projection and rubber-band formulas, velocity handoff, materials & depth, haptics, `prefers-reduced-transparency` / `prefers-reduced-contrast` | Static surfaces (tables, forms, settings) (skip the read entirely. READ only) `disable-model-invocation: true` |
| `~/.claude/skills/emil-design-eng/SKILL.md` | Implementation values: per-element easing/duration table, `clip-path` techniques, Sonner principles, blur-masked crossfades, `@starting-style`, never animate from `scale(0)`, stagger 30–80ms | READ only, `disable-model-invocation: true` |
| `~/.claude/skills/review-animations/SKILL.md` | Reviewing motion already written: diff-scoped review, remedial preference hierarchy | READ only, `disable-model-invocation: true` |

## Choosing a component library
| Path | Read it for | Ignore |
|---|---|---|
| `~/.claude/skills/pick-ui-library/SKILL.md` | Curated library table, common mismatches: charts, state, virtualization, drag-and-drop, animation runtime | READ only: `disable-model-invocation: true`. Its UI-primitive rows lose to the project's detected prefab library (`PREFAB_SOURCING.md`) |

## Naming an effect
| Path | Read it for | Ignore |
|---|---|---|
| `~/.claude/skills/animation-vocabulary/SKILL.md` | Reverse lookup only: describe an effect, get its name | Not a design reference. Use when naming a motion, never when deciding one READ only: `disable-model-invocation: true` |

## Reaching for a shader or generative background
| Source | Read it for | Ignore |
|---|---|---|
| [`paper-design/shaders`](https://github.com/paper-design/shaders) | Zero-dependency canvas shaders installable from npm, mesh gradients, grain, warp, dithering. Reach for it when a surface wants a living background and the alternative is a static gradient image. Apache-2.0 | Anything static. A shader is a running program on the page; a flat colour or an SVG gradient is the correct answer far more often than not |

**External URL, not vendored.** Nothing is on disk, so there is no content hash. It is registered
in `docs/BORROWED.md` as `url-only` with the revision below pinned, and `/checkup` compares that
pin against upstream on every run, GitHub URLs are checkable, so this is a real drift check
rather than a documentation note.

| | |
|---|---|
| Pinned revision | `7002061d8389781a45e479584deeca0cf538474e` |
| Licence | Apache-2.0 |
| Recorded | 2026-08-18 |
