## Design

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| design | Fresh UI generation: 10 Opus mockups (8 paradigms + 2 wild) → AI picks → you confirm → build. | Starting a new design or full redesign — want truly fresh, not an incremental patch | 7 distinct paradigms at once + slop validator kills the generic — one pick becomes a full build plan |
| design-audit | Audit UI across 5 lenses → ranked violations → optional 10-mockup fix pipeline. | Any UI that feels off — audit first, then optionally fix with 10 mockups in the same command | Five independent lenses catch what one reviewer misses — audit is read-only, fix gate keeps you in control before anything builds |

## Build

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| build | Full feature pipeline: plan → UI → code → tests → proof. | Starting any non-trivial feature from scratch | Nothing ships without a plan, tests, and proof. No more "works on my machine" done claims |

## Review

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| review | Unified diff review + codebase health. Bugs, bloat, secrets, slop — one command. | Before merging any non-trivial change, or when a codebase needs a cleanup pass | Replaces two separate commands with one routed pass — secret scan and antislop are automatic, not a separate step you remember to run |

## Research

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| last-30 | Trending now (last 30 days) from GitHub, HN, YouTube, X. | Starting research on a topic and want signal from the past month, not all-time rankings | GitHub stars and HN posts from 3 years ago are noise. Last 30 days is actual traction |
| video-to-kb | Turn a YouTube video into a searchable KB note. | Good talk or tutorial worth keeping permanently | Talks are perishable. One command turns them into permanent, searchable KB nodes |

## Quality

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| diagnose | Root-cause analysis: solo 6-phase or --debate for 6 Opus personas. | Stuck on a bug > 20 min — solo for systematic, --debate when multiple plausible theories | Solo: forces systematic evidence-gathering. --debate: six theories surface the one you missed |

## Memory

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| remember-that | Save, extract, delete, move, audit facts across sessions. | End of a session with useful decisions or preferences worth keeping | Preferences decay between sessions. This makes them permanent without manual file editing |

## Meta

| Skill | What it does | When to use | Why vs manual |
| --- | --- | --- | --- |
| my-skills | This menu. | Forgot what skills exist | You forget you have tools. This is the map |
| whats-next | Shows unfinished work or next-action list. Never static. | Session start — orient before picking what to do | Prevents starting something new while something is already half-done |
| ship | Quality-gate + changelog + publish to no-yolo. One command. | Done editing skills and ready to publish to no-yolo | Leak guard + quality gates run automatically. One command replaces 5 manual steps |

## Plugins

| Pack | What it does | Entry point | Why vs manual |
| --- | --- | --- | --- |
