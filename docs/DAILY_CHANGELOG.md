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

## 2026-08-02 — `/route-map` v2: pages prove themselves, no more typed word lists (`5c1ebc9`)

- Your product team debated yesterday's checker and won: hand-typed "expected words" barely
  guarded anything and went red on every normal edit. Now each page's full structure is
  captured automatically and compared to a copy you approved once — approving is just
  committing a file.
- Proved on the hard case: broke a shared component while the page's own file stayed
  untouched — the page still went red, naming exactly what changed.
- Also new: your real phone/email are pinned, so a wrong digit in a call/text/email link goes
  red; dangerous link types are flagged; and the checker finally has its own tests (78).

## 2026-08-02 — one list for the network rules too, and `/eli5` says where you are (`9727bba`)

- The rules that stop your home network details leaking were still typed into two files, in two
  slightly different dialects. Now one list, one program, like the key rules this morning.
- Proved it: a real home-network address still stops a real commit, and deleting the rule list
  turns the checker red instead of quietly passing.
- `/eli5` now tells you where you are in multi-step work, gives times in real units, ends open
  work with one thing you can do in two minutes, and caps lists you must act on at five.

## 2026-08-02 — new `/route-map`: proves a page shows the right thing (`2b0af0e`)

- Everything you had only proved a page loaded. This opens every page in a real browser and
  checks the words on it against an expectation you reviewed once, kept in the app itself.
- It finds the pages by reading the app, every run — so a new page nobody wrote an expectation
  for, a leftover expectation for a page you deleted, and anything it cannot prove all go red.
- Proved it works by breaking one page on purpose: exactly that page went red, the other four
  stayed green, and the file was put back untouched.

## 2026-08-02 — new `/dep-audit`: five checks on your packages, one table (`8f9ab01`)

- Leaked keys, known-vulnerable packages, licences, what you actually depend on, and a short
  Next.js safety checklist — merged into one list sorted worst-first. Installs nothing.
- It prints what it did *not* check every single time, so a clean result is never mistaken
  for full coverage. It is not a replacement for a real container scanner and says so.
- Two things only running it could find: it was reporting 20 fake problems here (all test
  files), and in a folder with no `package.json` npm quietly scans the folder *above* and
  blames this one. Both fixed.

## 2026-08-02 — the key-detection rules stopped existing in three places (`0ee2710`)

- The same ~29 rules were typed into three files, kept in step only by a comment in each
  saying "remember to update the others". They had already drifted apart once. Now there is
  one list and one program that reads it, and all three callers call that program.
- It refuses to run rather than run blind: no list, an empty list, a broken rule, or fewer
  than 25 rules stops the commit and turns the checker red instead of reporting clean.
- A second model reviewed the plan and found five real ways the old code could say "clean"
  when it had actually scanned nothing. All five are fixed and each now has a test.

## 2026-08-02 — the commit blocker could not tell a working rule from a blind one (`c8dfcc1`)

- It only caught keys sitting next to a giveaway word — "secret" or "api key" with an equals
  sign after it. A real token pasted into a doc sailed straight through, because a real token
  carries no such word. It now knows ~20 vendor key formats by sight.
- Nothing tested that: the credential rules had no proof they still worked, and the copy of the
  hook your commits actually run was three days stale, so a planted GitHub token committed
  cleanly while every check stayed green. Both gaps now have a test that goes red.
- Release dates are now read from git instead of typed from memory — four entries had the wrong
  day, which put the file out of order.

## 2026-08-01 — answers come back as tables, and hooks stop being invisible (`97d73c9`)

- The plain-language hook told Claude "one thing to say → one sentence, cut past ~10 lines",
  which pushed answers back into scattered prose and left the user typing `/eli5` to get a table
  again. Now it is table-first: two or more facts go in a table, up to 8 rows, ~20 lines. Say
  "as a table" or "reprint that" and `/eli5` re-emits the previous answer in table form.
- `/my-md` now lists every hook and what it does, flagging any with no write-up — which found
  four running silently. `/release` hard-blocks on an undocumented hook so it cannot drift again.

## 2026-08-01 — /antislop had been finding nothing for a day (`95e9512`)

- It read bullets under `## Writing Tells (25)`. Yesterday's trim renamed that heading to `(15)`,
  so `/health`, `/checkup`, `/md-check`, `/better-prompt` and `/release` all silently found zero
  writing tells. Now matches by prefix, and **stops rather than reporting CLEAN on an empty read**.
- `npx impeccable detect` wired into `/antislop`, `/design-audit` and `/design` — 59 mechanical
  source checks, no model call, no key, silent skip when offline. Its 376MB plugin clone deleted;
  the plugin was never installed, so `/design`'s polish redirect had always pointed at nothing.

## 2026-08-01 — removed nine plugin collections and the scaffolding one left behind (`eb14eb6`)

- Ten marketplaces, 262MB, three ever invoked. Gone: ruflo (317 skill files, 92MB), two Obsidian
  packs, karpathy-guidelines, design-and-refine and an empty duplicate superpowers. **525MB → 416MB.**
- Caveman left 9 tracked files that shipped to every stranger who cloned this. Removing them found
  `hooks/statusline.sh` calling a deleted script every prompt, and a test executing another.

## 2026-08-01 — every audit looked in one directory (`f490f92`)

- `/skill-audit` globbed `~/.claude/skills/*/` and never touched `plugins/marketplaces/`: 49 skill
  files audited, **401 ignored**, while every report said the library was healthy. New Dimension 0
  weighs each marketplace and flags any the user's own files never invoke — 262MB installed, three
  invoked.
- `/release` warned that third-party content *existed*, never that it was current, and the check
  that would have caught drift was broken until yesterday. Now warns per release, still never
  auto-pulls: `taste-skill` drives what `/design` builds.

## 2026-08-01 — the changelog stopped copying out the commit history (`580be39`)

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
