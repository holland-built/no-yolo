# Changelog

Fresh start 2026-07-17

## 2026-07-18 — Codex beyond planning (entry #3)

- **/review Pass D**: Codex (gpt-5.6-sol) reviews the diff as a fourth parallel pass — findings adjudicated against the code, confirmed ones join the unified table tagged `[codex]`.
- **/build fix loop**: after 3 failed fix iterations, the `codex:codex-rescue` agent gets one shot before the loop surfaces to the user.
- **/build phase 4.5**: Codex writes adversarial edge-case tests from the spec + public interface (never the implementation) — breaks implementer-authored-test bias.
- **/build 3.5 + /design + /design-audit**: Codex judges the rendered mockup screenshot (`codex exec -i`) as a second slop judge with its own table column — advisory only, agreement = confidence, split = signal.
- All additions skip silently when Codex isn't installed.

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
