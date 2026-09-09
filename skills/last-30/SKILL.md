---
name: last-30
description: Research what actually changed in a topic over the last 30 days and write a dated research note to ~/AI/research. Use for "what's new in X", "last 30 days of X", "catch me up on X", or when checking whether a tool/model/repo has shipped anything since it was last looked at.
---

# last-30

Answer one question: **what actually changed in <topic> in the last 30 days, and does any of
it matter to me?**

Output goes to `~/AI/research/<topic-slug>-<YYYY-MM-DD>.md`, matching the existing notes
there (e.g. `orca-new-features-2026-09-05.md`).

## Rules that make this worth reading

- **Date every claim.** A finding without a date is not a finding. If you cannot date it,
  say so or drop it.
- **30 days means 30 days.** Compute the cutoff from today. Anything older belongs in a
  short "older but I had missed it" section, clearly separated — never mixed in.
- **Prefer primary sources**: changelogs, release notes, commits, docs, the vendor's own
  posts. Roundup videos and listicles inflate and repeat; use them to find leads, then
  verify at the source.
- **Verify numbers you repeat.** Star counts, benchmarks, pricing — check them, and say
  when you could not.
- **Nothing shipped is a valid answer.** Say so in one line and stop. Do not pad.

## Steps

1. **Fix the window.** `date -v-30d +%Y-%m-%d` → cutoff. State it in the note.

2. **Gather.** Use whatever is available and cheapest first:
   - `WebSearch` / `WebFetch` for changelogs, releases, blog posts
   - the firecrawl MCP for pages that need real scraping
   - `gh api` for GitHub releases and commit ranges, e.g.
     `gh api repos/<owner>/<repo>/releases --jq '.[] | select(.published_at > "<cutoff>") | "\(.published_at[:10])  \(.tag_name)  \(.name)"'`
   - the local CLI when the topic is a tool that is installed (`<tool> --help`, its
     changelog) — often more current than anything published

3. **Check the vault first.** If `~/AI/Knowledge Base` already covers the topic, read that
   page and report the *delta* against it rather than restating what is already known.

4. **Write the note.**

```markdown
# <Topic>: Last 30 Days

Window: <cutoff> to <today>. Sources: <how you looked>.

## What shipped

| Date | What | Why it matters to me |
|---|---|---|

## Worth acting on

- <specific thing, with the command or link to do it>

## Noise

- <things that looked new but were not, so future-me does not re-chase them>
```

5. **Report in chat**: the two or three items that actually matter. Not the whole table.

## Vault handoff

If a finding deserves to live in the Knowledge Base rather than a dated research note, say
so and offer it — do not write into the vault from this skill. `~/AI/research` is a scratch
log; the vault is curated.
