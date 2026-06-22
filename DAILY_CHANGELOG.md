# Changelog

## 2026-06-22

- added /ship skill — replaces publish-skills with quality-gated publish (md-check + antislop + eli5 + changelog)
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
