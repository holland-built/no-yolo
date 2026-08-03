## Bundles — one command that runs several

| Bundle | Runs |
| --- | --- |
| `/build` | evidence → grill-me → Fable plan → `xcheck` → mockup gate (8 variants, slop judge, Codex wild slots) → TDD + Codex adversarial tests → Opus build agents → quality gates (secret scan, code-reviewer, security-auditor, accessibility-tester, `/health`) → prove → `/eli5` |
| `/health` | secret-scan.sh + `antislop` on changed .md + `/last-30` radar + `ponytail-review` / `ponytail-audit` / `ponytail-debt` + fallow (dead-code, dupes, health, security, audit) + `improve`; in ~/.claude also `md-check` + `skill-audit` |
| `/checkup` | verify.sh + `/md-check --drift` + `/md-check --orphans` + `/update` + `/antislop` + `/skill-audit` + memory lint + regen.py, then hands picked findings to `/plan` → `/release` |
| `/debate` | 7 Opus personas in parallel (6 UI personas with `--ui`) + Chairman ruling + Codex blind-spot call + `xcheck` on the briefing + eli5 summary |
| `/design` | brand seed + taste generators + 8 mockups (6 Opus, 2 Codex wild) + slop validator + Codex second judge + synthesis round when the judges split |
| `/design-audit` | 5–8 parallel lens agents + `xcheck` on every Critical + eli5, then on `y` the full `/design` 8-mockup fix pipeline + `improve-animations` |
| `/release` | reads the repo's SHIP.md and runs it; in ~/.claude that is antislop → `/md-check --drift` (catalog lock) → stale-external sweep → `/update` freshness → `/md-check --orphans` → regen → verify.sh |

Hooks are not skills — for every hook and what it fires on, run `/my-md`.
