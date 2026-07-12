# Changelog

## 2026-07-12 (cont'd, plans 009 + 010 + 011)

- **The four wired-but-untested hooks now have unit tests** (plan 009). `lockstep-guard`, `prompt-scan-nudge`, `caveman-activate`, and `caveman-config` get `hooks/tests/*.test.js` (27 asserts total) — covering the lockstep block/allow exit codes, the nudge's dated/garbage/missing-file branches, caveman mode transitions, and `caveman-config`'s default-mode resolution + a symlink-refusal safety check. `verify.sh` (and therefore CI) runs them on every push, so a regression in a hook fails the build instead of silently shipping.
- **Deterministic, committed menu-regen script** (plan 010). `skills/my-skills/regen.py` rebuilds `RENDERED.md`/`RENDERED_FAST.md` from the pipe-delimited catalog sources and reproduces the current files byte-for-byte; `SHIP.md` step 8 now points at it instead of a vague "see ship history" note, so the release menu-rebuild is reproducible. (The larger catalog-to-single-`.tsv` collapse was deliberately NOT done — 5 other files read the individual catalog files directly, so collapsing would break them for little gain; recorded as considered-and-rejected.)
- **Third-party skill supply chain pinned** (plan 011). `skills-lock.json` is now tracked (was gitignored), `docs/THIRD_PARTY_SKILLS.md` gains rows for the 3 previously-unregistered upstreams, `setup.sh` gets the optional `emilkowalski/skills` install line, and the stale `ponytail-*` ignore block (old name, pre-`trim` rename) is dropped from `.gitignore`. The live `trim-*` ignores and `settings.json` stay ignored — verified nothing secret or vendored became newly tracked. (All three Opus-planned advisor-plans/009 + 010 + 011, Sonnet-built + reviewed.)

## 2026-07-12 (cont'd, plans 002 + 005 + 006 + 013)

- **Safer permission defaults in the published template** (plan 002). `settings.example.json` no longer auto-allows `Bash(curl:*)`, `env`, `export`, `chmod`, or `cat` — together those are a prompt-free read-a-secret-then-ship-it-out chain — and `skipAutoPermissionPrompt` now ships `false` (you get a prompt the first time a session wants one), plus `permissions.deny: ["Read(.env)"]` blocks reading `.env` by default. README security note rewritten to explain the narrowing and the sanctioned opt-back-in path (the `fewer-permission-prompts` skill scans your own usage and writes a scoped allowlist). Fitting for a repo named no-yolo.
- **`verify.sh` — one command that runs every SHIP.md gate mechanically** (plan 006). New root `verify.sh` runs 7 checks (hook unit tests, `bash -n` shell syntax, template JSON parse, no quoted-`~` in hook commands, hook paths exist, README format headings, shellcheck if present) and exits non-zero on any hard failure. New `.github/workflows/ci.yml` runs it on every push/PR. `SHIP.md` steps 6 + 9 now delegate to it, so the release gates can't silently drift from the script. (Executor also caught + fixed two real bugs while building it: a `record()` exit-status leak that double-counted results, and an over-broad `~` grep.)
- **`setup.sh --md-only` actually strips the trigger imports now** (plan 005). The lightweight install mode was supposed to drop the `@docs/SKILL_TRIGGERS.md` import from the installed `CLAUDE.md`, but the regex never matched, so triggers silently stayed. Fixed; a temp-copy test harness proves 0 trigger/memory imports remain after the strip.
- **Trimmed `drawio-skill/SKILL.md`** (plan 013). Moved the non-macOS (Windows/Linux/xvfb) export detail to a new `references/export.md` and collapsed a duplicated preset intro — SKILL.md 487 → 441 lines, every macOS instruction kept whole (content moved, never dropped). (All four Opus-planned advisor-plans/002 + 005 + 006 + 013, Sonnet-built + reviewed.)

## 2026-07-12 (cont'd, plan 007 — node shim + fail-closed lockstep)

- **The lockstep edit-blocker can no longer silently fail open** (plan 007). The four Node-based hooks pinned an absolute nvm interpreter path (`.../v24.13.0/bin/node`); the next `nvm install`/`uninstall` deletes that dir and every hook dies with exit 127 — which Claude Code treats as *non-blocking*, so the "mechanically denied" lockstep gate would **stop blocking exactly when node vanished**. New `hooks/node-shim.sh` resolves a Node interpreter dynamically (PATH, then newest nvm install); if none is found it **fails closed (exit 2) for `lockstep-guard.js`** and stays quiet (exit 0) for the cosmetic hooks. All four hook commands in both `settings.example.json` (published) and the live `settings.json` now route through the shim. New isolated bash test (3 asserts incl. the fail-closed regression) — all pass. Also fixed a subtle bug in the shim itself: the interpreter name was matched with `basename`, which *itself* needs PATH — swapped to pure-bash `${script##*/}` so fail-closed holds even under a fully stripped PATH. (Opus-planned advisor-plans/007, drift-refreshed + Sonnet-built + reviewed.)

## 2026-07-12 (cont'd, plans 004 + 008 — release scope + reflect-hook fix)

- **`/release` can now stage the code that runs on adopters' machines** (plan 004). Its stage scope was `skills/ docs/ README.md .gitignore` — so hook scripts, the installer (`setup.sh`), the config template, `SHIP.md`, and `CLAUDE.md` could be edited but never actually published. Widened to include `hooks/ setup.sh settings.example.json SHIP.md CLAUDE.md memory/bin/` (only `memory/bin/` from `memory/`, which stays a Guard). This is why the very next fix below could ship at all.
- **Fixed a Stop hook that silently did nothing and could crash** (plan 008). `hooks/reflect-claude-md-stop.sh` — the "save your decisions after a plan run" reminder — was dead: it looked for brainstorm files *newer than a counter file it had just touched microseconds earlier*, so nothing ever qualified and the reminder never fired. Swapped to a "modified today" test (`-newermt`), so it works. Also hardened the counter read against a corrupt/garbage value that would crash the hook every turn. New isolated bash test (8 asserts, temp-HOME so the real `~/.claude` is never touched) — all pass. (Both Opus-planned advisor-plans/004 + 008, Sonnet-built + reviewed.)

## 2026-07-12 (plan 023 — proactive Astryx in /design fresh-gen + /build)

- `/design`'s fresh-generation pipeline now **proactively reaches for Meta's Astryx components** — before, it only pulled one on demand ("add a chat box"); now, whenever a design calls for a rich interaction (hover-preview cards, live typeahead search, infinite/virtualized feeds, chat surfaces, rich composers, reactions, command palette, stacked toasts), it treats the finished Meta component as the default building block instead of hand-rolling a weaker one. New **`skills/design/ASTRYX_CATALOG.md`** is the 14-component awareness menu both `/design` and `/build` read each run. Because Step-2 mockups are static HTML (no React), they *mock the Meta-quality behavior*; the real component is pulled and themed at build time via the existing component-pull machinery.
- `/build` gains the same instinct — an **Astryx proactive-pull bullet** in its stack-detect step. Both wired with a hardened guard: only fire in a **React + npm/bundler project** (a `package.json` with `react` + a lockfile). A CDN/babel React page with no npm project (e.g. the <a-client-repo> MCP) or any non-React stack falls back to hand-building — never a doomed `npm install`. Reactive component-pull mode, fresh-gen pipeline, and everything else unchanged (no overlap, nothing removed). (Opus-lockstepped, Sonnet-built + reviewed; advisor-plans/023.)

## 2026-07-11 (cont'd, plan 022 — latest-stable gate)

- new **CORE_RULES.md Rule 9 (Latest-stable gate)** + wired into `/build`'s stack-detect: when scaffolding a NEW repo or adding a core dependency (runtime/framework/language/core lib), query the package registry for the current stable version and pin that — never default to the version from training data, which lags (this is how a new MCP got React 18 when 19 was current). Dynamic by design: the rule stores the *check command* per ecosystem (`npm view <pkg> version`, `pip index versions`, `cargo add`, `go list -m -versions`), never a version number, so it self-updates forever with no maintenance. Grabs latest *stable* (not alpha/beta/rc), with a compat beat — pins the highest version everything supports if the newest major isn't ready yet. (Opus-planned as advisor-plans/022.)

## 2026-07-11 (cont'd, plans 020+021 — /design component-pull mode with preview gate)

- `/design` gains a second, additive **component-pull mode** — on natural language ("put a button here", "add a chat box", "drop in a card", "add a component") it pulls a finished component from Meta's open-source Astryx design system, themes it to the current project's own colors, and places it, instead of hand-building from scratch. React-only (guarded — falls back to normal `/design` otherwise); project-agnostic (colors, package manager, and existing component lib all discovered per project — nothing hardcoded, works in any React repo); installs Astryx into the target project at runtime, so nothing is vendored into no-yolo. Fresh-generation pipeline (brand seed → 10 mockups → build) 100% unchanged. Triggers added to `docs/SKILL_TRIGGERS.md`.
- **Preview-before-place gate:** the component-pull mode now renders the themed component in an isolated throwaway preview (in a sensible context — a chatbot in a chat surface, a button in a card), screenshots it with the same headless-Chrome machinery the fresh-gen pipeline uses, shows and auto-opens it, and waits for your yes before writing anything into the real app — matching `/design`'s "nothing builds before you confirm" gate. The temp preview is always cleaned up (accepted or rejected); if no dev server is available it degrades to a described preview and still asks first. (Both Opus-planned as advisor-plans/020 + 021, built + reviewed in isolation.)

## 2026-07-11 (plan 019 — /review security layer upgrade)

- `/review` secret scan expanded from ~13 to 25 patterns — added Google `AIza`, Slack `xox*`, Stripe `sk_live`/`rk_live`, GitHub fine-grained `github_pat_` + `gho/ghu/ghs/ghr`, GitLab `glpat`, Anthropic `sk-ant`, OpenAI `sk-proj`, npm, SendGrid, JWT (`eyJ…`), and raw `PRIVATE KEY` blocks. Verified: catches real samples, no false-match on prose (over-broad guard tested)
- `/review` gains a static **Security Review Checklist** (9 OWASP vuln classes — IDOR/access-control, injection, SSRF, XXE/deserialization, XSS, CSRF, auth/JWT/session, mass assignment, business-logic/race) applied at read-time in Pass A, catching logic/auth bugs that `fallow security` misses. Zero new tools, zero cost, no API key — the free harvest from evaluating the (paid, unusable-without-key) Strix pentester. (Opus-planned advisor-plans/019, built + reviewed in an isolated worktree.)

## 2026-07-10 (plan 017 — reference-URL scraping in design skills)

- `/design` + `/design-audit`: reference-URL support — when the request names a site ("make it look like this <url>"), scrape it via the self-hosted Firecrawl (`firecrawl-py`, `formats=["html"]`) and seed/inject its real palette·type·spacing tokens instead of guessing. `/design` folds tokens into the brand seed (Step 0); `/design-audit` injects them into the F3 fix mockups alongside the P0 findings. Graceful fallback to Radix/Open-Color if the scrape fails. `/quick-mockup` intentionally excluded (placeholder-only by design). Uses the same Python path as `/ingest-docs`; no MCP restart needed. (Opus-planned as advisor-plans/017, built + verified in an isolated worktree, live scrape smoke test passed.)

## 2026-07-09 (cont'd, plan 003 — template hooks fixed)

- fixed `settings.example.json`: all 6 hook/statusLine commands used `node "~/.claude/hooks/…"` — a quoted `~` never expands in a POSIX shell, so every fresh install threw a failing hook on every session event, had no status line, and the lockstep edit-gate failed open. Now `"$HOME/.claude/hooks/…"` (expands correctly); verified all 6 exit 0
- `setup.sh`: replaced the stale "update node path" instruction (the template had no node path to update) with "ensure 'node' is on PATH for GUI-launched apps"; removed the `enabledPlugins: caveman@caveman` block that pre-enabled a plugin the base install doesn't ship (marketplace registration kept)
- `SHIP.md` Step 9 hardened: now hard-fails on any quoted-`~` hook path and matches both `$HOME/` and `~/` forms when checking hook existence — the release gate can't pass a broken-path template again (executed via /improve in an isolated worktree, reviewed, merged)

## 2026-07-09 (cont'd, README trim + prompt-scan refresh)

- README.md trimmed 410 → 194 lines (task J's <200 target restored): "Cut the noise" section now 4 lines pointing at `settings.example.json`, setup-step table dropped (script self-documents), command-table descriptions cut to one clause, directory layout collapsed — all 17 README_FORMAT.md headings and all 28 command rows kept
- `/prompt-scan` run for real on Sonnet 5: learnings.md §1-5 snapshot restamped (§4 regenerated from SKILL_TRIGGERS.md — now includes /build, /release two-way update wording), new §6 entry for 2026-07-09 (Fable 5 default set, Claude Code 2.1.200-2.1.205 deltas); nudge hook verified reading it

## 2026-07-09 (cont'd, enhancement batch)

- tests for `hooks/caveman-mode-tracker.js` — the repo's highest-churn untested file: 14 node:test cases (mode transitions, NL activation/deactivation, invalid input, flag round-trip in temp dir), all passing via `node --test 'hooks/tests/*.test.js'`; tracker got a `module.exports` block + `main()` wrapper, CLI behavior unchanged
- `/update` fork/upstream/force-push flow removed (SKILL.md sync-and-run block) — this repo IS `holland-built/no-yolo`, the fork branch served nobody; sync is pinned to `origin/main`
- plugin-listing snippet deduped: new shared `hooks/list-plugins.py` (TSV out), called by both `setup.sh` Step 5 and `/update`'s plugin-status step — one source of truth
- `SHIP.md` hardened: Step 8 now checks RENDERED taglines match TAGLINES.md verbatim (catches the drift class fixed by hand today); new Step 9 HARD BLOCK — `settings.example.json` must parse and every referenced hook script must exist (the `log-learnings-stop.sh` class of bug can't ship again)
- deleted empty orphaned `skills/learned/` dir

## 2026-07-09 (cont'd, full /review health pass — 31 fixes)

- `hooks/statusline.sh` — removed leftover debug line that dumped the full statusline stdin JSON (transcript path, cost) to `/tmp/sl-stdin-*.json` on every render
- `settings.example.json` — removed Stop-hook entry for nonexistent `log-learnings-stop.sh` (fresh installs got a failing hook every turn); fixed playwright allowlist prefix to `mcp__plugin_ecc_playwright__*` (old `mcp__playwright__*` never matched); dropped unconfigured `mcp__filesystem__*` and legacy duplicate `voiceEnabled` key
- docs de-drifted after the /ship→/release, /design-full→/design, /code-review+/code-health→/review, /plan-feature+/build-feature→/build consolidations: `SKILLS.md` Daily-Driver table rewritten, `UI_MOCKUPS.md` routes + plans-path fixed, `SUBAGENTS.md` dead agents removed, `CODE_REVIEW.md` retitled, `CONTEXT_VOCAB.md` fact-path + gateguard row fixed
- duplicate rules consolidated to single owners: "Opus plans, Sonnet codes" → `SUBAGENTS.md`; skill-authoring rules → `NO_YOLO.md`; GUI-slop fingerprint → `ANTISLOP.md` pointer; Caveman section in `CLAUDE.md` → `HOOKS.md` pointer; token-bloat rule → `CONTEXT.md`
- deleted 4 orphaned my-skills catalog files (`HOW_TO_USE.md`, `BOLT_ONS.md`, `RELATIONSHIPS.md`, empty `PLUGIN_PACKS.md`) — nothing read them and two duplicated `STORIES.md` data; md-check's orphan checker updated to stop parsing `RELATIONSHIPS.md`
- stale numbers fixed everywhere: 27 commands (was 28), 8 core rules (was 5), /design = 10 mockups 8 paradigms + 2 wild (was 7) across README, STORIES, RENDERED, WHY_TO_USE
- added missing `/quick-mockup` README row and `/build` trigger block in `SKILL_TRIGGERS.md`; deleted duplicate `better_prompt` story line and dead `rel:code-health`/`rel:code-review` lines
- dead code trimmed: 14 unused exports dropped from `caveman-stats.js`, 1 (`getConfigPath`) from `caveman-config.js` — both invoked as subprocesses, never required
- `.gitignore` now covers runtime artifacts `.claude.json`, `.claude/`, `chrome/`, `debug/`; `SHIP.md` line added to `GLOBAL_DESCRIPTIONS.md`

## 2026-07-09 (cont'd, session-tuning settings)

- added 6 settings to `settings.example.json` (the only settings file this repo commits — `settings.json` itself stays gitignored, per-machine): `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY`, `DISABLE_TELEMETRY`, `DISABLE_ERROR_REPORTING`, `DISABLE_NON_ESSENTIAL_MODEL_CALLS`, `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: "75"` (compacts before quality degrades near the 95% default limit, not after), and top-level `spinnerTipsEnabled: false`. New README section explains what each does and how to add them by hand if you already have an older `settings.json`

## 2026-07-09

- `/my-skills`' menu (`CATEGORIES.md`/`RENDERED*.md`) only listed `improve` among borrowed plugins, not `trim` — an inconsistency, not a break: fixed by adding `trim`, then removed both `trim` and `design-audit` again per explicit preference (menu should reflect what's actually typed, not every real skill) — `TAGLINES.md`'s "6-persona" debate typo (should be 7) fixed along the way, confirmed clean by `/md-check --orphans` both times since neither skill's catalog/trigger entries elsewhere were touched
- wired Paper MCP into `/design-audit`'s fix pipeline as a conditional branch (F0.5 + F3-PAPER): fires only when Paper Desktop is connected AND the target is a single component, matching Paper's own "small sections, not whole pages" guidance — builds up to 6 live variants on the canvas instead of static HTML, picks via screenshot, pulls exact values via `get_jsx`/`get_computed_styles` for the build step. Full-page fixes stay on the existing Chrome/HTML path unconditionally. `RELATIONSHIPS.md` updated to match

- `/design` was missing the reuse/simplicity gate `/build` already had — added Step 4.6: for every new component/hook/util the build introduces, grep for an existing sibling first (reuse it, don't twin it); run `/trim` on the new files if 3+ new components land or a duplicate pattern shows up. Updated `RELATIONSHIPS.md`'s dependency row to match

## 2026-07-07 (cont'd, added emilkowalski/skills)

- installed `emilkowalski/skills` (Vaul/Sonner author's animation/design-eng taste rules) via `npx skills@latest add emilkowalski/skills` — 3 skills: `emil-design-eng`, `animation-vocabulary`, `review-animations`
- caught and fixed a placement bug in the installer itself: it dropped symlinks into a nested `~/.claude/.claude/skills/` (project-scoped, only live when a session's cwd is exactly `~/.claude`) instead of this repo's own `skills/` — added the correct flat symlinks matching the existing `trim`/`improve` pattern. Left the nested `.claude/.claude/settings.local.json` alone — real accumulated permission history, not installer junk
- wired `emil-design-eng` into `/design` Step 1 (motion decisions when `MOTION_INTENSITY` is non-baseline) and `review-animations` into `/design-audit`'s Taste lens (motion surfaces only) — both skip silently if not installed
- cataloged all 3 in `TAGLINES/WHEN_TO_USE/WHY_TO_USE/STORIES/RELATIONSHIPS.md` and `.gitignore` so `/my-skills` surfaces them and `/md-check --orphans` doesn't flag them

## 2026-07-07 (cont'd, /md-check --fix)

- ran `/md-check --fix` for real: found + removed 12 dangling `lazyweb-*` entries from `TAGLINES.md`/`WHEN_TO_USE.md`/`WHY_TO_USE.md` — these are Lazyweb MCP internals, not slash commands, and never belonged in the skill catalogs
- found a bonus dangling reference while in `NO_YOLO.md`: it told people to run `/publish-skills`, a skill retired long ago and replaced by `/release` — fixed the pointer and completed the checklist (was missing the TAGLINES/WHEN_TO_USE/WHY_TO_USE steps)
- trimmed README.md's "Add a new skill" section from 36 lines to 4 — it fully duplicated `NO_YOLO.md`'s checklist, now the single source of truth (419 → 389 lines; still over the 200-line soft cap, accepted tradeoff for the primary onboarding doc)

## 2026-07-07 (cont'd)

- added `/md-check --orphans` — checks two directions: does a catalog file (TAGLINES/STORIES/WHEN_TO_USE/WHY_TO_USE/RELATIONSHIPS/SKILL_TRIGGERS) describe a skill that no longer exists (DANGLING), and does a real skill sit unreferenced anywhere a user would find it (UNREFERENCED). Wired into `SHIP.md` Step 3.5 so every `/release` runs it automatically
- ran it for real and found + fixed 6 dangling names: `code-review`/`code-health` (retired into `/review`, but 6 catalog files still described them as live) and `graphify`/`design-full`/`design-fix`/`token-hunt` (real tool or fully-retired skills wrongly documented as their own commands) — fixed across `BOLT_ONS.md`, `HOW_TO_USE.md`, `WHEN_TO_USE.md`, `TAGLINES.md`, `WHY_TO_USE.md`, `RELATIONSHIPS.md`
- fixed two bugs in the orphan-checker itself found while running it: it never parsed `RELATIONSHIPS.md`'s `| name | ...` row format, and a regex artifact matched a stray leading `-` as a fake skill name
- deleted the duplicate local `/impeccable` skill (gitignored, unbacked-up, original content) per explicit choice to use the real `pbakaus/impeccable` plugin instead — `/design`'s existing-UI redirect now points at the real plugin, documented as an install command in README rather than duplicated
- un-vendored taste-skill from git (was committed as a full copy, against this repo's own `.gitignore` convention that other people's work stays local) — gitignored the vendor dir, rewrote `THIRD_PARTY_SKILLS.md` as an install-pointer doc, `/update vendor <name>` now handles first install too
- ran `/md-check --drift` for real (previously skipped in favor of ad-hoc greps) and fixed 5 real drift findings in `SKILL_TRIGGERS.md`: `update`, `release`, `md-check`, and `design` all omitted real behavior added this session; `design-audit`'s "zero mockups" claim flatly contradicted its own SKILL.md (predates this session)

- vendored the real taste-skill (Leonxlnx/taste-skill, MIT, pinned commit) into `skills/design/vendor/taste-skill/` — `/design` now actually reads it (Design Read + 3 dials + honest design-system routing) instead of running on the FALLBACKS-only stub
- added `docs/THIRD_PARTY_SKILLS.md` — registry `/update` reads to flag drift on any vendored (non-plugin) third-party content
- `/design` now auto-redirects existing-UI polish language (`polish`, `tighten`, `existing`, `fix the design`, etc.) to `/impeccable`, invoked in the same response — never tells you to retype a command
- `/impeccable` now shares the vendored taste-skill rules with `/design` (redesign-skill.md as its primary Fix driver, taste-skill.md's anti-default checklist in Audit) while its own Scope guard always overrides the dials for documented/intentional design decisions
- `/update` gained real two-way reconciliation: it now checks AHEAD (local commits not pushed) and DIRTY (uncommitted work) in addition to BEHIND, since the old version only checked "is GitHub ahead of me" and silently missed unpublished local work
- `/update` gained two apply commands — `/update vendor <name>` (re-vendor a stale third-party skill from upstream) and `/update marketplace <name>` (git pull a stale orphaned marketplace, e.g. impeccable) — both confirm-gated, the only steps that touch third-party content
- `/update` gained a plugin/marketplace drift check for marketplaces cloned directly (no `installed_plugins.json` entry) that the old plugin-status step silently missed — caught `impeccable` stale by 124 commits, since fixed
- `/release` gained a pre-push sync check (BEHIND only) so it never pushes blind against a moved remote — defers the full picture to `/update` rather than duplicating it
- **correction (same day):** taste-skill was committed as a full copy — against this repo's own convention (`.gitignore` already excludes `plugins/`, `skills/impeccable`, etc.). Un-tracked it, added it to `.gitignore`, rewrote `THIRD_PARTY_SKILLS.md` as an install-pointer doc — `/update vendor <name>` now handles first install, not just re-fetch
- **correction (same day):** discovered two unrelated things both named "impeccable" — a hand-written local skill (gitignored, never backed up) and the real `pbakaus/impeccable` plugin. Deleted the hand-written one per your call; `/design`'s existing-UI redirect now points at the real plugin instead, documented as an install command in README (not uploaded)
- swept every catalog file (STORIES/TAGLINES/WHEN_TO_USE/WHY_TO_USE, README, design/SKILL.md) for the now-fictional "5-lens polish loop" description and the equally-stale claim that `/design-audit`'s "fix it" hands off to `/impeccable` (it never did — self-corrected)
- logged a new lesson in `CORE_RULES.md` under the (also new) Self-learning section: check `.gitignore` convention before vendoring any external repo's files

## 2026-07-05

- added a `--ui` flag to /debate — swaps the default 7 business/eng personas for a 5-persona UI/UX panel (Restraint Auditor, The Operator, Spatial Designer, Accessibility Enforcer, Diagnostician) that reads the project's own design docs first, so it argues by your rules instead of generic taste

## 2026-07-04

- merged /md-fix into /md-check as `--fix` — one skill now both audits (default) and applies fixes (`--fix`, `--auto` to skip the gate); removed the standalone /md-fix skill (md-check is the shared audit primitive other skills call)
- skill-audit fixes: reworded drawio-skill/ingest-docs/supacode-cli descriptions to lead with "Use this skill when"; added a §1–6 header self-check to /prompt-scan (guards /better_prompt); repointed a stale ship/SKILL.md reference in my-skills to SHIP.md
- removed the `/ship` alias skill and killed `/ship` as a trigger phrase entirely — `/release` is the sole publish command
- unified publishing into one command: `/release` — context-aware, reads a repo-root `SHIP.md` playbook and pushes to the right environment (dev/staging/prod); `/ship` is now an alias
- added `~/.claude/SHIP.md` (the skill repo's own release playbook) and the SHIP.md template the skill authors when a repo has none
- `/release` refuses to push a repo with no SHIP.md — it stops (lockstep) and walks you through building one first
- added /md-fix skill: the active counterpart to /md-check — audits your docs, then applies the fixes (dedupe repeated rules, merge overlapping files, trim oversize, correct stale descriptions) behind one approve-all gate; --auto skips the gate
- hardened /prompt-scan release-note fetching: swapped the redirecting docs URLs for direct 2026 endpoints so scans no longer waste retries on redirects
- restructured /prompt-scan output: conventions are now a living snapshot overwritten each scan, model facts are a dated append-only log, and the skill-trigger table is derived from SKILL_TRIGGERS.md instead of retyped
- wired /md-fix into the skill menus, README, and triggers

## 2026-07-02

- added /quick-mockup skill: fast disposable placeholder-only HTML layout mockup, served over http://, auto-opens browser; lightweight counterpart to /design
- wired /quick-mockup into SKILL_TRIGGERS.md, STORIES.md, TAGLINES.md, CATEGORIES.md, TAGLINES_SHORT.md
- rewrote /better-prompt output: now returns only the rewritten prompt in a fenced block, no before/after/why

## 2026-07-01

- un-hid 13 skills back into /my-skills: eli5, debate, code-health (later deleted), plan, my-md, md-check, skill-audit, update, prompt-scan, better-prompt, ingest-docs, drawio-skill, supacode-cli
- added /improve to /my-skills after a debate concluded bare (non-namespaced) third-party skills should be visible regardless of authorship
- deleted /code-health and /code-review entirely — fully superseded by /review, zero unique capability left
- kept /antislop and /tdd hidden but present — each retains a standalone use case its replacement doesn't cover
- decided to keep the whole third-party trim-* family off the menu — three of six are already invoked by /review and /code-health, the other three the user won't use standalone
- added /lockstep — new skill + PreToolUse hook that hard-blocks Edit/Write/NotebookEdit until the user explicitly releases it
- updated /plan: final output now routes through /better_prompt before dispatching the recommended skill, instead of always assuming /build
- added a SessionStart hook that nudges /prompt-scan when the current model differs from the last recorded scan
- added worktree cleanup to /build and /design-audit — merges and removes isolated agent worktrees/branches after use
- redesigned /my-skills default output: paired-column (Skill+What x2), no section headers, 2-5 word summaries — 25 skills collapse to 13 rows, one screen
- added TAGLINES_SHORT.md as the source for the new dense default view; deep mode unchanged
- fixed stale README: removed all references to deleted/nonexistent skills (code-health, code-review, design-full, design-fix, token-hunt, quick-design), rebuilt the Skills inventory table to match what's actually installed
- synced TAGLINES.md/WHEN_TO_USE.md/WHY_TO_USE.md — lockstep was missing entirely, several other rows had drifted from the live RENDERED.md content
- fixed /review's trim-audit/trim-debt/trim-review install checks — were checking the wrong global path and always reporting "missing" even though the skills work; now resolves the actual local symlink
- added a drift guard to /ship's RENDERED.md/RENDERED_FAST.md regen — diffs against the current file before overwriting, warns if source files had drifted, still commits either way
- redesigned /review into one mode: always runs diff review AND whole-codebase health pass together, max effort always, one ranked findings list, one approve-all gate, then fixes everything approved — removed --health/--fix/--comment/--effort flags, kept --auto as an unattended override
- added Core Rule 8: self-check simplest-method + reuse before declaring any coding task done, checked during planning and again after — separate from /review, always on, unprompted
- fixed /plan's Gate: explicitly bans asking a second confirmation question after the user already says "yes" to alignment — was adding an extra unneeded prompt

## 2026-06-30

- improved /last-30 output: removed 40-word bottom line cap (now 3–4 sentences with concrete evidence), added clickable link format rules with long-URL fallback, raised output cap to 300 words
- consolidated 27 visible skills to 11: added /review (unified diff review + codebase health), hid plan/tdd/code-review/code-health/antislop/md-check/prompt-scan/better-prompt/eli5/debate/skill-audit/my-md/update/ingest-docs/drawio-skill/supacode-cli from /my-skills menu
- updated CATEGORIES.md to show exactly 11 skills in 6 sections (Design/Build/Review/Research/Quality/Memory/Meta)
- updated SKILL_TRIGGERS.md: removed code-review and code-health triggers, added /review trigger
- updated /build: /code-health references replaced with /review --health
- updated /impeccable: added adversarial verify gate for Criticals + eli5 round summary
- updated /design: added tsc/lint/build gate before Playwright smoke in main build flow
- set user-invocable: false on 16 hidden skills so they run internally but don't appear in menus
- redesigned /design: 10 mockups (8 paradigms + 2 wild), light+dark side-by-side (5 rows x 2 cols), states strip, annotation callouts, AI scoring agent picks winner, Chrome auto-opens before gate
- redesigned /design-audit: adds fix gate after audit (y/n); y triggers full 10-mockup pipeline scoped to P0 findings, you pick variant, then builds with tsc+lint+Playwright+re-audit
- absorbed /impeccable into /design-audit fix gate; set /impeccable user-invocable: false, removed from CATEGORIES.md and SKILL_TRIGGERS.md
- updated TAGLINES.md, WHEN_TO_USE.md, WHY_TO_USE.md for design and design-audit
- rebuilt RENDERED.md (10 visible skills: 2 Design / 1 Build / 1 Review / 2 Research / 1 Quality / 1 Memory / 3 Meta)

## 2026-06-28

- updated /my-skills index files — added taglines, when-to-use, and why-to-use entries for all lazyweb skills (lazyweb, lazyweb-quick-search, lazyweb-lite-design-research, lazyweb-deep-design-research, lazyweb-design-improve, lazyweb-design-brainstorm, lazyweb-design-best-practices, lazyweb-ab-test-research, lazyweb-optimize-paywall, lazyweb-optimize-sign-up, lazyweb-paywall-cta, lazyweb-update) and /skill-audit

## 2026-06-26

- added /token-hunt skill — finds 5 reference sites matching design intent, extracts CSS tokens from each, outputs stolen-tokens.md for design-full
- updated /design-full — added --steal flag that runs /token-hunt first to seed palette from a real site instead of generating one
- updated all my-skills index files — RELATIONSHIPS, WHEN_TO_USE, WHY_TO_USE, HOW_TO_USE, STORIES, TAGLINES with token-hunt entries
- updated SKILL_TRIGGERS.md — added token-hunt trigger, fixed md-check drift description, updated design-full to three modes
- updated README.md — added token-hunt row, bumped skill count to 28
- fixed MCP config — open-design server was registered in wrong ~/.claude.json (desktop app install vs CLI install); re-registered to correct ~/.claude-work/.claude.json

## 2026-06-23

- renamed /forge → /build — more obvious name for the full feature-build pipeline
- renamed /grill-me → /plan — clearer name for the pre-build planning interview
- forked DietrichGebert/ponytail → holland-built/trim — renamed all 6 sub-skills (trim, trim-audit, trim-debt, trim-gain, trim-help, trim-review), updated comment convention // ponytail: → // trim:
- updated all references across skills, docs, setup.sh, README, .gitignore to use /build, /plan, and trim
- fixed grill-me/plan SKILL.md — removed hard 8-question minimum, added eli5-style agreement gate
- fixed grill-me/plan SKILL.md — gate now references /build instead of deleted /plan-feature
- updated .gitignore — ignores both ponytail-* (currently installed) and trim-* (post-reinstall) symlinks
- updated /ship — dynamic skill count patch in README (step 3c.5), summary header + repo description update in release notes (step 4)
- restructured README — prerequisites converted to table, sections reordered (Set up a new project after Install, CLAUDE.md chain moved to bottom), broken cross-reference fixed
- rewrote README intro, What this is, Set up a new project — shorter, eli5, less jargon
- fixed README Add a new skill step 3 — wrong file (CLAUDE.md → SKILL_TRIGGERS.md)
- trimmed README fork sync, security note, directory layout, keeping up to date, update memory sections
- fixed README borrowed count: 7→8, trim count: 5→6 (was wrong in 3 places)
- replaced shadcn MCP with GitHub MCP in outside tools table and MCP examples
- improved video-to-kb descriptions: now says "Obsidian vault wiki page" not just "summary"
- updated /ship step 3c.5: now auto-patches borrowed count alongside custom count
- updated docs/README_FORMAT.md — section order updated to match restructured README
- ingested YouTube "How Anthropic Employees ACTUALLY Use Claude Skills" — raw KB file + wiki source page + topic page updated with 4-bucket taxonomy and folder structure
- rewrote description fields in 27 skills — all now lead with "Use this skill when" trigger condition
- updated docs/SKILLS.md — added 4-bucket taxonomy, folder structure, trigger condition rule, gotchas discipline sections
- updated docs/NO_YOLO.md — added trigger-condition and gotchas-grow-organically rules, fixed skill checklist (user-invocable: true, SKILL_TRIGGERS.md)
- added /skill-audit skill — 3-mode library audit: bucket/component/verifier/trigger audit, build-verifier mode, gotchas mode

## 2026-06-25

- removed impeccable from my-skills data files: TAGLINES.md, STORIES.md, WHEN_TO_USE.md, WHY_TO_USE.md
- added /design-audit skill — read-only audit: Playwright screenshot + Lazyweb deep + 5 lenses (Taste/Swiss/UIwiki/a11y/code-health) → violations table + top-10 improvements
- added /design-fast skill — 7 parallel Sonnet mockups (5 redesign + 2 wild), slop judge, Chrome screenshot, hard pick-gate, no code
- added /design-full skill — full pipeline: audit → 6-persona debate → 7 Opus mockups → token extraction → Opus plan → chains to /build, 4 hard gates
- retired /ui, /quick-design, /ui-wild — replaced by /design-audit, /design-fast, /design-full
- demoted /ui-ux to internal sub-skill (user-invocable: false) — called by design-* skills as reference lens
- updated README — rewrote frontend design section with new 3-command structure + 4 optional MCP servers
- updated SKILL_TRIGGERS.md — removed 3 old blocks, updated ui-ux to internal, added 3 new design skill triggers
- updated all my-skills data files — STORIES, TAGLINES, WHEN_TO_USE, WHY_TO_USE, HOW_TO_USE, RELATIONSHIPS, BOLT_ONS
- updated docs/UI_MOCKUPS.md — replaced tool decision tree with new design skills
- updated docs/SKILLS.md — replaced ui-wild row with 3 design skill rows
- updated skills/build/SKILL.md — routing note updated from /impeccable to /design-audit
- updated setup.sh — removed impeccable plugin hint, added 4 design pipeline MCP server hints
- removed Magic MCP from /design-full and setup.sh — required paid 21st.dev API key; Claude handles component generation natively via /build
- installed Lazyweb MCP — 12 design research skills now available (lazyweb, lazyweb-ab-test-research, lazyweb-deep-design-research, lazyweb-design-best-practices, lazyweb-design-brainstorm, lazyweb-design-improve, lazyweb-lite-design-research, lazyweb-optimize-paywall, lazyweb-optimize-sign-up, lazyweb-paywall-cta, lazyweb-quick-search, lazyweb-update)
- installed Interface Design skill pack — persists design decisions across sessions
- installed Design+Refine plugin — side-by-side variant comparison
- fixed ui-ux plugin doctor error — created .claude/skills/ui-ux-pro-max symlink to resolve missing path
- removed graphify from setup.sh and README — skill was deleted, stale references remained
- updated README design pipeline note — removed Magic MCP, added real install commands for Lazyweb, Interface Design, and Design+Refine

## 2026-06-22

- reorganized docs into docs/ subfolder — moved all .md files from root except CLAUDE.md and README.md
- updated README.md — directory layout table reflects new docs/ paths
- updated my-skills SKILL.md — $ARGUMENTS substitution, fast/deep/default modes, TAGLINES.md for short cells
- updated my-skills TAGLINES.md — trimmed all entries to ≤60 chars
- added model: haiku to 7 lightweight skills — antislop, eli5, md-check, my-md, my-skills, remember-that, whats-next
- added /ship skill — replaces publish-skills with quality-gated publish (md-check + antislop + eli5 + changelog)
- deleted 16 root MDs (now live in docs/ from prior commit)
- added memory/ safe subset to git — SCHEMA.md, CLAUDE.generated.md, bin/*.py (facts/ stays gitignored due to provenance UUIDs)
- updated .gitignore — memory/ now partially tracked; compile-manifest.json and facts/ excluded
- updated my-skills SKILL.md — pipe table output (4 columns: skill, what, when, why); removed broken wrap() + html br approach
- fixed remember-that SKILL.md description — "view" → "extract from context" (drift fix)
- added /antislop skill — AI writing/GUI slop detection against ANTISLOP.md
- added /better-prompt skill — rewrites rough prompts using learnings.md
- added /prompt-scan skill — scans system prompt files + model release notes → learnings.md
- added /plan-feature skill — no-code planning gate: evidence → grill-me → Opus plan → approval
- added /build-feature skill — reads approved plan → TDD → build → regression → prove
- added /debug-debate skill — 6 Opus personas argue bug root cause in parallel
- added /last-30 skill — pulls 30-day trending content from GitHub/HN/YouTube/X
- added /md-check skill — MD hygiene: line counts, overlap detection, pre-creation gate
- added ANTISLOP.md — 25 AI writing tells + GUI slop patterns reference file
- added CONTEXT_VOCAB.md — shared vocabulary file for token reduction
- rewrote /whats-next — session task queue first, runs next task, creative scan when empty
- rewrote README.md — trimmed from 391 to 157 lines
- updated setup.sh — added plugin awareness step (reads installed_plugins.json)
- updated /update skill — added plugin status step 4.5
- updated /forge — rewritten as thin wrapper calling /plan-feature then /build-feature
- updated /debate — parallel Opus mandatory, never inline
- updated /ui-wild — read-before-edit guard added
- updated /grill-me — added no-code gate pointing to /plan-feature
- updated /ui-ux — removed 52 lines of duplicate sections
- updated CLAUDE.md — added triggers for 10 new skills
- updated SKILLS.md — added new skill rows
- updated UI_MOCKUPS.md — cross-ref pointer to ANTISLOP.md
- updated hooks/reflect-claude-md-stop.sh — brainstorms safety net for memory reminders
- updated my-skills STORIES.md + TAGLINES.md — all new skills registered
- updated my-md GLOBAL_DESCRIPTIONS.md — ANTISLOP.md, CONTEXT_VOCAB.md, learnings.md added
- fixed CLAUDE.md — corrected stale skill descriptions for my-skills, code-review, whats-next, quick-design, ship, md-check; removed trigger collision between ui and ui-wild
- added --drift mode to md-check — LLM judge cross-checks CLAUDE.md descriptions against SKILL.md source of truth
- wired drift check into ship Phase 1d — runs on every publish as warn-only gate
- updated my-skills STORIES.md — corrected impeccable entry (design system author, not aesthetic applicator)
- updated impeccable SKILL.md — accurate description + trigger conditions moved from CLAUDE.md into skill frontmatter
- converted /remember-that from commands/ to skills/ — now shows blue, added trigger to SKILL_TRIGGERS.md
- deleted /start command — unused
- deleted build-feature and plan-feature skills — superseded by /forge
- deleted graphify skill — removed from setup
- updated my-skills STORIES.md — added remember-that story
- updated my-skills SKILL.md — 4-column table with when/why, line-wrap via fold+awk
- updated my-skills WHEN_TO_USE.md — added 10 missing skills
- updated my-skills WHY_TO_USE.md — added 10 missing skills
- added docs/README_FORMAT.md — spec file listing 15 required README section headings; /ship reads this to validate structure
- added "Skills with modes" section to README.md — table of 7 skills with flags/routes (/ui, /update, /my-skills, /md-check, /code-review, /code-health, /remember-that)
- added Phase 3c README format hard-block to /ship — commits blocked if any required README section is missing or renamed
- updated CORE_RULES.md — added rules 6 (flag uncertainty) and 7 (suggest better paths)
- updated SKILL_TRIGGERS.md — fixed 4 drift entries: code-review (added --fix/--comment/effort flags), ship (added README hard-block note), last-30 (gaining-traction vs all-time), md-check (added --pre gate)
- stripped 26 unused exports from skills/ui-ux/cli/ — fallow fix removed dead export keywords across 10 TypeScript files
- updated better-prompt SKILL.md — trigger and behavior refinements
- updated whats-next SKILL.md — creative suggestion format improvements
- updated update SKILL.md — expanded with rollback and restore-removed-skill flows
- updated ship/SKILL.md description — reflects new README format validation gate
- updated memory/CLAUDE.generated.md — compiled new eli5-on-output feedback rule
- merged "Skills with modes" section into inventory table — 3-col (Skill | What it does | Modes & flags), 7 skills get described modes, 18 get dash
- deleted standalone ## Skills with modes section from README.md
- removed ## Skills with modes from README_FORMAT.md required sections (14 remain)
- fixed README Prerequisites: Mac home path corrected to /Users/<username>, Linux /home/<username>
- added inline skill definition at first use (line 13) — "A skill is a command you run by typing /name"
- removed manual mkdir brainstorms from "Set up a new project" — skills create it automatically
- rewrote README install section: git clone alternative added, setup.sh documented step-by-step, redundant manual install block removed
- added /update fork-sync support: detects fork vs direct clone, auto-adds upstream remote, rebases AHEAD>0 commits instead of --ff-only, aborts cleanly on conflict
- added README "Keeping your fork in sync" section — fork workflow, upstream remote, rebase, force-push warning
- added "Keeping your fork in sync" to README_FORMAT.md required sections
- fixed /update AHEAD=0 fork path: now uses merge --ff-only $SYNC_REF (upstream) not origin
- fixed /update SYNC_REF: variable now set inside bash block (was prose-only — would have been empty at rebase time)
- added learnings.md (created by /prompt-scan): model delta, skill triggers, slop patterns, output conventions
- added staleness check to /better_prompt: warns if learnings.md >90 days old
- fixed /whats-next Step 3: checks git status + unpushed commits before creative suggestions
- added README Uninstall section — per-tool removal commands + rm -rf ~/.claude with backup note
- added Uninstall to README_FORMAT.md required sections
- fixed setup.sh --md-only exit message: correct re-run command (was wrong "re-clone" instruction)
- added README re-run hint after setup table: --md-only users can upgrade to full install anytime
- fixed /whats-next output: "looks interesting" → "I found"
- added Phase 1e to /ship — GLOBAL_DESCRIPTIONS coverage check warns on any ~/.claude/*.md or docs/*.md missing an entry
- updated my-md GLOBAL_DESCRIPTIONS.md — added 6 missing entries: DAILY_CHANGELOG.md, README_FORMAT.md, SKILL_TRIGGERS.md, MEMORY_USAGE.md, .pending-tasks.md; fixed README.md description (was "no-yolo rules", now "install guide")
- shrunk skills/ui-ux/SKILL.md from 609 to 261 lines — removed Recommended/Skip sub-blocks, replaced 236-line Quick Reference with 2-line search pointer, simplified Prerequisites, deleted Sticking Points table and Common Rules tables (all duplicated in searchable CSV data)
- created docs/MEMORY_USAGE.md — teammate onboarding guide for the memory system (7 sections: what it does, where it lives, 4 types, file format, workflow, what not to save, git rules)
- added docs/MEMORY_USAGE.md row to README.md directory table
- refactored hooks/caveman-mode-tracker.js — extracted 4 top-level functions (detectNLActivation, handleStatsCommand, parseSlashCommand, detectNLDeactivation, emitReinforcement), on('end') callback shrunk from 114 to 12 lines
- trimmed skills/update/SKILL.md from 296 to 228 lines — extracted shared dirty-check + fork/rebase block into "Shared: sync-and-run", Steps 7 and 8 now reference it with only setup command differing
- created docs/HOOKS_INTERNALS.md — developer reference for 4 caveman hook modules (caveman-config, caveman-activate, caveman-mode-tracker, caveman-stats): hook event, what it does, exports, security notes
- updated my-md GLOBAL_DESCRIPTIONS.md — added HOOKS_INTERNALS.md entry
- updated docs/SKILLS.md — added Skill Taxonomy (4 buckets: utility/verification/data-enrichment/orchestration) and Skill Folder Structure sections
- updated docs/NO_YOLO.md — fixed new-skill checklist (trigger line now in SKILL_TRIGGERS.md not CLAUDE.md), added description-as-trigger-condition rule and gotchas-grow-organically rule
- added .agents/ and skills-lock.json to .gitignore — npm artifacts from skills@latest install
- wired trim-* symlinks into ~/.claude/skills/ — trim, trim-audit, trim-debt, trim-gain, trim-help, trim-review now show in /my-skills plugin section
- removed GitHub MCP from Outside Tools table (no skill uses gh MCP — skills use gh CLI directly)
- removed Environment variables section from README — GROQ_API_KEY already in video-to-kb row
- rewrote README security note — describes actual risks (curl/docker/kill wildcards + skipDangerousModePermissionPrompt)
- fixed settings.example.json — skipDangerousModePermissionPrompt changed true→false (safe default for public example)
- removed github from MCP example in Set up a new project — only playwright is commonly needed
- added design pipeline subsection to Skills inventory — explains /ui-ux → /quick-design → /impeccable → /build chain
- updated /build skills table row — clarifies automatic 10-variant mockup gate before any code is written
- fixed 3 drift entries in SKILL_TRIGGERS.md: code-health Fallow description, ui-wild removed false claims, update description matches rollback/restore
- updated update/SKILL.md description — mentions rollback and restore-removed-skill
- fixed impeccable descriptions in README (pipeline table + inventory row) — clarifies it's a specific branded aesthetic, not a generic style layer
- updated design pipeline section — /build is now the hero, step-by-step table reframed as "why go deeper" with concrete reasons per command
- updated /code-health inventory row — calls out it runs trim + improve so users don't run those separately
- added / prefix to all skill names in inventory table
- fixed settings.example.json directory layout description — says setup.sh copies it automatically (was "copy manually")
- added README skill table format rule to NO_YOLO.md checklist — backtick + slash prefix required
- removed "Upstream of impeccable" from ui-ux trigger description in SKILL_TRIGGERS.md
- simplified install: removed gh clone option, git clone only — gh stays in Prerequisites with "/ship" scope note
- added one-line gh explanation before clone command (then removed as redundant once options collapsed)
- removed /impeccable skill entirely — symlink deleted, all README references removed, SKILL_TRIGGERS.md cleared, ui/SKILL.md menu updated to 3 options
- wired /build mockup gate to read design-system/MASTER.md (written by /ui-ux --persist) — constrains 10 variants to your design system; falls back to CSS tokens
- updated README frontend design section: renamed heading, added intro paragraph, pipeline table shows real handoff per command
- updated /quick-design inventory row — explains conservative/modern/wild + Sonnet/cheap vs ui-wild
- updated /ui-wild inventory row — explains 10 Opus personas, when to use over quick-design
- updated /ui SKILL.md — removed impeccable route, menu now 3 options, wild variant description updated

- consolidated design pipeline: merged /design-fast into /design-full as --fast flag; /design-full now has two modes
- consolidated bug diagnosis: merged /debug-debate into /diagnose as --debate flag; six Opus personas debate competing theories
- deleted /ui-ux skill (duplicate of externally-managed ui-ux-pro-max); removed all references from registries
- updated all skill registry files (TAGLINES, WHEN_TO_USE, WHY_TO_USE, HOW_TO_USE, STORIES, RELATIONSHIPS, BOLT_ONS) to reflect consolidations
- updated SKILL_TRIGGERS.md — removed triggers for deleted skills, merged modes into parent trigger blocks
- updated README.md frontend design section: two-skill table with mode documentation
- updated docs (SKILLS.md, UI_MOCKUPS.md) to reference /design-full --fast instead of /design-fast
- removed shadcn MCP from BOLT_ONS.md (was only used by deleted /ui-ux)
- added /design-fix skill — surgical 7-variant mockup for one component; respects current design tokens, no build chain
- added bold redesign enforcement to /design-full — BOLD MODE activates on keywords (new, redesign, fresh, different); variants must be impossible to mistake for current design
- added light+dark mode to all /design-full and /design-audit mockups — 14-section all.html (v1-light through v7-dark) required in both fast and full mode
- design-full always nukes existing design tokens — reads tokens to build explicit ban list; palette injection gives agents fresh hex from Radix/Open Color
- removed Interface Design MCP and Design+Refine MCP from design-full and design-audit pipeline steps
- added shadcn/ui MCP to design pipeline (MIT, open source, official shadcn team)
- added auto-pickup of saved audit by project slug — design-full reads latest AUDIT-<slug>-*.md without paste
- updated RELATIONSHIPS.md — removed stale Interface Design/Design+Refine references from design-audit and design-full rows
- updated SKILL_TRIGGERS.md — added design-fix trigger block
