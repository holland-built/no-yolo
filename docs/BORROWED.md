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

| Name | Where it came from | In this repo |
|---|---|---|
| `avoid-ai-writing`, `writing-for-agents`, `codebase-design`, `domain-modeling`, `mcp-builder`, `systematic-debugging` | `npx skills` installs, landing in `.agents/skills/` | No |
| `orca-cli` | installed by hand into `~/.agents/skills` | No |
| StyleSeed: `styleseed` and 22 `ss-*` | installed by hand, with an engine payload at `.agents/styleseed-engine` | No |

Rows without a pinned version or a hash cannot be watched yet. Filling them in is the
remaining half of this file, and until it is done, an upstream change to any of them will
pass unnoticed. Saying so here is better than an empty table that implies coverage.
