# Skill Triggers
<!-- All skill trigger blocks. Imported by CLAUDE.md via @docs/SKILL_TRIGGERS.md. -->
<!-- Add new skills HERE, not in CLAUDE.md. -->

# eli5
- **eli5** (`~/.claude/skills/eli5/SKILL.md`) - explain anything in plain English before you commit to it. Trigger: `/eli5`
When the user types `/eli5`, invoke the Skill tool with `skill: "eli5"` before doing anything else.
# my-skills
- **my-skills** - list skills you authored (not plugin packs) + relationship map. Trigger: `/my-skills`
When the user types `/my-skills`, invoke the Skill tool with `skill: "my-skills"` before doing anything else.
# improve
- **improve** (`~/.claude/skills/improve/SKILL.md`) - read-only senior-advisor audit across 9 categories (correctness, security, perf, tests, tech debt, deps, DX, docs, direction) → vetted findings → self-contained implementation plans for an executor model. Trigger: `/improve`
When the user types `/improve`, asks to audit a codebase, find improvement opportunities, or generate handoff plans for another agent, invoke the Skill tool with `skill: "improve"` before doing anything else.
# lockstep
- **lockstep** (`~/.claude/skills/lockstep/SKILL.md`) - hook-enforced gate: blocks Edit/Write/NotebookEdit until you say go. Not just a prompt reminder — mechanically denied. Trigger: `/lockstep`
When the user types `/lockstep`, says "lock step", "hold off on code", or "don't code yet", invoke the Skill tool with `skill: "lockstep"` before doing anything else.
# plan
- **plan** (`~/.claude/skills/plan/SKILL.md`) - pre-build planning interview: extracts design decisions, edge cases, constraints one question at a time before any code. Trigger: `/plan`
When the user types `/plan`, says "plan this", "help me think through", "plan before we build", or "interview me about", invoke the Skill tool with `skill: "plan"` before doing anything else.
# build
- **build** (`~/.claude/skills/build/SKILL.md`) - full feature pipeline: evidence → plan → Opus plan → approval gate → UI mockup gate → TDD → build → regression gate → prove. Trigger: `/build`
When the user types `/build`, says "build", or "build this feature end to end", invoke the Skill tool with `skill: "build"` before doing anything else.
# drawio-skill
- **drawio-skill** (`~/.claude/skills/drawio-skill/SKILL.md`) - generates diagrams (flowchart/architecture/ER/UML/sequence/network/mind-map) as .drawio XML, exports PNG/SVG/PDF/JPG via the native draw.io desktop CLI. Trigger: `/drawio-skill`
When the user types `/drawio-skill`, or asks for a diagram/flowchart/architecture diagram/ER diagram/UML diagram/sequence diagram, invoke the Skill tool with `skill: "drawio-skill"` before doing anything else.
# my-md
- **my-md** (`~/.claude/skills/my-md/SKILL.md`) - list all markdown files: global ~/.claude/ docs + current project artifacts. Trigger: `/my-md`
When the user types `/my-md`, says "list md files", or "show markdown files", invoke the Skill tool with `skill: "my-md"` before doing anything else.
# whats-next
- **whats-next** (`~/.claude/skills/whats-next/SKILL.md`) - checks task queue first, runs next task; if empty, scans project and proposes. Never shows a static menu. Trigger: `/whats-next`
When the user types `/whats-next`, says "what's next", "what should I do", or "now what", invoke the Skill tool with `skill: "whats-next"` before doing anything else.
# debate
- **debate** (`~/.claude/skills/debate/SKILL.md`) - 7-persona product-team debate: Senior Dev, Junior Dev, Sales Engineer, DevOps, Sales Leader, Eng Leader, Product Designer → Chairman oversight (evidence rulings, forced cross-examinations) → contradiction map → synthesis → peer review. Works on architecture, UI/UX, or feature-priority calls. Flag `--ui` swaps in a 5-persona UI/UX panel (Restraint Auditor, Operator, Spatial Designer, Accessibility Enforcer, Diagnostician) grounded in the project's design docs. Trigger: `/debate`
When the user types `/debate`, says "debate this", "stress test this decision", "get the team on this", or "should we build this", invoke the Skill tool with `skill: "debate"` before doing anything else.
# update
- **update** (`~/.claude/skills/update/SKILL.md`) - two-way reconciliation between local `~/.claude` and GitHub (behind AND ahead/uncommitted), plugin version status, vendored third-party skill drift; `/update full`/`rules`/`rollback`/`restore <name>` apply core changes, `/update vendor <name>`/`marketplace <name>` apply third-party updates (confirm-gated). Trigger: `/update`
When the user types `/update`, says "check for updates", "am I out of date", "what's new", "update my setup", or "rollback", invoke the Skill tool with `skill: "update"` before doing anything else.
# release
- **release** (`~/.claude/skills/release/SKILL.md`) - ONE context-aware publish command for any repo: reads the repo-root SHIP.md playbook and pushes to the right environment (dev/staging/prod). No SHIP.md → stops (lockstep) and helps you build one before anything ships. Never pushes blind against a moved remote — hard-stops if GitHub has commits you don't. Trigger: `/release`
When the user types `/release`, says "release", "push this", "commit and push", or "get this to github", invoke the Skill tool with `skill: "release"` before doing anything else.
# skill-discovery
When the user says "find skill for X", "what skill handles X", "which skill does X", or "what should I use for X", read `~/.claude/skills/my-skills/TAGLINES.md`, match X against the taglines, and return the single best-matching skill plus its trigger command. This is a routing rule, not a skill — do not invoke the Skill tool.
# diagnose
- **diagnose** (`~/.claude/skills/diagnose/SKILL.md`) - two modes: default = systematic 6-phase diagnosis (reproduce → minimize → hypothesize → instrument → fix → regression-test); `--debate` = 6 Opus personas argue competing root-cause theories → contradiction map → diagnosis + next step. Trigger: `/diagnose`
When the user types `/diagnose`, says "debug this", "can't figure out why", "something's broken", "argue about this bug", or "debate the bug", invoke the Skill tool with `skill: "diagnose"` before doing anything else.
# last-30
- **last-30** (`~/.claude/skills/last-30/SKILL.md`) - pulls gaining-traction signal (not all-time rankings) from GitHub/HN/YouTube/X filtered to last 30 days only. Trigger: `/last-30`
When the user types `/last-30`, says "what's trending in", "last 30 days", or "what's hot right now", invoke the Skill tool with `skill: "last-30"` before doing anything else.
# md-check
- **md-check** (`~/.claude/skills/md-check/SKILL.md`) - MD hygiene: line counts, topic-overlap, duplicate-rule detection (read-only audit); `--fix` APPLIES the fixes (dedupe/merge/trim/drift) behind one approve-all gate; `--drift` catches stale descriptions; `--orphans` catches dangling catalog references and unreferenced skills; `--pre <file>` pre-creation gate. Trigger: `/md-check`
When the user types `/md-check`, says "check md files", "md hygiene", "fix my md files", "dedupe my docs", or "clean up my docs", invoke the Skill tool with `skill: "md-check"` before doing anything else.
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
# design
- **design** (`~/.claude/skills/design/SKILL.md`) - fresh generation only, never preserves existing design: brand seed → Taste generators → 10 Opus mockups (8 paradigms + 2 wild) → slop validator → AI picks best → Chrome auto-opens → you confirm → Opus plan → Sonnet build. `--apply-spec <file>` swaps tokens from a DESIGN.md. Auto-redirects audit/review to `/design-audit`, existing-UI polish to the impeccable plugin. Trigger: `/design`
When the user types `/design`, says "design this", "new design", "redesign", "fresh look", "start over on the UI", "mock this up", "show me design options", "put a button here", "add a chat box", "drop in a card", "add a component", "drop in a component", invoke the Skill tool with `skill: "design"` before doing anything else.
# design-audit
- **design-audit** (`~/.claude/skills/design-audit/SKILL.md`) - 5 parallel lenses → adversarial verify every Critical → ranked violations table + P0/P1/P2 implementation plan. The audit itself is read-only (zero code, zero mockups) — but saying "fix it" afterward triggers a real 10-mockup fix pipeline scoped to the findings. Trigger: `/design-audit`
When the user types `/design-audit`, says "audit this UI", "review the design", or "find design problems", invoke the Skill tool with `skill: "design-audit"` before doing anything else.
# ingest-docs
- **ingest-docs** (`~/.claude/skills/ingest-docs/SKILL.md`) - per-repo doc ingestion pipeline: converts PDF/PPTX/DOCX/images in docs/raw/ → dense .md context files in docs/context/ via markitdown + LLM topic-match (NEW/UPDATE/REPLACE/COMBINE), approval table, manifest tracking. Trigger: `/ingest-docs`
When the user types `/ingest-docs`, says "ingest docs", "process raw docs", or "update context from docs", invoke the Skill tool with `skill: "ingest-docs"` before doing anything else.
# review
- **review** (`~/.claude/skills/review/SKILL.md`) - one mode, always thorough: diff review (correctness/bugs/over-engineering/Karpathy) AND full codebase health pass (fallow + trim + improve), max effort, every time. Bakes in secret scan and antislop on .md changes. One ranked findings list, one approve-all gate, then fixes everything approved. `--auto` skips the gate for unattended runs. Trigger: `/review`
When the user types `/review`, says "review this", "check the diff", "code health", "run health pass", or "review before merge", invoke the Skill tool with `skill: "review"` before doing anything else.
# quick-mockup
- **quick-mockup** (`~/.claude/skills/quick-mockup/SKILL.md`) - fast disposable placeholder-only HTML mockup for layout/spatial decisions. ONE file, gray boxes, system-ui font, served over http://, auto-opened in browser. No brand tokens, no slop-judge, no 10-variant pipeline — that's /design's job. Also the concrete tool that satisfies the global "never show ASCII mockups" rule for small/quick asks. Trigger: `/quick-mockup`
When the user types `/quick-mockup`, says "quick mockup", "sketch this", "throwaway mockup", or "just show me the layout", invoke the Skill tool with `skill: "quick-mockup"` before doing anything else.
