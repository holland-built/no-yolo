---
name: design
description: Use when the owner wants a look for something they are building, says "make it look like X", asks how a page or app should look, or needs a visual direction picked. Narrows 74 real brand specifications to three, renders them as a page the owner points at, and never shows a list of names.
user-invocable: true
argument-hint: "<what you are building>"
allowed-tools: Read, Grep, Glob, Bash
---

# design

The owner is not a designer. They cannot judge a look from a name, and they have said so.
So this skill never asks them to choose from a list. It shows three rendered directions and
they point at one.

## The material

`refs/brands/` holds 74 brand specifications vendored from `VoltAgent/awesome-design-md` at
commit `8147538b`, MIT. Each is a `DESIGN.md` carrying that brand's real colour ramp, type
scale, spacing and radii, read off the live site.

`refs/brands/INDEX.md` is one table of all 74 with primary colour, first typeface and a line
of character. **Read the index, never the 74 files.** Opening a brand's own `DESIGN.md`
happens once, after the owner has picked it.

## Steps

**1. Learn what is being built.** One question at most, and only when the answer changes the
shortlist: who is it for, and what is the one thing a visitor should do. Do not ask about
colour, font or mood. That is the question this skill exists to answer for them.

**2. Shortlist three.** Scan `INDEX.md` and pick three that pull in genuinely different
directions. Three near-twins waste the owner's only real decision. Recommendation first.

**3. Render the page.**

```bash
python3 skills/design/scripts/render-picker.py <slug> <slug> <slug> \
  --for "<what is being built>" --headline "<real headline>" --body "<real supporting line>" \
  --out .design/pick.html
```

Use copy from the actual project, never "Lorem ipsum" and never "Acme". A card with fake
words is judged on the fake words.

**4. Say three lines and stop.** One line per brand on why it suits this job, recommendation
first and labelled. Print the path to the page. Then wait. Nothing is chosen until the owner
names one.

**5. Build from the picked spec.** Now open `refs/brands/<picked>/DESIGN.md` and take its
values verbatim: the hex codes, the type scale, the spacing, the radii. Do not improve them.

## Boundaries

These describe real companies' identities. They are a starting point the owner then moves
away from, never a finished product shipped under someone else's look. Say so once, in one
line, when a brand is picked.

Never auto-pick. A look chosen silently is the owner's taste decided for them, which is the
one thing this skill must not do.

Never print the 74 names. If none of the three lands, shortlist three different ones and
render again. Re-rendering is cheap; reading a list of 74 slugs is not something the owner
can do.
