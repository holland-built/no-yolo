# Third-Party Skills — vendored content drift tracker

Content pulled verbatim from an external repo and vendored into this repo (not
a Claude Code plugin — plugin drift is tracked separately, see `/update`
Step 4.5). Each row is read-only-checked by `/update`: it compares "Pinned
commit" against the upstream repo's current HEAD and flags STALE if they
differ. `/update` never auto-pulls these — you re-vendor manually.

| Name | Vendor path | Upstream repo | Pinned commit | Used by |
|---|---|---|---|---|
| taste-skill | `skills/design/vendor/taste-skill/` | `Leonxlnx/taste-skill` | `b17742737e796305d829b3ad39eda3add0d79060` | `/design` Step 1 (fresh-gen dials + routing) and `/impeccable` Audit/Fix (existing-code rules) — shared rules, never the same engine run twice per request; see each skill's Scope note |

To add a new row: vendor the files under `skills/<owner-skill>/vendor/<name>/`,
write a `SOURCE.md` there with the same fields, add a row here.
