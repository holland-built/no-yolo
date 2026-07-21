## Design

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| design | Fresh UI generation: 10 Opus mockups (8 paradigms + 2 wild) → AI picks → you confirm → build. | Starting a new design or full redesign — want truly fresh, not an incremental patch | 10 mockups at once (8 distinct paradigms + 2 wild) + slop validator kills the generic — one pick becomes a full build plan |
| quick-mockup | Fast throwaway HTML layout mockup — gray boxes, served live, browser-opens. Not /design. | Just need to see a layout before deciding, no brand polish needed yet | Gray boxes served over http:// and auto-opened, no brand tokens or slop-judge — satisfies "never show ASCII mockups" without the full /design pipeline |
| design-audit | Audit UI across 5 lenses → ranked violations → optional 10-mockup fix pipeline. | Any UI that feels off — audit first, then optionally fix with 10 mockups in the same command | Five independent lenses catch what one reviewer misses — audit is read-only, fix gate keeps you in control before anything builds |

## Build

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| build | Full feature pipeline: plan → UI → code → tests → proof. | Starting any non-trivial feature from scratch | Nothing ships without a plan, tests, and proof. No more "works on my machine" done claims |
| plan | One-question-at-a-time interview that forces hard decisions before any code. | Fuzzy feature or system idea, before running /build | First-try success goes from ~70% to ~90% when the hard calls are made up front, not mid-build |

## Review

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| health | Diff + codebase health + /last-30 trends, with every fix walked past you one at a time. | Before merging any non-trivial change, when a codebase needs a cleanup pass, or when you want fixes informed by what's currently trending | Replaces three separate commands with one routed pass — trend radar, secret scan and antislop are automatic, and you approve each fix one at a time instead of one blind batch |
| xcheck | Cross-model critique: Codex reviews your plan, Claude adjudicates, 2-round cap. | Automatically inside /plan, /debate, /build, /diagnose --debate, /design-audit — or /xcheck to bounce any plan off Codex manually | A different model family catches blind spots self-review can't — findings-only protocol stops rewrite ping-pong, convergence gate stops endless nitpicking |

## Research

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| last-30 | Trending now (last 30 days) from GitHub, HN, Reddit, YouTube, X. | Starting research on a topic and want signal from the past month, not all-time rankings | GitHub stars and HN posts from 3 years ago are noise. Last 30 days is actual traction |
| video-to-kb | Turn a YouTube video into a searchable KB note. | Good talk or tutorial worth keeping permanently | Talks are perishable. One command turns them into permanent, searchable KB nodes |
| ingest-docs | Converts PDFs/decks/docs into dense context files Claude reads at runtime. | You have source material Claude should know about | Dedupes against what's already there and tracks changes in a manifest — re-runs only touch what's new |

## Quality

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| diagnose | Root-cause analysis: solo 6-phase or --debate for 6 Opus personas. | Stuck on a bug > 20 min — solo for systematic, --debate when multiple plausible theories | Solo: forces systematic evidence-gathering. --debate: six theories surface the one you missed |
| debate | 7-persona product-team debate → contradiction map → one decisive verdict. | Architecture calls, UI/UX choices, or "what should we build next" when you want real pushback | Ends with YES/NO/CONDITIONAL and the one reason that settles it — no "it depends" |
| improve | Read-only codebase audit across 9 categories → ranked findings → self-contained plans for an executor model. | Want a deep audit-plus-plan pass, not just a diff review | Vets every subagent finding itself before reporting; plans are written for a weaker model with zero session context |

## Prompting

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| prompt-scan | Reads global Claude MD files + current model's release notes, writes a dated snapshot to learnings.md. | Once on setup, and again whenever a new Claude model ships | Keeps /better-prompt's reference material from going stale |
| better-prompt | Rewrites a rough prompt with a named target, scope boundary, success criterion, and correct skill route. | Before running a fuzzy prompt through any skill | Shows before/after with rationale instead of guessing why a prompt underperformed |

## Diagrams

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| archify | Architecture/flow/sequence/dataflow/state diagrams as zero-dep HTML+SVG. Accepts Mermaid. | Any architecture, workflow, sequence, dataflow, or state diagram — or converting a Mermaid sketch | Self-contained HTML with inline SVG, dark/light toggle, in-browser PNG/SVG export — no diagram app, no layout-engine install |

## Memory

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| remember-that | Save, extract, delete, move, audit facts across sessions. | End of a session with useful decisions or preferences worth keeping | Preferences decay between sessions. This makes them permanent without manual file editing |

## Meta

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| my-skills | This menu. | Forgot what skills exist | You forget you have tools. This is the map |
| whats-next | Shows unfinished work or next actions as a plain-English table with a "type this" column. Never static. | Session start — orient before picking what to do | Prevents starting something new while something is already half-done |
| release | The one context-aware publish command for any repo: reads the repo-root SHIP.md playbook and pushes to the right environment (dev/staging/prod). No SHIP.md yet? It stops and helps you build one before anything ships. | Ready to commit + push any repo to GitHub | One verb everywhere — each repo's SHIP.md holds its own recipe, so you never memorize per-repo commands |
| eli5 | Explains any skill, plan, or finished work in plain English — short, no jargon; a small chart when there's a list, one plain sentence when there isn't. | Before committing to something you don't fully understand — or after work finishes, to catch up in plain English | Forces the "wait, do you actually get this?" check before you say yes |
| my-md | Lists every markdown file — global Claude docs plus current project's notes. | Lost track of what notes exist | One command instead of hunting across two directory trees |
| md-check | Audits ~/.claude docs for size, duplicate topics, and duplicate rules; `--drift` finds stale descriptions, `--orphans` finds dangling/unreferenced skills, `--fix` applies the fixes behind one approve-all gate, `--pre` is a pre-creation gate. | Notes piling up or repeating themselves | Other skills call it with --pre before writing a new note, so you never get two files on one topic |
| skill-audit | Audits the whole skill library: bucket fit, missing pieces, unverified output, stale triggers. | Wondering if your skills are well-structured or missing something | One pass instead of manually eyeballing every SKILL.md |
| update | Two-way check between ~/.claude and GitHub — behind AND ahead/uncommitted — plus plugin versions and vendored-skill drift; applies or rolls back. | Not sure if you should update | Rollback and restore-removed-skill built in — no manual git surgery if something breaks |
| lockstep | Hook-enforced gate: blocks Edit/Write/NotebookEdit until you say go. | You want "don't code yet" to actually hold, not just get ignored a few messages later | Mechanically denied by a PreToolUse hook — not a prompt the model can talk itself past |
| checkup | One read-only wellness pass over your ~/.claude skill library — plumbing gates, doc drift and dead references, how far behind or ahead of GitHub you are, prose slop, the skill-library audit, and a memory lint; auto-fixes only the safe regenerated menus, then pauses with a plain-English summary before you pick what to fix. | You want one health check of your whole ~/.claude setup | Runs every existing check for you in one go and only touches the safe auto-generated files — nothing else changes without your OK |

## Helpers (called by other skills)

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| antislop | Check text/UI for AI-slop tells. Violations table + verdict. | Before shipping any user-facing text or README — or when output feels generic | AI writing has 25 known tell patterns. This catches them before they reach users |
| tdd | Failing test first, then make it pass. Red→green discipline. | Bug fixes, new features, anywhere tests matter | The RED test is proof you actually fixed it. Without it you're asserting, not proving |

## Flags & arguments

| Skill | Arguments & flags |
| --- | --- |
| antislop | `[text, code, or output to check]` |
| better-prompt | `[rough prompt text to sharpen]` |
| build | `[describe the feature to build]` |
| checkup | `(no arguments — one full read-only pass)` |
| debate | `<topic or decision> [--ui]` |
| design | `[text \| URL \| screenshot \| domain context] [--apply-spec <file>]` |
| design-audit | `[surface to audit]` |
| diagnose | `[describe the bug or paste the error] [--debate]` |
| eli5 | `[skill name, plan text, command, or file path]` |
| health | `[path] [--auto] [--quick]` |
| ingest-docs | `[--force] [filename]` |
| last-30 | `[topic / library / tool / pattern to research]` |
| lockstep | `[on\|off] (omit to toggle on)` |
| md-check | `[--fix [--auto]] [--drift] [--orphans] [--pre <proposed-filename>] (omit for read-only audit)` |
| my-skills | `[deep]` |
| plan | `[describe the feature, system, or decision to plan]` |
| quick-mockup | `[what to lay out] [--variants N]` |
| release | `[env: dev\|staging\|prod] [optional commit message] [--auto]` |
| remember-that | `<fact> \| d <id> \| m <id> \| audit \| compile \| (empty=extract from context)` |
| skill-audit | `[--audit] [--build-verifier <skill-name>] [--gotchas] [--research]` |
| tdd | `[describe the feature or function to implement]` |
| update | `[preview\|full\|rules\|rollback\|restore <name>\|vendor <name>\|marketplace <name>]` |
| video-to-kb | `[YouTube URL or video path]` |
| xcheck | `[artifact to cross-check — plan text, file path, or 'last plan']` |
