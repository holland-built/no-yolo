# Skill Triggers
<!-- All skill trigger blocks. Imported by CLAUDE.md via @docs/SKILL_TRIGGERS.md. -->
<!-- Add new skills HERE, not in CLAUDE.md. -->

# eli5
- **eli5** (`~/.claude/skills/eli5/SKILL.md`) - explain anything in plain English before you commit to it. Trigger: `/eli5`
When the user types `/eli5`, invoke the Skill tool with `skill: "eli5"` before doing anything else.
# code-health
- **code-health** (`~/.claude/skills/code-health/SKILL.md`) - three-phase codebase health pass: Fallow (static analysis) → Trim → Improve. All output as tables. Trigger: `/code-health`
When the user types `/code-health`, invoke the Skill tool with `skill: "code-health"` before doing anything else.
# my-skills
- **my-skills** - list skills you authored (not plugin packs) + relationship map. Trigger: `/my-skills`
When the user types `/my-skills`, invoke the Skill tool with `skill: "my-skills"` before doing anything else.
# code-review
- **code-review** (`~/.claude/skills/code-review/SKILL.md`) - three-pass diff review: correctness/bugs, over-engineering (trim), Karpathy surgical+simplicity. Supports `--fix` to apply findings, `--comment` for inline PR comments, effort flags (low/medium/high/max). Trigger: `/code-review`
When the user types `/code-review`, invoke the Skill tool with `skill: "code-review"` before doing anything else.
# ui-ux (internal sub-skill — not user-invocable)
- **ui-ux** - design intelligence backend: 161 palettes, 57 font pairings, 99 UX guidelines. Called internally by design-audit, design-fast, design-full as a reference lens. Not triggered directly by the user.
# my-md
- **my-md** (`~/.claude/skills/my-md/SKILL.md`) - list all markdown files: global ~/.claude/ docs + current project artifacts. Trigger: `/my-md`
When the user types `/my-md`, says "list md files", or "show markdown files", invoke the Skill tool with `skill: "my-md"` before doing anything else.
# whats-next
- **whats-next** (`~/.claude/skills/whats-next/SKILL.md`) - checks task queue first, runs next task; if empty, scans project and proposes. Never shows a static menu. Trigger: `/whats-next`
When the user types `/whats-next`, says "what's next", "what should I do", or "now what", invoke the Skill tool with `skill: "whats-next"` before doing anything else.
# debate
- **debate** (`~/.claude/skills/debate/SKILL.md`) - 6-persona product-team debate: Senior Dev, Junior Dev, Sales Engineer, DevOps, Sales Leader, Eng Leader → contradiction map → synthesis → peer review. Works on architecture, UI/UX, or feature-priority calls. Trigger: `/debate`
When the user types `/debate`, says "debate this", "stress test this decision", "get the team on this", or "should we build this", invoke the Skill tool with `skill: "debate"` before doing anything else.
# update
- **update** (`~/.claude/skills/update/SKILL.md`) - check for updates, preview what changed, apply full or rules-only update, rollback, or restore a removed skill. Trigger: `/update`
When the user types `/update`, says "check for updates", "am I out of date", "what's new", "update my setup", or "rollback", invoke the Skill tool with `skill: "update"` before doing anything else.
# ship
- **ship** (`~/.claude/skills/ship/SKILL.md`) - quality gates (md-check + antislop + eli5 + drift check, warn-only) + README structure hard-block → dated changelog → leak-guarded commit + push to no-yolo. Trigger: `/ship`
When the user types `/ship`, says "push skills", "publish to no-yolo", or "ship my work", invoke the Skill tool with `skill: "ship"` before doing anything else.
# skill-discovery
When the user says "find skill for X", "what skill handles X", "which skill does X", or "what should I use for X", read `~/.claude/skills/my-skills/TAGLINES.md`, match X against the taglines, and return the single best-matching skill plus its trigger command. This is a routing rule, not a skill — do not invoke the Skill tool.
# debug-debate
- **debug-debate** (`~/.claude/skills/debug-debate/SKILL.md`) - 6 repo-aware Opus personas argue bug root causes → contradiction map → diagnosis + next diagnostic step. No fix — diagnosis only. Trigger: `/debug-debate`
When the user types `/debug-debate`, says "argue about this bug", "what's breaking and why", or "debate the bug", invoke the Skill tool with `skill: "debug-debate"` before doing anything else.
# last-30
- **last-30** (`~/.claude/skills/last-30/SKILL.md`) - pulls gaining-traction signal (not all-time rankings) from GitHub/HN/YouTube/X filtered to last 30 days only. Trigger: `/last-30`
When the user types `/last-30`, says "what's trending in", "last 30 days", or "what's hot right now", invoke the Skill tool with `skill: "last-30"` before doing anything else.
# md-check
- **md-check** (`~/.claude/skills/md-check/SKILL.md`) - MD hygiene: line counts, topic-overlap, duplicate-rule detection; `--drift` mode catches stale CLAUDE.md descriptions; `--pre <file>` pre-creation gate. Trigger: `/md-check`
When the user types `/md-check`, says "check md files" or "md hygiene", invoke the Skill tool with `skill: "md-check"` before doing anything else.
# prompt-scan
- **prompt-scan** (`~/.claude/skills/prompt-scan/SKILL.md`) - reads all system prompt files + fetches current model release notes → appends dated section to ~/.claude/learnings.md. Feeds /better_prompt. Trigger: `/prompt-scan`
When the user types `/prompt-scan`, says "scan my prompts", or "refresh learnings", invoke the Skill tool with `skill: "prompt-scan"` before doing anything else.
# better_prompt
- **better_prompt** (`~/.claude/skills/better-prompt/SKILL.md`) - reads learnings.md, diagnoses a rough prompt, rewrites it with concrete target + scope + success criterion + correct skill route. Trigger: `/better_prompt`
When the user types `/better_prompt`, says "sharpen this prompt", or "improve my prompt", invoke the Skill tool with `skill: "better_prompt"` before doing anything else.
# antislop
- **antislop** (`~/.claude/skills/antislop/SKILL.md`) - diagnose AI writing/GUI slop tells against ANTISLOP.md; violations table + verdict, no rewrite. Trigger: `/antislop`
When the user types `/antislop`, says "check for slop", or "is this AI slop", invoke the Skill tool with `skill: "antislop"` before doing anything else.
# remember-that
- **remember-that** (`~/.claude/skills/remember-that/SKILL.md`) - unified memory manager: add facts, extract from context, delete, move, audit, compile. Trigger: `/remember-that`
When the user types `/remember-that`, says "remember that", "save this to memory", or "forget that", invoke the Skill tool with `skill: "remember-that"` before doing anything else.
# skill-audit
- **skill-audit** (`~/.claude/skills/skill-audit/SKILL.md`) - audits ~/.claude/skills/ across 4 dimensions: bucket fit, component gaps, missing verifiers, trigger conditions. Also builds verifiers and surfaces gotcha gaps. Trigger: `/skill-audit`
When the user types `/skill-audit`, says "audit my skills", "check my skill library", "find skill gaps", or "run skill audit", invoke the Skill tool with `skill: "skill-audit"` before doing anything else.
# design-audit
- **design-audit** (`~/.claude/skills/design-audit/SKILL.md`) - read-only design audit: Playwright screenshot + Lazyweb deep + Taste/Swiss/UIwiki/accessibility/code-health lenses → ranked violations table + top-10 improvements. No gates, no code. Trigger: `/design-audit`
When the user types `/design-audit`, says "audit this UI", "review the design", or "find design problems", invoke the Skill tool with `skill: "design-audit"` before doing anything else.
# design-fast
- **design-fast** (`~/.claude/skills/design-fast/SKILL.md`) - 7 parallel Sonnet mockups (5 redesign + 2 wild), slop judge, Chrome screenshot, HARD pick-gate. No code written — run /design-full to build. Trigger: `/design-fast`
When the user types `/design-fast`, says "design options", "mockup this fast", "show me design directions", or "quick mockup", invoke the Skill tool with `skill: "design-fast"` before doing anything else.
# design-full
- **design-full** (`~/.claude/skills/design-full/SKILL.md`) - full pipeline: audit → debate direction → 7 Opus mockups (5+2) → slop judge → 4 hard gates → token extraction → Opus plan → chains to /build. Nothing builds without an approved mockup. Trigger: `/design-full`
When the user types `/design-full`, says "full design pipeline", "design and build this", or "redesign and ship", invoke the Skill tool with `skill: "design-full"` before doing anything else.
