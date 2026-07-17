# Changelog

Fresh start 2026-07-17 — the repo was overhauled end to end and this log restarts at entry #1. Older history lives in git.

## 2026-07-17 — v1: full overhaul (entry #1)

- **Diagrams**: drawio-skill and its draw.io/Graphviz install burden removed; [archify](https://github.com/tt-a1i/archify) (zero-dep HTML+SVG diagrams, installed by setup.sh) replaces it. supacode-cli removed (unused).
- **Menu**: `/my-skills` fast view now lists only commands you run; helper skills (antislop, tdd — called by /review and /build) sit in a labeled Helpers tier in the deep view. A completeness check makes hidden-skill bugs impossible.
- **Docs**: all rule and reference docs rewritten plainer and shorter with meaning frozen; README rebuilt for a day-one engineer — 3-command install and one Add-ons table.
- **Skills**: the six largest skills trimmed ~25% (design 506→269 lines) with behavior, triggers, and every check preserved byte-for-byte where it counts.
- **Safety**: CI now scans tracked files for private-network/infra values; the pre-commit deny-list caught and scrubbed a private company name; git history rewritten to remove a LAN IP and stray personal data.
- **Prompting**: learnings.md gains §7 per-model prompt rules (fable/opus/sonnet/haiku); /prompt-scan updates only the running model's subsection and /better-prompt applies the rules for whatever model the session runs on.
