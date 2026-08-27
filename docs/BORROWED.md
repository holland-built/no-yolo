# Borrowed

Everything in this setup that somebody else wrote. One row per item, and the row carries
enough to answer the only question that matters: **has the author changed it since we took
it?**

The owner named that as their real fear, in their own words: "the author updated something
and I miss it." A markdown repository publishes no version numbers and no release feed, so
"has it changed" cannot be answered by asking for a version. It is answered by taking a
content hash at the moment of vendoring and comparing it later. That is why every row has a
hash, and why a row without one is worse than no row.

## Vendored into this repo

Copied in, tracked here, redistributed under the upstream licence. A fresh clone gets these.

| Name | Upstream | Pinned | Path | Licence | Taken |
|---|---|---|---|---|---|
| Brand specifications | `github.com/VoltAgent/awesome-design-md` | `8147538b4226ae41e2487a9179e3bcc1f68e8554` | `refs/brands/` | MIT | 2026-08-25 |
| StyleSeed, retired | `github.com/bitjaru/styleseed` | `a2bea1d09d8ad6e2b66ca5215edbc9dfb7325b84` | `archive/styleseed/` | MIT | 2026-08-20 |

StyleSeed is listed although it is retired, and the row is deliberate. It sits in `archive/`
rather than `skills/`, so nothing loads it, but it is tracked and therefore restorable from a
fresh clone rather than from one laptop. Its own `PROVENANCE.txt` carried the upstream and the
pinned revision, which is the only reason this row could be filled in honestly. Every skill
that arrived without one is in the unwatched table below.

**The snapshot is the pin, not the machine, and on 2026-08-25 the two had drifted.** The
archive was described as taken before a delete; the delete did not happen, so the installed
copies went on updating past it. `diff -rq` against `~/.agents/skills` found two files changed:
`ss-resolve/references/catalog.json` carried a later `engineRevision`, and
`ss-score/scripts/evidence-gate.mjs` had moved from comparing `import.meta.url` against a
hand-built `file://` string to resolving it through `fileURLToPath`. Neither is in the archive,
because the archive is honest about being the pinned revision and nothing else. The newer
copies were moved to `~/.agents-retired-2026-08-25/` rather than deleted, and they are outside
the repo: a fresh clone restores the pin, not them.

Content hash of the 74 `DESIGN.md` files, in sorted path order:

```
bc05dd45dab14cccca8c9c2194e19aa77ee647f24fefb47e2562b226c6108a78
```

Recompute it with:

```bash
find refs/brands -name 'DESIGN.md' -type f | sort | xargs shasum -a 256 | shasum -a 256
```

A different result means the upstream moved and this file was not updated, or somebody edited
a vendored specification in place. Both are worth stopping for. These files are third-party
text stored verbatim: they are excluded from vale, dupe-check and external-check in
`verify.sh`, and they are deliberately still covered by the secret and infra scans.

## Adapted into this repo's own documents

Neither vendored nor installed. **No upstream file is on disk here.** These are ideas read
out of somebody else's skill and rewritten into this repo's own prose, in this repo's own
voice, sitting inside a document this repo maintains. One row per adapted item, because nine
items came from four projects and a per-project row would hide which of them moved.

Read on 2026-08-26. Nothing was installed, and nothing was executed: every verdict came from
reading the instruction text. `.reports/2026-08-26-kit-skills-read.md` carries what was read
and why six other candidates were refused.

| Item taken | Upstream file | Pinned | Landed in | Licence | Quoted or adapted |
|---|---|---|---|---|---|
| Exposure gate, six purposes, duration budgets, required refusal list | `emilkowalski/skills/skills/find-animation-opportunities/SKILL.md` | `d23d7f88` | Motion | MIT | Adapted. Tier names and the exposure denominator are ours |
| The three converged combinations, with `#F4F1EA` | `anthropics/skills/skills/frontend-design/SKILL.md` | `3b3fad96` | The tells | Apache-2.0 | Adapted. The hex code is quoted |
| The brief outranks the tells | same file | `3b3fad96` | The tells | Apache-2.0 | Adapted |
| One signature element, cut one thing | same file | `3b3fad96` | Spend the boldness in one place | Apache-2.0 | Adapted. The "record that nothing was cut" branch is ours |
| Interface copy as design material | same file | `3b3fad96` | The words on the screen | Apache-2.0 | Adapted. The verb-object framing is ours; upstream said active voice |
| Notation follows the project's tokens | `jakubkrehel/skills/skills/better-colors/SKILL.md` | `ca483852` | Colour | MIT | One sentence quoted, marked as a quotation |
| One filled action per decision | same file | `ca483852` | Colour | MIT | Adapted, and narrowed to decision surfaces |
| Read the minus side of the diff | `jakubkrehel/skills/skills/interface-review/SKILL.md` | `ca483852` | Reviewing a change to a screen | MIT | Adapted, one principle of eight |
| Core Web Vitals, field against lab, Lighthouse 13, the MCP limits | `addyosmani/web-quality-skills/skills/web-quality-audit/SKILL.md` | `afa8da94` | Speed, and what a local run can claim | MIT | Adapted. The field-versus-lab split and the INP refusal are ours |
| WCAG 2.2 additions | `addyosmani/web-quality-skills/skills/accessibility/SKILL.md` | `afa8da94` | Accessibility | MIT | Adapted. Criterion numbers and thresholds are W3C's, not theirs |
| Competing actions, form fields, attributable testimonials | `autonnel/autonnel-skills/landing-page-conversion-audit/SKILL.md` | `1a326bf2` | Does it argue? | Apache-2.0 | Adapted. Its funnel-product recommendation was left behind |

**Has the author changed it since we took it?** The pin answers it for these rows, because no
bytes were copied and a content hash of our own prose would measure our editing rather than
theirs. Compare a pin against the upstream default branch:

```bash
gh api repos/<owner>/<repo>/commits/HEAD --jq .sha
```

A different value means the upstream moved. That is a prompt to re-read the file, not a
defect: an adapted idea does not go stale the way a copied file does.

**Two of the eleven carry a caveat worth keeping.** The `anthropics/skills` repository has no
licence at its root; each skill directory carries its own `LICENSE.txt`, and the one covering
`frontend-design` is Apache-2.0, read on 2026-08-26. And `autonnel/autonnel-skills` had zero
stars on the day it was read, while the kit that recommended it printed "25.9K installs"
beside it. Its checks were still sound. Its closing recommendation of the author's own product
was not taken.

## Installed alongside, not in this repo

Skills that live under `skills/` on this machine but are excluded by `.gitignore` lines 110
to 123. A fresh clone gets none of them. They are listed here so that a person setting this
up knows what is missing and where to get it.

Seven skills sit under `skills/` on this machine and are excluded by `.gitignore`. A fresh
clone gets none of them, and **none of them is watched**, so an upstream change passes
unnoticed. One row each, with what to do about it:

| Skill | Comes from | Watched | To fix it |
|---|---|---|---|
| `avoid-ai-writing` | `github.com/conorbronsdon/avoid-ai-writing` | No | Run the procedure below. The source is known, so this one is quick |
| `writing-for-agents` | `github.com/mattpocock/skills` | No | Same. `docs/WRITING.md` already names it as the source |
| `codebase-design` | `github.com/mattpocock/skills` | No | Same |
| `domain-modeling` | `github.com/mattpocock/skills` | No | Same |
| `systematic-debugging` | `github.com/mattpocock/skills` | No | Same |
| `orca-cli` | The Orca app, which the owner codes in | Not applicable | Nothing. It arrives and updates with Orca, so a content hash here would report drift every time the app updated itself |
| `mcp-builder` | Still not recorded anywhere | No | Nothing, by the owner's decision on 2026-08-25. Reopen it by saying "start watching mcp-builder", which will ask for the source first |

### The procedure, for one skill

Say to Claude: **"start watching `<name>`"**. It runs these four steps and shows you the row.

1. Find the skill on disk (`skills/<name>`, usually a shortcut into `.agents/skills/`).
2. Read the current upstream commit: `git ls-remote https://github.com/<owner>/<repo> HEAD`.
3. Hash what is on disk:
   ```bash
   find skills/<name> -type f | sort | xargs shasum -a 256 | shasum -a 256
   ```
4. Add a row to the watched table at the top of this file with both values and today's date.

**Confirm it worked.** Delete `.upstream/last-run`, start a new session, and the check runs
again. The name should appear in the watched table above and nowhere in the table on this
page. If it is still here, step 4 did not happen.

Five of the seven are waiting on that procedure and nothing else. The other two were settled on
2026-08-25 by asking the owner, and they were settled two different ways: `orca-cli` has a
source and needs no watch, while `mcp-builder` still has no recorded source and the owner chose
not to pursue one.

Neither row guesses, and the difference between them is deliberate. A row with a guess in it is
worse than an empty one: it would report "unchanged" against the wrong project forever.
