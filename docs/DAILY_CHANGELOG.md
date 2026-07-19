# Changelog

Fresh start 2026-07-17

## 2026-07-19 — debate rebuilt around real usage (entry #11)

- Default panel retuned: Sales Engineer → The Alternative (steelmans the competing approach), Sales Leader → The Prioritizer (value vs effort, no revenue framing) — matches actual usage (approach validation + feature triage, never revenue).
- New Step 4.5: one bounded Codex blind-spot call after the contradiction map, Chairman-adjudicated; final xcheck unchanged (Codex advises, never vetoes).
- --ui panel: +The Benchmark (best-in-class comparison), The Prioritizer joins as 7th on ranking asks; grounding now loads emil-design-eng, ANTISLOP GUI, UI_MOCKUPS, dataviz.
- Every debate now ends by naming the installed tool that executes the outcome.

## 2026-07-19 — caveman lite persists + build skill trimmed + judge live-tested (entry #10)

- Caveman level reverting root-caused: SessionStart hook rewrites the flag with hardcoded 'full'; fixed via ~/.config/caveman/config.json {"defaultMode": "lite"} (user config, survives plugin updates).
- skills/build/SKILL.md trimmed 232 → 200 lines: summary/variant tables defined not enumerated, judge prose compressed, memory checkpoint shortened — zero behavioral change, all headings intact.
- /design's Codex screenshot-judge path live-tested through codex-run.sh -i: Codex correctly read a generated test image.

## 2026-07-19 — hard scan-delegation rule (entry #9)

- New global rule (memory fact + docs/CONTEXT.md): ≥5 read-only lookups for one question must go to cavecrew-investigator (fallback Explore) — one collapsed line on screen instead of a grep waterfall, raw output stays out of session context. Exceptions: user watching live, sequential lookups, skills with their own agents.

## 2026-07-19 — right-sized skill models + tighter eli5 format (entry #8)

- Model right-sizing: lockstep→haiku; release, update, last-30, video-to-kb, ingest-docs, prompt-scan, quick-mockup→sonnet. Judgment skills (build, design, plan, xcheck, …) stay on the default model.
- eli5 Mode B is now ONE 4-column table (Done/Ask | Why | Left + importance | Type this), ≤12 words/cell, ≤5 rows, fragments not sentences — the verbosity fix; /whats-next uses the same table.
- Memory fact updated + recompiled; catalog relocked.

## 2026-07-19 — /review renamed to /health (entry #7)

- The authored review skill is now `/health` — resolves the exact-name clash with Claude Code's built-in `/review` (GitHub PR review) found by the trigger-overlap audit. Same skill, same natural-language triggers ('review this', 'code health', 'run health pass'); only the typed command changed.
- All references updated: build, better-prompt, my-skills, CORE_RULES, CODE_REVIEW, THIRD_PARTY_SKILLS, README (Add-ons + inventory), catalog rows + relock, RENDERED menus regenerated.

## 2026-07-18 — audit follow-ups: verifiers, codex wiring, memory lint (entry #6)

- Shared Codex runner `codex-run.sh` gained `-i IMAGE` support; ALL inline `codex exec` calls in `/build`, `/review`, `/design` now route through it (`/design-audit` reference updated) — zero inline calls remain.
- `/design` description shortened 1593 → 936 chars (no more harness truncation); all trigger phrases kept.
- Output verifiers added: `/better-prompt` (structural checks + independent antislop critic), `/ingest-docs` (per-file frontmatter/density PASS/FAIL), `/video-to-kb` (schema + wikilink resolution check).
- `memory_compile.py` now lints the full SCHEMA.md contract (enums, filename=id, dates, provenance, supersession links); new bad facts ERROR, legacy facts only WARN — compile never breaks on existing store.
- `/eli5` Mode B refined: next actions are their own table with a "Why do it / why skip it" column (user feedback).
- Trigger-overlap audit run: no unsafe collisions; `/review` name clash with built-in flagged for a future naming decision (report: brainstorms/skill-audit-2026-07-18.md, local).

## 2026-07-18 — skill-audit + Codex xcheck fixes applied (entry #5)

- `setup.sh --md-only` is now reversible: backs up `CLAUDE.md` before stripping imports; a later full setup auto-restores it (was a silent, permanent strip).
- README memory-sync section rewritten: only compiled `memory/CLAUDE.generated.md` syncs; `memory/facts/` is deliberately gitignored + pre-commit-blocked (old text told users to commit a blocked path).
- New shared Codex runner `skills/xcheck/scripts/codex-run.sh` (stdin close, git-repo skip, portable timeout, pinned-model fallback); `/xcheck` now calls it instead of inlining `codex exec`.
- `argument-hint` added to `/update` (7 subcommands) and `/debate` (topic + `--ui`).
- `/ingest-docs` description: dropped redundant trailing trigger.
- README: fallow documented (Add-ons + uninstall), `verify.sh` surfaced as install check, python3 prereq row, Codex row lists all direct + transitive consumers, Playwright MCP link fixed, `pnpm dlx` → `npx`, Linux note, inventory-table clarification, caveman plugin requirement, rule-5 substitution note, interface-design/design-refine MCP rows, npx re-run caveat.
- Full audit report (2 Codex rounds, 13 findings accepted): `brainstorms/skill-audit-2026-07-18.md`.

## 2026-07-18 — eli5 table format everywhere (entry #4)

- `/eli5` — output is now always a table; new Mode B for finished work with fixed rows: What just got done / Where we are / What I'm asking you / Next actions (with exact commands).
- `/whats-next` — suggestions and status now render as plain-English tables with a "Type this" column.
- `/build` — end-of-run summary shows the eli5 Mode B table first, technical table after.
- Memory fact `feedback-eli5-on-output` broadened: every completed-work summary, next-actions list, and question to the user uses the eli5 table; `CLAUDE.generated.md` recompiled.
- my-skills catalog rows (TAGLINES, TAGLINES_SHORT, STORIES) + README inventory table resynced; catalog relocked; RENDERED menus regenerated.

## 2026-07-18 — Codex beyond planning (entry #3)

- **/review Pass D**: Codex (gpt-5.6-sol) reviews the diff as a fourth parallel pass — findings adjudicated against the code, confirmed ones join the unified table tagged `[codex]`.
- **/build fix loop**: after 3 failed fix iterations, the `codex:codex-rescue` agent gets one shot before the loop surfaces to the user.
- **/build phase 4.5**: Codex writes adversarial edge-case tests from the spec + public interface (never the implementation) — breaks implementer-authored-test bias.
- **/build 3.5 + /design + /design-audit**: Codex judges the rendered mockup screenshot (`codex exec -i`) as a second slop judge with its own table column — advisory only, agreement = confidence, split = signal.
- All additions skip silently when Codex isn't installed.
- **Synthesis round on judge splits**: when Claude's scorer and the Codex judge pick different winners, two crossover variants generate — v11 (Claude's paradigm + Codex pick's best named elements) and v12 (the mirror, Codex-led). Crossover only, never layout-averaging; skipped entirely when the judges converge; a failed synthesis slot drops silently. In /design, /build 3.5, /design-audit F6.
- **Codex authors the WILD mockup slots (v9–v10)** in /design, /build 3.5, and /design-audit F3 — cross-model generation breaks single-model taste DNA at the source. Codex stays read-only (returns HTML on stdout, Claude validates and writes the files); background launch = zero wall-clock cost; Opus regenerates any failed slot. Cross-grading rule: neither model's judge counts for its own variants.

## 2026-07-18 — Codex cross-model critique (entry #2)

- **New skill `/xcheck`**: sends a plan/diagnosis to OpenAI Codex for critique; Codex returns findings only (never rewrites), Claude accepts/rejects each with a reason and patches the artifact. Converges when a round adds no new accepted blocking/major findings; hard cap 2 rounds. Skips silently when Codex isn't installed.
- **Wired into 5 skills**: `/plan` (after the "yes" gate), `/debate` (new Step 6.5 before the verdict), `/build` (new phase 2.5 before the approval gate), `/diagnose --debate` (new Step D4.5 — Codex can add a rival theory), `/design-audit` (second verifier on Criticals).
- **Codex plugin documented**: README Add-ons row + setup.sh recommended-plugins line for `openai/codex-plugin-cc` (plugin itself stays local per third-party convention). — the repo was overhauled end to end and this log restarts at entry #1. Older history lives in git.

## 2026-07-17 — v1: full overhaul (entry #1)

- **Diagrams**: drawio-skill and its draw.io/Graphviz install burden removed; [archify](https://github.com/tt-a1i/archify) (zero-dep HTML+SVG diagrams, installed by setup.sh) replaces it. supacode-cli removed (unused).
- **Menu**: `/my-skills` fast view now lists only commands you run; helper skills (antislop, tdd — called by /review and /build) sit in a labeled Helpers tier in the deep view. A completeness check makes hidden-skill bugs impossible.
- **Docs**: all rule and reference docs rewritten plainer and shorter with meaning frozen; README rebuilt for a day-one engineer — 3-command install and one Add-ons table.
- **Skills**: the six largest skills trimmed ~25% (design 506→269 lines) with behavior, triggers, and every check preserved byte-for-byte where it counts.
- **Safety**: CI now scans tracked files for private-network/infra values; the pre-commit deny-list caught and scrubbed a private company name; git history rewritten to remove a LAN IP and stray personal data.
- **Prompting**: learnings.md gains §7 per-model prompt rules (fable/opus/sonnet/haiku); /prompt-scan updates only the running model's subsection and /better-prompt applies the rules for whatever model the session runs on.
