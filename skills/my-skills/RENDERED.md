## Design

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| design | Fresh UI generation: 10 Opus mockups (8 paradigms + 2 wild) → AI picks → you confirm → build. | Starting a new design or full redesign — want truly fresh, not an incremental patch | 10 mockups at once (8 distinct paradigms + 2 wild) + slop validator kills the generic — one pick becomes a full build plan |
| quick-mockup | Fast throwaway HTML layout mockup — gray boxes, served live, browser-opens. Not /design. | — | — |

## Build

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| build | Full feature pipeline: plan → UI → code → tests → proof. | Starting any non-trivial feature from scratch | Nothing ships without a plan, tests, and proof. No more "works on my machine" done claims |
| plan | One-question-at-a-time interview that forces hard decisions before any code. | Fuzzy feature or system idea, before running /build | First-try success goes from ~70% to ~90% when the hard calls are made up front, not mid-build |

## Review

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| review | Unified diff review + codebase health. Bugs, bloat, secrets, slop — one command. | Before merging any non-trivial change, or when a codebase needs a cleanup pass | Replaces two separate commands with one routed pass — secret scan and antislop are automatic, not a separate step you remember to run |

## Research

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| last-30 | Trending now (last 30 days) from GitHub, HN, YouTube, X. | Starting research on a topic and want signal from the past month, not all-time rankings | GitHub stars and HN posts from 3 years ago are noise. Last 30 days is actual traction |
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
| prompt-scan | Reads global Claude MD files + current model's release notes, writes a dated snapshot to learnings.md. | Once on setup, and again whenever a new Claude model ships | Keeps /better_prompt's reference material from going stale |
| better-prompt | Rewrites a rough prompt with a named target, scope boundary, success criterion, and correct skill route. | Before running a fuzzy prompt through any skill | Shows before/after with rationale instead of guessing why a prompt underperformed |

## Diagrams

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| drawio-skill | Generates a diagram (flowchart/architecture/sequence/ER/UML) and exports PNG/SVG/PDF. | Need a picture of how something works | An hour of manual fiddling becomes two minutes |

## Memory

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| remember-that | Save, extract, delete, move, audit facts across sessions. | End of a session with useful decisions or preferences worth keeping | Preferences decay between sessions. This makes them permanent without manual file editing |

## Meta

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| my-skills | This menu. | Forgot what skills exist | You forget you have tools. This is the map |
| whats-next | Shows unfinished work or next-action list. Never static. | Session start — orient before picking what to do | Prevents starting something new while something is already half-done |
| release | The one context-aware publish command for any repo: reads the repo-root SHIP.md playbook and pushes to the right environment (dev/staging/prod). No SHIP.md yet? It stops and helps you build one before anything ships. | Ready to commit + push any repo to GitHub | One verb everywhere — each repo's SHIP.md holds its own recipe, so you never memorize per-repo commands |
| eli5 | Explains any skill, command, plan, or decision in plain English. | Before committing to something you're not sure you fully understand | Forces the "wait, do you actually get this?" check before you say yes |
| my-md | Lists every markdown file — global Claude docs plus current project's notes. | Lost track of what notes exist | One command instead of hunting across two directory trees |
| md-check | Audits ~/.claude docs for size, duplicate topics, and stale descriptions; `--fix` applies the fixes (dedupe/merge/trim/drift) behind one approve-all gate; `--pre` is a pre-creation gate. | Notes piling up or repeating themselves | Other skills call it with --pre before writing a new note, so you never get two files on one topic |
| skill-audit | Audits the whole skill library: bucket fit, missing pieces, unverified output, stale triggers. | Wondering if your skills are well-structured or missing something | One pass instead of manually eyeballing every SKILL.md |
| update | Checks if ~/.claude is behind, previews changes, applies or rolls back. | Not sure if you should update | Rollback and restore-removed-skill built in — no manual git surgery if something breaks |
| supacode-cli | Lets Claude drive the Supacode terminal app — tabs, worktrees, surfaces. | Working inside a Supacode terminal session | Auto-activates in-session; no slash command to remember |
| lockstep | Hook-enforced gate: blocks Edit/Write/NotebookEdit until you say go. | You want "don't code yet" to actually hold, not just get ignored a few messages later | Mechanically denied by a PreToolUse hook — not a prompt the model can talk itself past |
