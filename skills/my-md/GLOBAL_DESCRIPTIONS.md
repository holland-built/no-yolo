CLAUDE.md|Loaded at the start of every session. Has the skill triggers, core rules, and your learned preferences. If Claude is behaving wrong, this is the first place to look.
CORE_RULES.md|The 5 rules that govern how Claude works with you — think before coding, simplicity first, surgical changes only, goal-driven tasks, Opus plans and Sonnet codes. The ground rules everything else builds on.
CODE_REVIEW.md|How /code-review reviews a diff — the 3-pass logic it uses, what it hunts for, what it ignores. Open this when you want to understand or tune how reviews work.
CONTEXT.md|What to do when a session gets long and Claude starts losing track. Has the strategies for keeping context clean without starting over.
PLANNING.md|The rules Claude follows before touching code — how to think through a task, what to settle before writing a line. Open this if Claude is jumping to solutions too fast.
README.md|Install guide and reference for the no-yolo setup — prerequisites, install steps, directory layout, skills inventory, and how the CLAUDE.md chain works.
SKILL_RECOMMENDATIONS.md|Ideas for new skills and tools sourced from your knowledge base — not built yet, just on deck. Open this when you're wondering what to build next.
SKILLS.md|How the skill and plugin system works — what a SKILL.md does, how triggers fire, how arguments get passed. Open this if you're building or debugging a skill.
SUBAGENTS.md|Rules for dispatching parallel agents — when to fan out, how to coordinate, what to watch out for. Open this before running a multi-agent task.
TESTING.md|The testing discipline — when to write tests, what counts as proof something works, TDD rules. Open this if you're about to skip a test.
UI_MOCKUPS.md|Rules for creating UI mockup variations before building any UI change — the 5-8 variation requirement, what each variant must cover. Open this before any visual design work.
HOOKS.md|Documents the hook scripts in ~/.claude/hooks/ — scripts that fire automatically at harness events (session start/stop, before a tool runs). Open this to understand or add automated behaviors.
MEMORY.md|Memory system reference — 4 types, fact file format, everyday workflow (auto-save / /remember-that / /memory-compile), what NOT to save, git rules. Merged from MEMORY_USAGE.md.
NO_YOLO.md|Skill authoring rules for when working in ~/.claude as the no-yolo repo — write for strangers, eli5 output standard, no-slop rules, what files are safe to publish.
ANTISLOP.md|25 AI writing tells (filler openers, em-dash spam, forbidden words) + GUI slop patterns. Canonical extraction target for /prompt-scan and /antislop.
CONTEXT_VOCAB.md|Shared vocabulary — name a concept here once, reference it in prompts to cut token cost. Has ~/.claude system terms; add project-specific terms while working, delete after.
learnings.md|Compiled prompt conventions written by /prompt-scan. Feeds /better_prompt. Appends dated sections on each run — never overwrites prior entries.
DAILY_CHANGELOG.md|Running log of every change shipped — /release appends a dated entry here before pushing. Open to see what changed and when.
README_FORMAT.md|Spec file listing the 15 required README section headings. /release reads this and hard-blocks the commit if any section is missing or renamed.
SKILL_TRIGGERS.md|Source of truth for every skill trigger rule — what phrases fire which skill. CLAUDE.md imports this. Edit here, not in CLAUDE.md directly.
THIRD_PARTY_SKILLS.md|Registry of vendored (non-plugin) third-party skill content, pinned to an upstream commit per row. /update reads this to flag drift — read-only, never auto-pulls.
.pending-tasks.md|Session task queue. /whats-next reads this first and runs the next unchecked item. Add tasks here to queue work across sessions.
HOOKS_INTERNALS.md|Developer reference for the 4 caveman hook JS modules — what each does, when it fires, exports, and security notes.
SHIP.md|Release playbook for this repo — environments, pre-push steps, hard guards, optional GitHub release recipe. /release reads and runs it; never push without it.
