# Changelog

## 2026-06-22

- reorganized docs into docs/ subfolder — moved all .md files from root except CLAUDE.md and README.md
- updated README.md — directory layout table reflects new docs/ paths
- updated my-skills SKILL.md — $ARGUMENTS substitution, fast/deep/default modes, TAGLINES.md for short cells
- updated my-skills TAGLINES.md — trimmed all entries to ≤60 chars
- added model: haiku to 7 lightweight skills — antislop, eli5, md-check, my-md, my-skills, remember-that, whats-next
- added /ship skill — replaces publish-skills with quality-gated publish (md-check + antislop + eli5 + changelog)
- deleted 16 root MDs (now live in docs/ from prior commit)
- added memory/ safe subset to git — SCHEMA.md, CLAUDE.generated.md, bin/*.py (facts/ stays gitignored due to provenance UUIDs)
- updated .gitignore — memory/ now partially tracked; compile-manifest.json and facts/ excluded
- updated my-skills SKILL.md — pipe table output (4 columns: skill, what, when, why); removed broken wrap() + html br approach
- fixed remember-that SKILL.md description — "view" → "extract from context" (drift fix)
- added /antislop skill — AI writing/GUI slop detection against ANTISLOP.md
- added /better-prompt skill — rewrites rough prompts using learnings.md
- added /prompt-scan skill — scans system prompt files + model release notes → learnings.md
- added /plan-feature skill — no-code planning gate: evidence → grill-me → Opus plan → approval
- added /build-feature skill — reads approved plan → TDD → build → regression → prove
- added /debug-debate skill — 6 Opus personas argue bug root cause in parallel
- added /last-30 skill — pulls 30-day trending content from GitHub/HN/YouTube/X
- added /md-check skill — MD hygiene: line counts, overlap detection, pre-creation gate
- added ANTISLOP.md — 25 AI writing tells + GUI slop patterns reference file
- added CONTEXT_VOCAB.md — shared vocabulary file for token reduction
- rewrote /whats-next — session task queue first, runs next task, creative scan when empty
- rewrote README.md — trimmed from 391 to 157 lines
- updated setup.sh — added plugin awareness step (reads installed_plugins.json)
- updated /update skill — added plugin status step 4.5
- updated /forge — rewritten as thin wrapper calling /plan-feature then /build-feature
- updated /debate — parallel Opus mandatory, never inline
- updated /ui-wild — read-before-edit guard added
- updated /grill-me — added no-code gate pointing to /plan-feature
- updated /ui-ux — removed 52 lines of duplicate sections
- updated CLAUDE.md — added triggers for 10 new skills
- updated SKILLS.md — added new skill rows
- updated UI_MOCKUPS.md — cross-ref pointer to ANTISLOP.md
- updated hooks/reflect-claude-md-stop.sh — brainstorms safety net for memory reminders
- updated my-skills STORIES.md + TAGLINES.md — all new skills registered
- updated my-md GLOBAL_DESCRIPTIONS.md — ANTISLOP.md, CONTEXT_VOCAB.md, learnings.md added
- fixed CLAUDE.md — corrected stale skill descriptions for my-skills, code-review, whats-next, quick-design, ship, md-check; removed trigger collision between ui and ui-wild
- added --drift mode to md-check — LLM judge cross-checks CLAUDE.md descriptions against SKILL.md source of truth
- wired drift check into ship Phase 1d — runs on every publish as warn-only gate
- updated my-skills STORIES.md — corrected impeccable entry (design system author, not aesthetic applicator)
- updated impeccable SKILL.md — accurate description + trigger conditions moved from CLAUDE.md into skill frontmatter
- converted /remember-that from commands/ to skills/ — now shows blue, added trigger to SKILL_TRIGGERS.md
- deleted /start command — unused
- deleted build-feature and plan-feature skills — superseded by /forge
- deleted graphify skill — removed from setup
- updated my-skills STORIES.md — added remember-that story
- updated my-skills SKILL.md — 4-column table with when/why, line-wrap via fold+awk
- updated my-skills WHEN_TO_USE.md — added 10 missing skills
- updated my-skills WHY_TO_USE.md — added 10 missing skills

## 2026-06-23

- added docs/README_FORMAT.md — spec file listing 15 required README section headings; /ship reads this to validate structure
- added "Skills with modes" section to README.md — table of 7 skills with flags/routes (/ui, /update, /my-skills, /md-check, /code-review, /code-health, /remember-that)
- added Phase 3c README format hard-block to /ship — commits blocked if any required README section is missing or renamed
- updated ship/SKILL.md description — reflects new README format validation gate
- updated memory/CLAUDE.generated.md — compiled new eli5-on-output feedback rule
- merged "Skills with modes" section into inventory table — 3-col (Skill | What it does | Modes & flags), 7 skills get described modes, 18 get dash
- deleted standalone ## Skills with modes section from README.md
- removed ## Skills with modes from README_FORMAT.md required sections (14 remain)
- fixed README Prerequisites: Mac home path corrected to /Users/<username>, Linux /home/<username>
- added inline skill definition at first use (line 13) — "A skill is a command you run by typing /name"
- removed manual mkdir brainstorms from "Set up a new project" — skills create it automatically
