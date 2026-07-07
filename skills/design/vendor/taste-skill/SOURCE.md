# Vendored source — taste-skill

Not authored here. Pulled verbatim from upstream, MIT licensed. `/update` checks
this file's pinned commit against upstream to flag drift (read-only — never
auto-updates; see `docs/THIRD_PARTY_SKILLS.md`).

| | |
|---|---|
| Upstream | https://github.com/Leonxlnx/taste-skill |
| License | MIT |
| Pinned commit | `b17742737e796305d829b3ad39eda3add0d79060` |
| Vendored | 2026-07-07 |
| Files | `taste-skill.md` (brief inference, 3 dials, honest design-system map, stack conventions), `redesign-skill.md` (6-category audit for existing projects), `image-to-code-skill.md` (screenshot → reference image → code) |
| Used by | `skills/design/SKILL.md` Step 1 and `skills/impeccable/SKILL.md` Audit/Fix — both read this dir, never the same engine run twice per request |

To re-pin after an upstream update: re-run the curl commands against
`skills/{taste-skill,redesign-skill,image-to-code-skill}/SKILL.md` on the new
commit, update the SHA above and in `docs/THIRD_PARTY_SKILLS.md`.
