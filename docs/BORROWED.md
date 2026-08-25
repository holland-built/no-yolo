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
| `mcp-builder` | Not recorded anywhere | No | Ask Claude "where did mcp-builder come from" before anything else. A row cannot be written without it |
| `orca-cli` | Installed by hand, source not recorded | No | Same as above |

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

Two of the seven cannot be done at all until somebody remembers where they came from, and
that is written above rather than left blank. A row with a guess in it is worse than an empty
one: it would report "unchanged" against the wrong project forever.
