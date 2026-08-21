# Fresh Start: ~/.claude rebuild plan, SUPERSEDED

> **Do not build from this file.** It was replaced by `docs/REBUILD_PLAN.md` on 2026-08-20,
> and that file has since been superseded in its turn. What was actually decided is in
> `docs/DECISIONS.md`. Kept for its usage measurements, which are still the only ones taken.

**Decided 2026-08-04/05.** Replaces incremental cleanup. Old setup stays on `main` and on
GitHub (`holland-built/no-yolo`) forever, so nothing in this plan destroys anything.

## Why

| Measured | Number |
|---|---|
| Skills built | 52 (33 own, 19 borrowed) |
| Skills never invoked across 474 sessions | 24 |
| Commits, last 30 days / all time | 179 / 281 |
| Most-edited file | `docs/DAILY_CHANGELOG.md` (169 edits) | <!-- gone-on-purpose -->
| Next 6 most-edited | the `skills/my-skills/` catalogue files (~390 edits) |

The config isn't too big. The self-describing layer around it is: catalogues, lock files,
changelogs, "which skill does what" docs. Every change became five changes. That layer is
what this plan deletes.

---

## Chunk 1. Skills: 33 own → 17

### Keep unchanged (11)
eli5 · whats-next · xcheck · release · debate · lockstep · last-30 · remember-that ·
ingest-docs · dep-audit · route-map

### Keep and absorb (6)
| Survivor | Absorbs |
|---|---|
| design | design-audit, quick-mockup, match-all |
| checkup | md-check, skill-audit, update, my-skills, my-md |
| health | diagnose, fixloop |
| build | plan, tdd |
| better-prompt | prompt-scan |
| watch | video-to-kb |

### Delete (2)
- **antislop:** prevention (always-loaded rules + slop-guard hook) replaces after-the-fact
  inspection. This was the user's explicit call: "only thing I want with anti-slop is keep it out."
- **literal:** becomes a phrase, not a command. The two hooks that implement it stay.

### Notes
- `dep-audit` and `route-map` stay **standalone**, deliberately NOT folded into `/release`.
  Both are long-running and the user pushes to GitHub often and small. Reversed twice. Do
  not re-propose folding them in.
- `route-map` and `dep-audit` were created 2026-08-02. Their zero use count proves nothing.

## Chunk 1b. The 19 borrowed skills: uninstall none

Symlinks into `~/.agents/skills/` and `~/.claude/.agents/skills/`, installed by the `skills`
CLI and tracked in `~/.agents/.skill-lock.json`. **Deleting the symlink does nothing.** The
installer restores it. They stop being commands and become fuel for the 17.

| Group | Skills | Consumed by |
|---|---|---|
| Ponytail (6) | ponytail, -review, -audit, -debt, -gain, -help | `/health` invokes -review, -audit, -debt by name (18 refs in health/SKILL.md) |
| Design taste (4) | apple-design, emil-design-eng, interface-design, pick-ui-library | `/design` reads via DESIGN_REFS.md |
| Animation (4) | animation-vocabulary, find-animation-opportunities, improve-animations, review-animations | `/design` reads via DESIGN_REFS.md |
| Standalone (3) | archify, improve, resolving-merge-conflicts | archify direct; improve feeds `/health`; merge-conflicts fires on the git situation |
| Orca (2) | computer-use, orca-cli | Orca app |

## Chunk 2. Agents: 13 → 2

**Keep:** react-specialist (116 uses) · accessibility-tester (13 uses)

**Delete (11):** typescript-pro · test-automator · qa-expert · code-reviewer ·
security-auditor · python-pro · debugger · architect-reviewer · refactoring-specialist ·
docker-expert · backend-developer

Rationale: the built-in general-purpose agent handled 1,522 jobs; all 13 specialists together
handled 173. None showed evidence of beating "general agent + one sentence of focus".

## Chunk 3. Hooks: 21 → 12

**Keep (12):** eli5-activate · slop-guard · format-typecheck · lockstep-guard ·
config-protection · secret-scan.sh · pre-commit · statusline.sh · mockup-autoopen ·
literal-mode-tracker · literal-statusline · node-shim.sh

**Delete (9):** catalog-selfheal · relock-guard · generated-file-guard · prompt-scan-nudge ·
worktree-guard · worktree-autoarm · worktree-autoclean · check-coherence.py · list-plugins.py

The first three exist only to maintain the catalogue system being deleted. The three worktree
hooks duplicate Orca's own. The last two are wired to nothing.

**Leave alone:** the 10 wirings calling `~/.orca/agent-hooks/claude-hook.sh`.

**Settings.json must be trimmed in the same change.** It is gitignored (holds live API keys),
so it will keep pointing at deleted hooks unless edited by hand.

## Chunk 4. Docs: 26 → 15

**Keep (10):** ANTISLOP.md · learnings.md · SHIP.md · SUBAGENTS.md · MCP_SERVICES.md ·
MEMORY.md · CONTEXT.md · PLANNING.md · TESTING.md · CODE_REVIEW.md

**Keep because the repo stays public (3):** README.md · INSTALL.md · README_FORMAT.md

**Rewrite (1):** CLAUDE.md, from scratch, under 40 lines

**Merge (1):** UI_MOCKUPS.md → into ANTISLOP.md

**Delete (10):** DAILY_CHANGELOG.md + `docs/changelog/` · MAP.md · SKILLS.md ·
THIRD_PARTY_SKILLS.md · SKILL_TRIGGERS.md · SKILL_RECOMMENDATIONS.md · NO_YOLO.md ·
FLAGS.md · CONTEXT_VOCAB.md · HOOKS.md

## Chunk 5. 8 design reference files, NOT DONE

Open question: do any of the 8 overlap each other, or turn out to be low quality? ~20 min.
Happens inside the `/design` merge.

## Anti-slop: 6 homes → 3

| Home | Holds |
|---|---|
| `docs/ANTISLOP.md` | The one list. Absorbs UI_MOCKUPS.md |
| `hooks/slop-guard.js` + `slop-patterns.json` + tests | The blocker. Machine-readable, untouched |
| `skills/design/vendor/taste-skill/` | Third-party, ~2,600 lines, never edited, read on demand |

Gone: the antislop skill, UI_MOCKUPS.md, TASTE_CORE.md (moves into `/design`'s reference folder).

**The deciding rule, reusable:** a rule lives in exactly one file; everything else points at it.
Which file: *does a machine read it?* → own file. *Did someone else write it?* → untouched
folder. *Otherwise* → the one list.

## Plugins

| Plugin | Fate |
|---|---|
| codex | Keep, backs `/xcheck` (30 uses) |
| caveman | **Gone.** Removed 2026-08-03 in `eb14eb6`, along with its 9 tracked files. This row said "Keep, its agents ran 232 times" until 2026-08-05, two days after the removal, and that stale row caused caveman to be treated as wanted and re-updated. Usage counters record the past; they are not evidence something is still wired in |
| design-and-refine | Delete, 0 real invocations |
| superpowers | **Gone in practice, confirmed 2026-08-06.** Its four skills (`brainstorming`, `systematic-debugging`, `test-driven-development`, `using-superpowers`) sat in `~/.agents/.skill-lock.json` with no files on disk, no shortcut pointing at them, and the marketplace missing from `enabledPlugins`. The four ghost entries were deleted from the lockfile. The downloaded `plugins/marketplaces/superpowers-marketplace` clone is still on disk and is the last piece to remove. This row read "3 real uses each. Leave for now" until today, the same stale-counter mistake the caveman row above documents |
| ecc | 3 real uses. Leave for now |

---

## DONE already (2026-08-04)

The 2026-07-29 core-rules experiment was closed out early. 35 rules → 8, rebuilt from
survivors only per the experiment's own instruction ("do not restore wholesale").
`docs/CORE_RULES.md` written; `CORE_RULES.md.off` and `EXPERIMENT_CORE_RULES.md` deleted;
CLAUDE.md and README.md references fixed. `verify.sh` passes 20/20. **Not yet committed.**

Junk cleared 2026-08-05: `file-history/`, `debug/`, two dead logs, three settings backups
273 MB. `settings.json` verified intact.

---

## Execution

**Method: empty room.** Start with nothing; a skill, hook or doc comes back only when
something that survived actually reads it. This is what makes chunks 3 and 4 self-answering.

| Step | Time |
|---|---|
| 0. Commit + push today's work so `main` is the undo button | 5 min |
| 1. Set up a copy folder (approach A, old setup keeps working, no dead window) | 5 min |
| 2. Write the new CLAUDE.md from scratch, under 40 lines | 20 min |
| 3. Copy back the 17 skills, performing the 6 merges | ~6 hrs |
| 4. Copy back the 2 agents | 2 min |
| 5. Add back only the hooks and docs the 17 actually read; trim settings.json to match | falls out |
| 6. Swap the copy folder in when it's finished. Live on it two weeks | n/a |

**Approach B (wipe in place) was rejected.** It leaves ~6 hours with no skills and a
settings.json pointing at deleted hooks.

## Still open

| # | Decision |
|---|---|
| 1 | Commit the July-29 close-out (4 changed files, unsaved) |
| 2 | Chunk 5 now, or start building |
| 3 | Chat history: keep all 3.1 GB / delete pre-5-July (709 MB) / delete all |

## Standing corrections: do not repeat

- Grepping session transcripts for a skill name counts **mentions, not uses**. Every session
  prints the skill list into its own context. Only `"skill":"..."` tool calls and
  `"subagent_type":"..."` are real invocations. This produced three wrong numbers on 2026-08-04.
- Check a skill's creation date before calling it unused.
- The user asked for one chunk at a time. Do not jump ahead to execution.
