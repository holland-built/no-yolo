# Changelog

## 2026-07-28 — de-duplication pass across 17 skills + the MD rule chain

Prompted by Boris Cherny's YC Startup School 2026 talk (ingested to the KB the same day):
Anthropic deleted ~80% of Claude Code's system prompt for Opus 5 because most of it
corrected behavior current models get right unprompted. Audited all 31 skills and the
whole rule chain against that claim.

**Finding: the claim mostly does not apply here, and the audit said so.** 4,412 lines of
skills yielded only ~330 cuttable (7.5%), because these skills are runbooks — exact shell
commands, file paths, step ordering, gates. A newer model cannot guess that `regen.py` runs
before `catalog_lock.py --relock`. What it *did* find was repetition: the same instruction
restated 4, 5, 6 times inside one file.

| File | Lines | Cut |
|---|---|---|
| `skills/health/SKILL.md` | 265 → 250 | `## Rules` section — all 8 bullets restated inline earlier |
| `skills/fixloop/SKILL.md` | 105 → 94 | 3 "never relax" bullets repeating the goal + ladder; war story |
| `skills/diagnose/SKILL.md` | 164 → 159 | 2 sharpening bullets repeating D4 and the persona lanes; 4 pep lines |
| `skills/plan/SKILL.md` | 97 → 88 | "70%→90%" motivation block, checkpoint rationale, self-declare rule |
| `skills/md-check/SKILL.md` | 202 → 200 | Exclusion list, restart note, impeccable origin story (kept 1 of 2) |
| `skills/release/SKILL.md` | 163 → 160 | Header prose; lockstep gate stated 3× (kept the hook-toggle trap) |
| `skills/last-30/SKILL.md` | 117 → 111 | Recency rule already enforced by `tbs: "qdr:m"` + 3 more places |
| `skills/prompt-scan/SKILL.md` | 146 → 141 | "How this file works" blockquote; stale "(10 as of 2026-07)" |
| `skills/antislop/SKILL.md` | 75 → 69 | Generic "scan for the pattern, mark found" criteria |
| `skills/skill-audit/SKILL.md` | 221 → 217 | 2 anti-patterns already gated by explicit ask prompts |
| `skills/update/SKILL.md` | 250 → 248 | Header prose restating frontmatter; "do not auto-pull" |
| `skills/whats-next/SKILL.md` | 92 → 89 | Closing format rules — verbatim eli5, which the file already calls |
| `skills/ingest-docs/SKILL.md` | 109 → 105 | "Content rules" block re-checked by Step 5b |
| `skills/watch/SKILL.md` | 111 → 108 | 3 anti-patterns restating the phases above them |
| `skills/remember-that/SKILL.md` | 161 → 160 | "Never skip confirm" — enforced inline at all 3 write paths |
| `skills/checkup/SKILL.md` | 67 → 65 | Graceful-degrade rules already required by Step 9 |
| `skills/xcheck/SKILL.md` | 68 → 66 | "Claude authors, Codex critiques" — stated operationally below |
| `CLAUDE.md` | 62 → 60 | "Review this file weekly" — aimed at the human, not actionable in a turn |
| `docs/CONTEXT.md` | 34 → 32 | Paragraph explaining context windows to the model |
| `docs/CODE_REVIEW.md` | 26 → 21 | Re-derived CORE_RULES 2 and 3 → pointer |
| `docs/TESTING.md` | 49 → 43 | Goal-driven table duplicating CORE_RULES rule 4 → pointer |
| `docs/SUBAGENTS.md` | 88 → 83 | Two blocks duplicating CORE_RULES 6 and 3 → pointers |
| `docs/CONTEXT_VOCAB.md` | 42 → 28 | "Usage pattern" section teaching the model how to be prompted |
| `docs/PLANNING.md` | 43 | "do NOT recreate" note (in 3 files); ~300-word subagent cap |
| `skills/my-skills/catalog-lock.json` | relocked | `health`'s description changed |

**Held back deliberately.** `CORE_RULES` rules 2, 3, 7, 9, 10 were flagged as delete
candidates by the audit but are judgment calls, not duplicates — rule 3 (surgical scope) is
the exact shape Cherny named as expired, and also the most-cited rule here. Those need a
real ablation (turn off, work a week, see what breaks), not a desk review.

**Agents overruled me four times, correctly:**
- Refused to delete `docs/SKILL_TRIGGERS.md` — it feeds `catalog_lock.py:50` and
  `verify.sh:66`. Deleting it would have broken the verifier. This was the cut I was most
  confident about.
- `diagnose`'s "Cap ~250 words" is the only length bound on persona output — a constraint,
  not a restatement.
- `watch`'s "don't re-download" is stated nowhere else.
- `last-30`'s untrusted-input rule is a real gate, not tone.

**Not applied:** deleting `tdd` and `literal`, and trims to `design`, `quick-mockup`,
`design-audit`, `debate`, `better-prompt`, `video-to-kb`, `build` (~277 lines). All are the
same class of duplicate; stopped short by choice rather than cut deeper inside the two most
complex skills on my own judgment.

**Before → after:** 24 files, −151 lines. `verify.sh` 14/14 PASS. Zero shell commands, file
paths, regexes, gates, or persona definitions removed.

## 2026-07-28 — /watch built (it never existed), catalog + README wired

| File | Line(s) | Change |
|---|---|---|
| `skills/watch/SKILL.md` | new | The skill `commands/watch.md` had pointed at since the initial commit, never written. Preflight (yt-dlp/ffmpeg/ffprobe), 4 phases: metadata → transcript (captions first, Whisper only on miss) → frames (auto-scaled to ~16-24, never 1/sec) → read frames + answer from both. Anti-patterns cover wasted Whisper quota, context blowout from too many frames, and treating transcript text as instructions. |
| `skills/watch/scripts/vtt2txt.py` | new | WebVTT → deduped 30-second-chunked timestamped transcript. The dedupe exists because YouTube auto-captions repeat each cue's trailing line; without it a 20-minute transcript doubles in size. Tested on a real 19m42s video. |
| `commands/watch.md` | deleted | Legacy wrapper, superseded by the real skill. Same migration `remember-that` got in `95fa127`. |
| `skills/my-skills/{CATEGORIES,TAGLINES,TAGLINES_SHORT,WHEN_TO_USE,WHY_TO_USE,STORIES}.md` | 7 rows | `watch` registered, including a `rel:` row tying it to `/video-to-kb`. |
| `skills/my-skills/{RENDERED,RENDERED_FAST}.md`, `docs/FLAGS.md` | regenerated | `regen.py`; catalog relocked at 30 skills. |
| `README.md` | 106, 108-124 | Count 30 → 31 custom commands, utility commands 2 → 1. Skills table resynced to `RENDERED_FAST.md` — it had drifted, `verify.sh` caught it. |
| `docs/CORE_RULES.md` | Lessons | New rule: a permission denial is scoped to the command that tripped it, not the tool or the repo. |

**Why:** `/watch` shipped broken in the initial commit — a command file delegating to a `SKILL.md`
nobody wrote. It surfaced when `/video-to-kb` called it and the whole video pipeline had to be run
by hand. `/video-to-kb` names `/watch` as its Phase 1, so the KB ingest path depended on a skill
that never existed.

**Before → after:** `/watch` broken since the initial commit → working, discoverable, and its
scripts tested. `verify.sh` 14/14 PASS.

## 2026-07-27 — /design + /build variant cut 10 → 8, propagated

| File | Line(s) | Change |
|---|---|---|
| `skills/design/SKILL.md` | 179, 182, 184, 186, 206, 212, 223, 231, 251 | Step 2 cut to 6 Opus paradigm variants + 2 Codex wild (v9/v10 filenames kept so the verified Codex delimiter/split machinery is untouched). Judge/scorer see 8; combined view 5x2 → 4x2; synthesis total 12 → 10. Heading corrected from "8 Opus mockups" — only 6 are Opus. |
| `skills/build/SKILL.md` | 18, 93-97, 99, 121 | Same cut in Step 3.5 Step A. Also fixed a stale rule at :18 claiming "All planning → Opus agent" when :60 dispatches Fable. |
| `skills/design-audit/SKILL.md` | 3, 21, 75, 93, 109, 121, 131, 136 | Propagated: description (harness-injected), F3 heading, v1–v8 → v1–v6, combined view 5x2 → 4x2, scorer 10 → 8, F7 total 12 → 10. |
| `skills/my-skills/{STORIES,TAGLINES,WHY_TO_USE,WHEN_TO_USE}.md` | 8 rows | Counts corrected; dropped "Opus" from two rows — the set is mixed authorship (6 Opus + 2 Codex), so the word was wrong independent of the number. |
| `skills/my-skills/RENDERED.md` | regenerated | Rebuilt by `regen.py` from corrected sources; never hand-edited. |
| `skills/my-skills/catalog_lock.json` | relocked | Blessed `design` + `design-audit` only, after re-verifying `rel:design` against `design/SKILL.md`. |

**Why:** cutting `/design` from 10 variants to 8 saves 2 Opus agents per UI run, but the first pass
changed only `design` and `build`. It left 15 stale references across 6 files — including
`design-audit`'s harness-injected `description`, which claimed a "10-mockup fix pipeline (same as
/design)" after `/design` became 8. `verify.sh` caught it as a stale catalog lock.

**Before → after:** Opus agents per UI run 8 → 6. `verify.sh` 13/14 → **14/14 PASS**.

## 2026-07-27 — skill-audit verifier blind spot

| File | Line(s) | Change |
|---|---|---|
| `skills/skill-audit/scripts/resolve-invocations.sh` | new, 1-320 | Preflight emitting candidate script/skill invocations per SKILL.md with source line, kind, resolved path. Depth-3 cycle-safe indirection; `(cwd-assumed)` tag only when the file exists on disk; UNRESOLVED never silently dropped. Emits candidates, never verdicts. 363 raw rows → 97 after dedupe/noise filtering. |
| `skills/skill-audit/SKILL.md` | 83-100 | Phase 2: single `scripts/` column → three (own dir / invokes external / deterministic need met?) with rubric `yes`/`no`/`n-a (pure reasoning)`. Provenance separated from adequacy. |
| `skills/skill-audit/SKILL.md` | 101-120 | Phase 3: HARD RULE to run the preflight first; verifier redefined as any objective check of the promised outcome (inline/pre/post all count, two-part test); script presence alone never scores "has verifier"; unresolved → `UNKNOWN — MANUAL REVIEW`. Added `Evidence (file:line)` column. |
| `brainstorms/skill-audit-2026-07-27.md` | 44-49, 51-131, 140-158 | Phases 2-3 re-run under corrected method; Top Fixes and counts recomputed; correction note added. Phases 1 and 4 byte-identical. |

**Why:** the audit scanned only each skill's own `SKILL.md`, so verifiers living in external scripts
were invisible. It produced 4 false "no verifier" findings (`remember-that`, `checkup`, `debate`,
`plan`) and a wrong #1 recommendation. `remember-that` invokes `memory_compile.py`, which lints and
`sys.exit(2)`s on error — a blocking verifier the audit could not see.

**Before → after:** verifier gaps 5 (4 false, 1 real) → 6 (all newly verified, 0 UNKNOWN).
Component gaps: 2 of the original `scripts/` recommendations withdrawn as blind-spot artifacts.


Fresh start 2026-07-17

## 2026-07-26 — added /fixloop, resynced README skill table (entry #34)

- New skill `/fixloop`: autonomous find-prove-fix-verify-ship loop — fixes at its own recommended settings and reports once at the end instead of narrating each finding. Severity-ordered (wrong-data-as-fact and blind alerting before cosmetics). Hard-stops only on destructive, unbounded-blast-radius, blocked-upstream, or product-changing work.
- README's Skills inventory table had drifted from `skills/my-skills/RENDERED_FAST.md` (missing fixloop's row position) — resynced verbatim, custom-command count bumped 29 → 30.

## 2026-07-26 — filled in the missing third-party attribution rows (entry #33)

- `docs/THIRD_PARTY_SKILLS.md` was missing 5 rows: `impeccable`, `computer-use`, `orca-cli`, `orchestration` (all four managed by the Orca app, not npx) and `interface-design` (`Dammyjay93/interface-design`, no attribution shipped in its local files — flagged for a follow-up patch). All 5 verified present on disk under `~/.agents/skills/`.
- Live-tested the new `/design-audit` Motion lens (from entry #32) against a real Wayfinder surface (`QuestionChip.tsx`, `InterviewRailView.tsx`, `QuestionRow.tsx`) — confirmed it fires on real motion code and returns real file:line findings instead of padding. No production changes made; Wayfinder is a separate repo.

## 2026-07-26 — full emilkowalski pack installed and auto-wired, no manual skills (entry #32)

- Installed the four skills from `emilkowalski/skills` that were being skipped: `apple-design` (Apple's fluid-motion principles for the web — springs, velocity, momentum, interruptible transitions), `find-animation-opportunities`, `improve-animations`, and `pick-ui-library`. Only 3 of the pack's 7 were previously installed; nothing had excluded the rest, they simply were never added.
- **Fixed a silent bug:** `/design-audit`'s Taste lens instructed itself to invoke `review-animations`, but that skill sets `disable-model-invocation: true`. Verified by test — the Skill tool refuses it outright ("Skill review-animations cannot be used with Skill tool due to disable-model-invocation"), so that call had been failing quietly. Replaced with the read-the-file grounding pattern.
- Wired every new skill into a pipeline so none of them need typing by hand: `/design-audit` gains a conditional **Motion lens** (6th, fires only when the surface has real animation/transition/gesture code) grounded by READING apple-design + review-animations, and a new **F7.5 Motion roadmap** step that invokes `improve-animations` when that lens finds anything. `/design` gains conditional apple-design grounding for motion surfaces, a post-verify `find-animation-opportunities` pass at step 6.5, and a pick-ui-library reference for non-prefab library questions (charts, state, virtualization) where its component-primitive rows stay overridden by the existing sourcing gate. `/debate --ui` grounds its panel in apple-design when the surface involves gesture or transition behaviour.
- All seven emilkowalski skills moved under `## Helpers (called by other skills)` in the catalog, so they stay out of the `/my-skills` fast menu while still appearing labelled in `/my-skills deep` — verified 0 leaks into the fast menu, 4 present in deep.
- Corrected a stale path in two places in `/debate`: emil-design-eng lives at `.agents/skills/`, not `skills/`, since the newer installer changed location.
- The general rule this established: a skill marked `disable-model-invocation: true` can never be invoked by a pipeline, but its `SKILL.md` can be READ as grounding — recorded in `docs/THIRD_PARTY_SKILLS.md` so the next wiring attempt doesn't repeat the failed-invoke pattern.

## 2026-07-26 — abandoned the trim fork, now tracking DietrichGebert/ponytail (entry #31)

- **Dropped the `holland-built/trim` fork.** It was a fork of `DietrichGebert/ponytail` whose only change was a rename (ponytail→trim across 6 skill dirs, frontmatter, the `// ponytail:` comment convention, the env var, and the debt file). It had drifted **96 commits behind upstream** while sitting 1 commit ahead, so every improvement since 2026-06-23 was being missed and each upstream pull would have meant redoing the rename. Uninstalled it and installed `DietrichGebert/ponytail` directly.
- Renamed every reference across the library: `trim*` → `ponytail*` in `README.md`, `setup.sh`, `docs/SKILLS.md`, `docs/CORE_RULES.md`, `docs/SKILL_RECOMMENDATIONS.md`, `docs/THIRD_PARTY_SKILLS.md`, `skills-lock.json`, and the skill bodies that call it (`health` — the biggest, ~14 references including its H0/H2 phase names and dependency checks — plus `build`, `design`, `skill-audit`, `md-check`) and all five my-skills catalog files. English-verb uses of "trim" were deliberately left alone.
- Removed the six dead `skills/trim*` lines from `.gitignore` rather than renaming them: the current installer puts ponytail in `.agents/skills/` and `.claude/skills/`, both already ignored, so a `skills/ponytail*` entry would itself have been the stale reference that SHIP.md step 3.4 exists to catch.
- Attribution note added to `docs/THIRD_PARTY_SKILLS.md` recording that the fork existed and why it was abandoned — the fork's LICENSE did correctly retain Dietrich Gebert's copyright, but nothing in this repo recorded the provenance.
- Behaviour change worth knowing: upstream's current description reads "Use on ANY coding task" — noticeably more ambient than the stale fork, which only fired on explicit phrases like "be lazy". Verified no `ponytail:`/`trim:` debt markers, `TRIM_DEFAULT_MODE` env var, or `TRIM-DEBT.md` ledger existed anywhere, so nothing needed migrating.
- Audited every other third-party skill for the same mistake: **trim was the only one.** improve, emil-design-eng, animation-vocabulary, review-animations, archify, and taste-skill all point at their original authors' repos.

## 2026-07-26 — diagnose sharpening parity + stale gitignore purge (entry #30)

- `/diagnose --debate` now carries the same sharpening posture as `/debate`: an anchor-or-forfeit rule (every theory cites a `file:line` from the excerpt bundle or a repro path, or it's discounted and cannot win the diagnosis), lead-with-your-lane guidance so the six failure-class personas don't converge, and a required "what would kill my theory" line. D4 gained explicit ADMITTED/DISCOUNTED rulings plus a collapse check — six personas agreeing off one anchor counts as one theory, not six.
- Removed the orphaned `skills/learned/` line from `.gitignore` — it referenced a skill that has not existed on disk since it was added (2026-06-19) and had zero references anywhere else. Caught by the SHIP.md step 3.4 stale-external sweep.

## 2026-07-24 — debate persona sharpening: User Advocate seat + evidence lanes (entry #29)

- Swapped `debate`'s default-panel Product Designer seat for **The User Advocate** — argues the user's outcome/job-to-be-done instead of pixels, so it bites on code and product calls (the Product Designer's screen lens stays on the `--ui` panel where it belongs).
- Added a **sharpening contract** binding every persona on both panels: cite a specific fact (file/rule/failure) or the Chairman discounts it, judge against the project's own standards not generic taste. Validated by live-testing sharpened personas on both panels — they cited real anchors (CORE_RULES, WCAG ratios, named products) and stayed distinct.
- Added **soft evidence lanes**: each seat leads with its own evidence class (DevOps→failure modes, Prioritizer→opportunity cost, Eng Leader→capacity/debt/ownership, etc.) to fight documented persona-collapse, but may still flag cross-cutting points. The Chairman now runs an explicit collapse check — two seats citing the same evidence for the same claim get the weaker one down-weighted.
- Removed the Eng Leader ↔ Prioritizer overlap: Eng Leader's third question moved from roadmap opportunity-cost (the Prioritizer's lane) to maintainer/ownership.

## 2026-07-24 — model/effort presets + debate project-grounding (entry #28)

- Model preset changes: `build`'s plan-authoring agent now runs on Fable at high effort (was Opus), `checkup` drops from Opus to Sonnet (it orchestrates other checks, doesn't reason deeply), and the `debugger` agent moves from Sonnet to Opus (root-cause work is the one build task that needs it).
- Added `effort: low` to 12 display/fetch skills (`eli5`, `my-md`, `my-skills`, `whats-next`, `literal`, `lockstep`, `antislop`, `md-check`, `remember-that`, `last-30`, `update`, `release`) — speed win with no quality risk.
- Added `effort: high` to `plan`, `diagnose`, and `xcheck` — the deep-reasoning skills where being wrong compounds.
- `debate` now grounds both panels in a project primer built in memory from the repo's own docs (CLAUDE.md/README/docs) and discarded after the run — personas argue against your real codebase instead of generically. Deliberately not persisted to disk: a committed machine-written summary would drift, churn git, and break the library's derive-don't-store rule (decided by running `/debate` on itself).

## 2026-07-21 — skill trigger-collision cleanup + checkup read-only fix (entry #27)

- Tightened 6 skill descriptions to kill routing collisions found in an /improve audit: `design` drops "mock this up" (was stealing quick-mockup's small-ask lane), `health` drops the over-broad bare "review this", `design-audit` drops "review the design", `debate` drops "should we build this" (read as a whats-next query), `update` "what's new" → "what's new in my setup" (was colliding with last-30 trend queries), and `improve` is now anchored to /improve with an explicit hand-off note (over-engineering-only → /trim-audit, diff health → /health).
- Corrected `checkup`'s description AND its my-skills tagline from the flat "read-only wellness pass" to "read-only except safe regen" — it runs regen.py, so the old claim was inaccurate.
- Relocked the catalog to bless the 6 description edits (regen.py rebuilt RENDERED.md; catalog-lock.json updated); verify.sh all-green. Surfaced by /improve → fixed inline → /checkup caught the resulting catalog drift → relocked.

## 2026-07-21 — /quick-mockup upgrade: 5 style-matched functional variants on one page (entry #26)

- /quick-mockup went from "1-3 placeholder-only gray static variants in separate tabs" to "up to 5 style-matched, lightly-functional layout candidates on ONE combined page with an AI ★ pick" — while staying much lighter than /design (no slop-judge, no brand-seed, no 10-variant pipeline). Default is now 5 (--variants clamps 2-5).
- Style-match: a bounded CSS-token read (globals/app/index/styles.css :root + tailwind.config, excludes node_modules/dist/build/.next) so variants use the project's font, colors, and corner radius; per-token fallback, font stack always keeps a system fallback (degrades if the font needs local files), clean-neutral fallback when no tokens exist. Functional via native HTML only (real <select>/<input>/<details>, no frameworks). Labels stay generic — style not content.
- Two-pass pick: render 5 unranked + a combined all.html → screenshot with the headless-Chrome CLI (falls back to just opening the page if Chrome CLI is absent) → write a one-line rationale per variant + a ★ on one winner → reopen. After the pick it prints a one-line pointer to /build or /design mockup-match. Kept the http:// serve + auto-open + disposable hard rules.
- Fixed every now-stale description (docs/SKILLS.md, docs/UI_MOCKUPS.md x2, WHY_TO_USE, TAGLINES, TAGLINES_SHORT, STORIES) that still called it placeholder-only/gray. Built /plan → xcheck (8 findings folded) → 2 Sonnet agents → verify.sh all-green.

## 2026-07-21 — new /match-all skill: conform siblings to one golden (entry #25)

- New /match-all skill (Design bucket): point at ONE perfected UI instance and it conforms every sibling to that instance's design LANGUAGE — adapted per sibling, never a clone. Too-basic siblings get elevated to the standard; empty/missing/variable content is hidden, given a sensible fallback, or resized (never a pasted placeholder or empty box). Discovery proposes candidate siblings with a reason each (identity by import+name+role, default exclusions for node_modules/generated/third-party/intentional-variants, batch cap 8); a hard uncheck-gate + disposable before/after preview means no production file is touched until the user confirms; every changed surface is screenshotted and side-by-side compared to the golden before done.
- Reuses /design's proven machinery (headless-Chrome screenshot loop, Step 5.6 visual-diff gate, .mockups disposable convention, approved-tokens.md format, PREFAB import-grep primitive); adds the two pieces /design lacked — multi-instance sibling discovery and extract-from-one-rendered-instance-then-adapt-per-sibling. Opus coordinates/judges, Sonnet subagents make the per-sibling edits.
- Built /plan → recon of /design internals → Opus plan (self-checked, Codex F5/F7 folded from the earlier round) → 2 parallel Sonnet agents → verify.sh all-green. This closes Piece B; the challenge-posture + /literal (Piece A) shipped earlier today. Note: ~/.claude has no app, so /match-all is proven by verify + its spec, not a live UI run.

## 2026-07-21 — challenge-by-default posture + /literal off-switch (entry #24)

- CORE_RULES now makes substance-challenge the DEFAULT: on a real change/complaint/direction, AI proposes its version and waits ("here's what I'd do instead — yours or mine?") before touching anything; for visual asks the counter-proposal is a /quick-mockup. Bare permission-questions stay banned. Reconciled rules 1/3/6/7/10 with a new "Challenge posture — precedence" block so they don't fight (propose-broad-but-execute-surgical; wait on direction, state-and-continue on internal assumptions).
- New /literal skill + off-switch: a sticky mode (existence-based `.literal-active`, mirroring caveman/lockstep) that suppresses the challenge posture for a stretch — AI obeys the letter, no proposals, no mockups — until `/literal off`. A UserPromptSubmit hook (literal-mode-tracker.js) injects the suppression each turn while active, handles inline one-off safewords ("just do it", "do exactly what i say", "no ai") without writing the flag, and a cyan [LITERAL] status-bar badge shows when it's on. Wired into settings.example.json; 6 hook tests incl. a false-positive guard so ordinary uses of "literal" don't trigger it.
- Built /plan → xcheck (8 Codex findings folded) → Opus plan (self-checked) → 5 parallel Sonnet agents → 46 hook tests green + verify.sh all-green. Piece B (/match-all propagation skill) deferred to its own build — xcheck showed its sibling-discovery + per-item adaptation is genuinely new logic, not a /design wrapper.

## 2026-07-21 — new /checkup skill: one-command library health pass (entry #23)

- New `/checkup` skill (Meta bucket): one read-only wellness pass over the whole ~/.claude library. Thin wrapper — shells to existing owners (`verify.sh`, `/md-check --drift`/`--orphans`, bare `/update`, `/antislop`, `/skill-audit`, `memory_compile.py`), never re-implements a check. Auto-fixes only deterministic regen output, then pauses with one plain-English summary before you pick findings → `/plan` → approval → subagent build → `/release`. Never pushes blind. Built via /plan → xcheck (8 Codex findings folded) → Opus plan → Sonnet build.
- Caught a real repo gap while building it: a new skill's `SKILL.md` must be `git add`-ed before `catalog_lock.py --relock` (the locker reads `git ls-files`), or it ships unlocked while verify.sh stays green. Added that line to the docs/NO_YOLO.md new-skill checklist.
- Memory hygiene: backfilled honest provenance on 7 facts flagged by the memory lint (1 reformatted from a dict, 6 given a "origin not recorded, backfilled today" note — no invented history); memory recompiles WARN-free.

## 2026-07-21 — stop parroting + plain-language eli5 (entry #22)

- New behavior rule "act like AI, don't parrot": mined from 41 real sessions where the loudest, most-repeated frustration was AI echoing the literal ask and padding with invented/static values. Codified the 5-move recipe from the one turn the user praised — root-cause first, own debated ideas, real-data browser mockup, refuse to fabricate, close with one plain choice. (Global rule lives in the private fact store; compiled into CLAUDE.generated.md.)
- eli5 output overhauled — plain, short, no jargon is the constant. A simple ask or single next step is now ONE plain sentence; a small chart is used only for a list (what's done / what's left / options). Dropped the mandatory 4-column "why" table that three prior refinements never fixed. Synced every consumer: eli5 SKILL.md, whats-next SKILL.md, docs/NO_YOLO.md, and the eli5 catalog rows (STORIES/TAGLINES/TAGLINES_SHORT).
- CORE_RULES rule 10 gained two teeth: never present invented/static values as real data (labeled fixtures OK), and for UI asks show a working browser mockup by default instead of describing one — real data via /design or /build, layout-only sketch via /quick-mockup.
- quick-mockup stays placeholder-only: added an explicit redirect so "real data / working prototype" asks route to /design or /build, never into a gray-box sketch.
- Purged the stray `skills/supacode-cli/` directory for good — it was marked removed back in entry-with-archify but a local untracked copy kept lingering. Confirmed no plugin/install source or memory fact resurrects it; deleted permanently.

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
