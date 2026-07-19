# Changelog

Fresh start 2026-07-17

## 2026-07-19 — /health dogfood run: 15 findings fixed (entry #21)

- Full /health pass on today's 44-file diff (6 parallel workers + Codex second reviewer). Fixed: unknown setup.sh flags now rejected (typo can't trigger a full install), git made fatal (secret-scanner can't be silently skipped), md-only restore can't clobber a newer CLAUDE.md, core-only needs node only, wrong trim repo in health skill hint, stale /review references, dead scan-exclude entry, bash-4 guard extended to the whole construct class, memory compiler hardened (fresh-machine manifest, inline YAML lists, project-tier facts, deduped helper), regen.py flags table computed once, fallow hints pinned, INSTALL.md drift-proofed, README bullet redundancy merged.
- Clean: secrets, fallow dupes/security, surgical filter. Informational: vendored caveman hook complexity, radar gap — measure our own session-preamble token cost (community hot topic).

## 2026-07-19 — stranger install test: bash 3.2 bug found + fixed (entry #20)

- Sandboxed end-to-end install test (fake HOME, real clone): preflight, --core-only skips, --md-only backup/restore, fail-loud gate, all verify rows — PASS.
- REAL DEFECT caught: setup.sh used a bash-4-only associative array; stock macOS ships bash 3.2, so the documented `bash setup.sh` failed on any un-provisioned Mac. Rewritten bash-3.2-clean and proven by running the install under /bin/bash 3.2.57.
- New verify.sh guard "setup.sh bash-3.2 clean" (grep + /bin/bash -n) so a bash-4 construct can never ship again.
- /prompt-scan refreshed learnings.md for claude-fable-5 (local file).

## 2026-07-19 — generated flags table in /my-skills deep (entry #19)

- docs/FLAGS.md: standalone generated flags page in the repo, linked from the README — same no-drift guarantee (regen --check covers all 3 generated files).
- regen.py now builds a "Flags & arguments" table into RENDERED.md from every skill's argument-hint frontmatter — machine-generated, alphabetical, covered by regen --check + verify.sh so it can never drift. First central place all skill flags are documented.

## 2026-07-19 — --core-only install + codex-aware preflight (entry #18)

- setup.sh gains `--core-only`: skips every third-party install (fallow + the four npx skill packs), records them as SKIPPED (not FAILED), exits 0; plain setup.sh later adds them.
- Preflight now detects Codex and says plainly whether cross-model checks are active or will skip themselves — informational, never an error.
- README + INSTALL.md: "No Codex? No problem" caveat and minimal-install guidance.

## 2026-07-19 — README opener v3: plain-words bullet list (entry #17)

- Working-method pitch replaced after user verdict ("AI garbage"): now a 2-sentence summary (non-slop output, self-checking repo, current research) + 9 plain bullets. Metaphor language ("design wing wakes up") banned and gone; all 10 user-approved lines shipped.

## 2026-07-19 — README opener: the full pitch (entry #16)

- "Any stack" beat added: method is stack-agnostic, the web-deep design wing only wakes on UI changes.
- Opener replaced with the "working method" pitch: trust-earning framing + When you build / decide / design / publish / All the time sections — the full breadth (orchestration, routing, dual-AI checks, anti-slop, token frugality), user-picked from 5 drafted styles. Standalone Why sentence absorbed into the pitch.

## 2026-07-19 — README opener rewritten as capability→outcome bullets (entry #15)

- Second debate on the opener ruled the 6-clause capability sentence a NO: it promised optional add-ons a day-1 install lacks and named counts/vendors that drift. Shipped form: bold one-liner + 3 bullets, each "capability — so you stop X"; Why sentence un-bolded so one thing is loud; all optional-feature detail stays below the fold.

## 2026-07-19 — README why-sentence (debate verdict) (entry #14)

- One bolded Why sentence added after the What: names the out-of-the-box gaps (no memory, edits-before-asking, generic drift) and the mechanisms this repo wires in. Debate ruled one sentence over a Why section (rots) or before/after strip (over-promises, pushes install below fold).

## 2026-07-19 — beginner install path (audience: beginners) (entry #13)

- New INSTALL.md: agent-guided install — beginners paste "walk me through installing this — read ~/.claude/INSTALL.md" into Claude Code; Claude checks their machine, runs setup.sh, narrates every step in plain English, never skips a failure.
- README first screen rewritten beginner-first: plain one-sentence pitch, "New to this?" pointer to the guided install, 4-row glossary (skill/plugin/MCP/hook) after the You're-done divider.
- SHIP.md stage scope + GLOBAL_DESCRIPTIONS cover the new file.

## 2026-07-19 — install stops lying (debate verdict built) (entry #12)

- setup.sh: new preflight (git/node/npm/npx/python3/claude — hard-fail on missing required tools), per-step OK/FAILED tracking, and a truthful end-of-run Install summary that exits 1 when any step failed — no more green "Done" over a half-broken install.
- README: "You're done. Everything below this line is reference" divider after the install block.
- verify.sh: new "README inventory current" check — the README skills table must be byte-identical to RENDERED_FAST.md (the drift that shipped once can't ship again).
- fallow pinned to 2.98.0 in setup.sh; emilkowalski/skills confirmed already hash-locked in skills-lock.json.

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
