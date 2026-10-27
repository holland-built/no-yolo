---
name: skill-audit
description: Audit every skill Claude Code and Codex can load and recommend what to keep, merge, park or delete, as one report page, changing nothing. Use when the user says skill audit, clean up my skills, which skills do I use, too many skills, prune skills, or after installing a batch of skills or plugins. Also worth suggesting every few months.
---

# skill-audit

Every skill's name and description sits in every session's context, so each unused or
overlapping skill is another chance for Claude to load the wrong one. This audit finds which
skills earn that place. The method is Mark Kashef's
(https://www.youtube.com/watch?v=2IPR6F3cQ_I), plus checks the video's prompt leaves out.

The audit changes no skill, setting, note or plugin, because the user decides from the report
and a wrong delete costs them a skill they relied on. Its only outputs are a scratch JSON file
and a private report page. Changes happen afterwards, only the ones the user picks.

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

## The report

One page, published with the Artifact tool, private. Lead with the actions: what to delete,
merge, park and fix, each with its reason. Then the top 10 skills by use, a heat map of uses by
date for every skill, and the full table. The heat map is what shows the install-and-forget
skills at a glance. Keep the CLAUDE.md trim list in its own section, because that is a different
file and a different decision.

In chat, give the counts per verdict and the link.

## Done

The report is published, every skill and dead link has a verdict with a reason grounded in its
use count and the checks above, and no skill, setting, note or plugin has changed.
