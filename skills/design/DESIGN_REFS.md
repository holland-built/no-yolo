# DESIGN_REFS — shared reference routing for design pipelines

Read-only reference index for `/design`, `/design` (audit mode), `/build`, and any UI work.
Every path below is **reference text, never invoked as a skill**. Rules:

- **READ, never invoke.** Two are `disable-model-invocation: true` (`pick-ui-library`, `review-animations`) — the Skill tool will refuse them.
- **Missing path = skip silently.** A reference that isn't on disk never blocks, never errors, never gets mentioned.
- **The project's own tokens always win.** No reference's palette, typeface, or opinion overrides tokens extracted from the project.
- **Read only what this task needs.** Never all nine. Match the WHEN heading, read that row, stop.

## Picking a visual direction
| Path | Read it for | Ignore |
|---|---|---|
| `~/.claude/skills/interface-design/SKILL.md` | Domain / colour-world / signature exploration; squint, swap, signature and token tests; concentric corner radius; surface-elevation percentages | Marketing pages, landing pages, campaigns — product UI only (dashboards, admin, settings) READ only — `disable-model-invocation: true` |
| `~/.claude/skills/design/TASTE_CORE.md` | The three dials (`DESIGN_VARIANCE` / `MOTION_INTENSITY` / `VISUAL_DENSITY`); brief → real-design-system map | — |

## Structuring component rules and QA criteria
| Path | Read it for | Ignore |
|---|---|---|
| `~/.agents/skills/impeccable/SKILL.md` | Guideline authoring workflow, required output structure, component rule expectations, quality gates | **`## Brand`, `## Style Foundations`, `## Rules: Do`, `## Rules: Don't` — and NEVER read the sibling `DESIGN.md`.** They impose a foreign palette (#CC8800, cream) and typeface (Chakra Petch). Shapes how rules are written, never the visual direction |

## Deciding whether and how something animates
| Path | Read it for | Ignore |
|---|---|---|
| `~/.claude/skills/find-animation-opportunities/SKILL.md` | Read FIRST when the question is *should this animate at all* — formal 4-question gate, required rejected-candidates list | READ only — `disable-model-invocation: true` |
| `~/.claude/skills/improve-animations/SKILL.md` | A whole codebase's motion, not one diff: prioritized audit plus self-contained implementation plans | READ only — `disable-model-invocation: true` |
| `~/.claude/skills/apple-design/SKILL.md` | Gesture/physical motion: momentum-projection and rubber-band formulas, velocity handoff, materials & depth, haptics, `prefers-reduced-transparency` / `prefers-reduced-contrast` | Static surfaces (tables, forms, settings) — skip the read entirely. READ only — `disable-model-invocation: true` |
| `~/.claude/skills/emil-design-eng/SKILL.md` | Implementation values: per-element easing/duration table, `clip-path` techniques, Sonner principles, blur-masked crossfades, `@starting-style`, never animate from `scale(0)`, stagger 30–80ms | READ only — `disable-model-invocation: true` |
| `~/.claude/skills/review-animations/SKILL.md` | Reviewing motion already written: diff-scoped review, remedial preference hierarchy | READ only — `disable-model-invocation: true` |

## Choosing a component library
| Path | Read it for | Ignore |
|---|---|---|
| `~/.claude/skills/pick-ui-library/SKILL.md` | Curated library table, common mismatches — charts, state, virtualization, drag-and-drop, animation runtime | READ only — `disable-model-invocation: true`. Its UI-primitive rows lose to the project's detected prefab library (`PREFAB_SOURCING.md`) |

## Naming an effect
| Path | Read it for | Ignore |
|---|---|---|
| `~/.claude/skills/animation-vocabulary/SKILL.md` | Reverse lookup only — describe an effect, get its name | Not a design reference. Use when naming a motion, never when deciding one READ only — `disable-model-invocation: true` |
