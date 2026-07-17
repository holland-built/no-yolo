# Skill Triggers
<!-- Imported by CLAUDE.md via @docs/SKILL_TRIGGERS.md. Keep this file TINY. -->

**Routing rule.** When the user types a skill's `/command`, or says something matching the
trigger phrases in that skill's `description`, invoke the Skill tool with that `skill:` before
doing anything else.

Do NOT add a per-skill trigger block here. The harness already injects every skill's
`description` frontmatter into context, so a block here is the same text loaded twice
(27 blocks once cost ~2.4k tokens/session while 14 block-less skills routed fine).
**A new skill's triggers go in its own `description`, phrased as
"Use this skill when the user types /x, says 'y' or 'z'."**

# skill-discovery
When the user says "find skill for X", "what skill handles X", "which skill does X", or "what
should I use for X", read `~/.claude/skills/my-skills/TAGLINES.md`, match X against the
taglines, and return the single best-matching skill plus its trigger command. This is a routing
rule, not a skill — do not invoke the Skill tool for it.
