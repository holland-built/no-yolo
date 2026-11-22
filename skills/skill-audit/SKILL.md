---
name: skill-audit
description: "Use when the user says skill audit, clean up my skills, which skills do I use, too many skills, prune skills, or after installing a batch of skills or plugins; suggest it monthly. Installs waiting skill and plugin updates, retests them, then reports what to keep, merge, park or delete across Claude Code and Codex."
---

# skill-audit

Every skill's name and description sits in every session's context, so each unused or
overlapping skill is another chance for Claude to load the wrong one. This audit finds which
skills earn that place. The method is Mark Kashef's
(https://www.youtube.com/watch?v=2IPR6F3cQ_I), plus checks the video's prompt leaves out.

Running this skill is the user's yes to install every waiting update, so install them without
asking, because the user has said a second question defeats the point of running it. Merging,
parking, deleting and turning off stay recommendations in the report until the user picks them,
because a wrong delete costs them a skill they relied on.

It covers skills installed for the whole machine. Skills inside a single project's
`.claude/skills` folder are out of scope; say so in the report.

## The facts come from the script

```bash
# list every loadable skill and count its real uses from Claude and Codex session logs
python3 ~/.claude/skills/skill-audit/skill_usage.py > "$TMPDIR/skill-usage.json"
```

It reads `~/.claude/skills`, `~/.agents/skills` (shared with Codex), `~/.codex/skills`, and the
skills of every plugin switched on in `settings.json`. Uses come from the Skill tool and typed
`/commands` in `~/.claude/projects` and `~/.claude-work/projects`, and from Codex opening a
`SKILL.md` in `~/.codex/sessions`. A skill with uses is in use, whatever its description
suggests. Do not override the count with a guess, because guessing is how a heavily used skill
ends up on a delete list.

The counts are observed uses, not all uses. They miss a skill Claude read as a plain file, and
they go back only as far as the logs do. So zero uses alone never earns a delete: the skill also
has to fail the three questions and have nothing depending on it.

## How to judge each skill

Kashef's three questions decide whether a skill earns its place:

1. Does it run the same code every time? (Its scripts are listed in the JSON.)
2. Does it know something Claude cannot know or look up: the user's own rules, voice, clients?
3. Has a connector, MCP server or built-in feature made it obsolete? Check the MCP servers in
   `~/.claude.json` and the enabled plugins before answering.

A skill that passes none of them and is rarely used is a delete candidate. Then check what
Kashef's prompt leaves out, because each of these has caught a wrong call here:

- **Who depends on it.** Search the other skills, `CLAUDE.md`, `shared/AGENTS.md`, hooks and
  scripts for the skill's name. A skill another skill calls is not dead, however rarely it is
  typed.
- **Overlap with memory and CLAUDE.md.** Read the memory notes under
  `~/.claude/projects/*/memory/` and `CLAUDE.md`. A personal rule should live in one place. Say
  which copy to keep.
- **Overlap between skills.** Two skills that cover the same job make results depend on which
  one loads. Read both before calling it overlap. A rule that splits the work between them
  (one for slides, one for interactive pages) means they are not duplicates.
- **Dead links.** The JSON's `broken_links` are skill folders pointing at files that no longer
  exist. Report where each points.
- **Plugin skills.** They cannot be removed one by one. The choice is the whole plugin on or off,
  so judge them per plugin.
- **CLAUDE.md lines that restate what the model already does.** List them as trim candidates
  with the reason. Kashef reports that cutting most instructions made models work better.

The verdicts are keep, merge (name the skill it merges into), park (useful but seasonal: move to
a folder Claude does not load at start-up and read it on request), delete, or fix (a dead link
or a stale reference). Give each one a single-sentence reason the user can check.

## Are the third-party skills current

Skills copied from other people's repos stay frozen on the day they were copied unless something
updates them, and the user will not remember which ones those are. Each has one way to update:

| Skills | Check | Update |
|---|---|---|
| Everything in `~/.agents/.skill-lock.json` (`better-*`, `frontend-design`, `archify`, `humanizer`, `find-skills`, `ui-demo`, `web-design-guidelines`) | the lock's `updatedAt` dates, and the upstream repo's last commit | `npx -y skills update -g -y` |
| `diagram-design` | upstream `cathrynlavery/diagram-design` against the commit named at the top of its `SKILL.md` | by hand only: it carries a local house skin that an update would overwrite, so merge the upstream changes into it and keep the skin |
| `retro` | upstream `mattpocock/skills` `skills/engineering/retro/SKILL.md` against the version named at the top of its `SKILL.md` | by hand only: it carries two local edits (named in its header comment), so merge the upstream changes into it, keep those edits, and update the version in the comment |
| `grill-lite` | upstream `mattpocock/skills` `skills/productivity/grilling/SKILL.md` against the date named at the top of its `SKILL.md` | by hand only: it is a rewrite, not a copy, so carry over only upstream ideas that fit it and update the date in the comment |
| Plugin skills | `claude plugin marketplace update` | `claude plugin update <plugin>` |
| `modern-web-guidance` (used inside `build`, `improve`, `site-design`, `fix`, and by `CLAUDE.md` for `better-*` and `frontend-design`) | `~/.claude/state/web-guidance-update.log` | nothing to do: `~/.claude/tools/update-web-guidance.py` runs every Sunday, so report only a failed or skipped week |

Save a copy of each skill before updating it, then run the updates, follow "Short descriptions"
below, and rerun `trigger_test.py`, because an updated description can change which skill loads.
If an update removes or moves part of a skill, install what it moved to. Then bring no-yolo's
`installer/sources.json` to the same versions through a pull request, so a fresh install matches.
Put an "Updates" section in the report listing what was updated and anything that failed.

## Short descriptions

Claude Code's skill list cuts long descriptions, and updates bring the long upstream ones back.
`short_descriptions.json` holds a short, trigger-first version of each updated skill's
description. After any update, run `python3 apply_descriptions.py`. It puts the short version
back where the upstream text is unchanged, and lists each skill whose upstream text is new
("upstream changed", with the new text). The startup hook prints the same list.

For each listed skill, write a new short version from the new text: trigger words first, every
trigger phrase and "not for" line kept, anything new upstream added kept, what-it-does detail
cut, under about 300 characters. The point is the latest information in fewer words, so never
reuse the old short version over new upstream text. Save and apply it with:

```bash
python3 apply_descriptions.py --set <skill> "<short text>"
```

Done when `python3 apply_descriptions.py --check` prints nothing. Report what changed. A skill with local edits never goes through an automatic
update; check `git log` for edits made after its install commit first.

## Which skill actually loads

Reading descriptions side by side shows where skills could clash; it does not show which one
Claude picks. The trigger test does. It sends each realistic prompt in `trigger_queries.json` three times to
`claude -p` inside a copy of a small fake web app, and records the first skill loaded. Run it
during an audit when skills overlap, and after any change to a description, because a new
description can pull requests away from a neighbour.

```bash
# which skill loads first for each prompt in trigger_queries.json (~3 min, 60 runs)
python3 ~/.claude/skills/skill-audit/trigger_test.py
# re-check only some prompts, by number
python3 ~/.claude/skills/skill-audit/trigger_test.py --only 3,7,9
```

A run that reads a few files and then answers without a skill is common on the tiny fake app,
so a prompt that flips between runs on unchanged wording is noise, not a finding. When the
script stops on a usage limit, its results are void; rerun after the reset. To test new
prompts, add `{"q": ..., "ok": [skills that count as right]}` entries to `trigger_queries.json`;
write them as the user would, and name a page that exists in `trigger-fixture/`, because a
prompt about a missing app makes Claude ask where it is instead of loading anything.

## The report

One page, published with the Artifact tool, private. Lead with the actions: what to delete,
merge, park and fix, each with its reason. Then the top 10 skills by use, a heat map of uses by
date for every skill, and the full table. The heat map is what shows the install-and-forget
skills at a glance. Keep the CLAUDE.md trim list in its own section, because that is a different
file and a different decision.

In chat, give the counts per verdict and the link.

## Done

The report is published, every skill and dead link has a verdict with a reason grounded in its
use count and the checks above, every waiting update is installed and retested or reported as
failed, no-yolo matches, and nothing was merged, parked or deleted without the user picking it.
