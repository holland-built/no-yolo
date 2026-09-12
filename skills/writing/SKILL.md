---
name: writing
description: Write or edit a file that an AI reads as instructions - a SKILL.md, CLAUDE.md, an output style, or a memory file. Use when creating or changing any of those, or when the user says the instructions are not working.
---

# writing

## The one thing that has changed

Most instruction files on the internet were written for models that under-delivered, and the
habits that fixed those models now make current ones worse. Anthropic's own guidance says
prompts written for prior models are often too prescriptive and reduce output quality. So the
default shape is **constraints and a definition of done**, not a numbered procedure.

## The constraints

**No numbered steps for judgment work.** A step list narrows the model to the author's version
of the job, and the model's own plan is usually better. Keep numbered steps only where order is
genuinely load-bearing — a destructive command, an auth flow, a sequence where doing two before
one breaks something.

**Normal volume.** No `CRITICAL`, no shouted `MUST` or `NEVER`. Current models are highly
responsive to instructions, so emphasis over-applies and an anxious file produces an anxious,
hedging model. Say the constraint plainly and say why it exists.

**Describe success, not a list of failures.** A run of prohibitions anchors toward the very
failure it names. Keep a prohibition when the failure it prevents has actually happened here —
and write the incident beside it, so the next person can tell whether it still applies.

**Give the reason with every rule.** On any real task there are dozens of small unstated
decisions, and the reason is what lets the model make them the way the user would. A rule with
no "because" is a rule that gets applied in the wrong place.

**Say when to stop.** These models expand scope on their own, and the fix is an explicit
definition of done, not more instructions. Every instruction file ends with what finished
looks like, in terms that can be checked.

**Never ask for the reasoning to be shown.** On Fable 5.1 that reads as an attempt to extract
the chain of thought and can return an outright refusal — a real API error, not a style issue.

**Frontmatter is routing, and routing is allowed to be keen.** The `description` decides
whether the skill is reached for at all, and skills under-trigger more often than they
over-trigger. Name the situations plainly, including the words the user actually uses.

**Match the house style.** Everything the user reads is governed by `~/.claude/output-styles/plain.md`
— everyday words, short sentences, say who does what. An instruction file that ignores it
teaches the model to ignore it.

## Before changing an existing file

Ask what each line is doing before cutting it, and sort it into one of two piles. **Context
stays** — the audience, the environment, the quality bar, tool mechanics, and the reason
behind any rule, because only the user knows those. **Behaviour goes** when the model would do
it unprompted anyway. Length is not the test, and when a line could plausibly sit in either
pile, it stays.

A prohibition stays when the failure it prevents still happens here. Delete it only when you
can say what changed.

When a cut is contested, `/claude-api prompt-audit` is the careful version of this — it reads
the file against Anthropic's own dated-pattern list and hands back a report and a proposed diff
without applying anything.

## Done

Done is a file where the reasons are attached to the rules, nothing restates a trained default,
and the last section says how the work will be judged.
