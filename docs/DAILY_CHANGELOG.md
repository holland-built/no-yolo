# Changelog

What changed and what it means for anyone using this setup. **The reasoning lives in the commit** —
it is attached to the diff, which is where `git blame` will look for it in six months. Do not repeat
it here.

**One entry per release. 2–4 lines. Always cite the commit.** Written long once, this file grew 704
lines in a single month and a sampled entry shared 66 of its 72 distinctive words with its own commit
message. Two copies of the same paragraph is not two records, it is one record and a maintenance
cost. July 2026 and earlier are archived under `docs/changelog/`.

Shape:

```
## YYYY-MM-DD — one line a stranger understands (`abc1234`)
- What changed, in plain words.
- What it means for someone using the setup — or what it stops going wrong.
```

---

## 2026-08-02 — /antislop had been finding nothing for a day (`95e9512`)

- It read bullets under `## Writing Tells (25)`. Yesterday's trim renamed that heading to `(15)`,
  so `/health`, `/checkup`, `/md-check`, `/better-prompt` and `/release` all silently found zero
  writing tells. Now matches by prefix, and **stops rather than reporting CLEAN on an empty read**.
- `npx impeccable detect` wired into `/antislop`, `/design-audit` and `/design` — 59 mechanical
  source checks, no model call, no key, silent skip when offline. Its 376MB plugin clone deleted;
  the plugin was never installed, so `/design`'s polish redirect had always pointed at nothing.

## 2026-08-02 — removed nine plugin collections and the scaffolding one left behind (`eb14eb6`)

- Ten marketplaces, 262MB, three ever invoked. Gone: ruflo (317 skill files, 92MB), two Obsidian
  packs, karpathy-guidelines, design-and-refine and an empty duplicate superpowers. **525MB → 416MB.**
- Caveman left 9 tracked files that shipped to every stranger who cloned this. Removing them found
  `hooks/statusline.sh` calling a deleted script every prompt, and a test executing another.

## 2026-08-02 — every audit looked in one directory (`f490f92`)

- `/skill-audit` globbed `~/.claude/skills/*/` and never touched `plugins/marketplaces/`: 49 skill
  files audited, **401 ignored**, while every report said the library was healthy. New Dimension 0
  weighs each marketplace and flags any the user's own files never invoke — 262MB installed, three
  invoked.
- `/release` warned that third-party content *existed*, never that it was current, and the check
  that would have caught drift was broken until yesterday. Now warns per release, still never
  auto-pulls: `taste-skill` drives what `/design` builds.

## 2026-08-02 — the changelog stopped copying out the commit history (`580be39`)

- 43 July entries moved to `docs/changelog/2026-07.md`; this file restarts short.
- `/build` and `SHIP.md` now cap entries at 2–4 lines with a commit hash, so the long form cannot
  creep back through either writer.

## 2026-08-01 — the last two audit steps closed (`2f7dd08`)

- Merge conflicts have a skill now — the one gap with no in-house coverage. `CLAUDE.md` pointers
  became trigger-conditioned sentences after a test showed bare `topic → file` arrows made sessions
  open all thirteen sibling docs at once.
- The prepared `CLAUDE.md` replacement was not taken verbatim: it silently dropped three doc pointers
  while calling itself correctness-only. They were kept.

## 2026-08-01 — /lockstep can finally stop a delete (`fcda3a0`)

- `/lockstep` blocked file edits but not `rm -rf`, so its own weakest point was a written rule — the
  exact thing it exists to distrust. Now hook-enforced across 12 destructive patterns, 123 tests.
- Five skills gained the audit's named merge-parts, and `/video-to-kb` stopped dropping the evidence
  section from wiki pages.

## 2026-08-01 — creating a mockup folder now protects it (`401fe69`)

- `mockup-dir.sh` creates the folder AND adds `.mockups/` to that project's ignore list in one action,
  because remembering to do the second had already failed twice.
- Same script prunes folders untouched for 30+ days, wired into every release. First run cleared 13.

## 2026-08-01 — one line in /build made mockups committable (`16fd7c2`)

- `/build` wrote `mockups/` without the leading dot on one line, which no ignore rule matched. One
  shape now everywhere: `.mockups/<skill>-<slug>/`.
- The same audit found nine places still saying Sonnet writes the code, a fortnight after that changed.

## 2026-08-01 — /last-30 was guessing the numbers it printed (`850bb49`)

- Its own rule said read counts from the page; only one of five sources actually did. Star, view and
  like counts were coming from search previews.
- The Firecrawl fallback stopped being silent — it now checks Tailscale and asks, rather than quietly
  returning a thinner answer.
