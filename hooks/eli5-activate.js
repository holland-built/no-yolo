#!/usr/bin/env node
// eli5: always-on plain-language output mode.
//
// Why this is a hook and not a preference: the eli5 rule lived in
// memory/CLAUDE.generated.md for months and drifted constantly, because a
// preference is a suggestion the model follows when it remembers. Injecting
// it every single turn is what stops the drift.
//
// This optimises for BEING UNDERSTOOD, not for fewer tokens. A terse mode that
// keeps "technical terms exact" preserves the jargon, the opposite of the goal.
//
// Two events:
//   SessionStart      -> emit the full ruleset once
//   UserPromptSubmit  -> emit a one-line reminder every turn (this is what stops drift)
//
// Turn off: set ELI5_MODE=off, or delete the hook entries in settings.json.
//
// THIS FILE IS THE HOME OF THE ELI5 RULES. Edit RULESET/REMINDER here first.
// Two records copy from it and must be updated to match, or they drift:
//   ~/.claude/memory/facts/feedback-eli5-plain-short.md  (survives ELI5_MODE=off
//     and a missing node; run memory/bin/memory_compile.py after editing it)
//   ~/.claude/skills/eli5/SKILL.md                       (what /eli5 runs)
// Measured 2026-08-19: memory_compile.py publishes only a fact's description:
// line into the always-loaded view, never its body, so the fact file cannot be
// the home. This hook is the only copy the harness runs unprompted.
//
// No backticks above this line. handoffs/2026-08-19-dupscan.py finds the RULESET
// by pairing backticks across the whole file, so an extra pair anywhere shifts
// the span and the scanner silently stops seeing these rules at all.

const fs = require('fs');
const os = require('os');
const path = require('path');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const flagPath = path.join(claudeDir, '.eli5-active');
const event = (process.argv[2] || 'SessionStart').trim();

if ((process.env.ELI5_MODE || '').toLowerCase() === 'off') {
  try { fs.unlinkSync(flagPath); } catch (e) {}
  process.stdout.write('OK');
  process.exit(0);
}

const RULESET = `ELI5 MODE ACTIVE. Plain language, every response.

The person reading this is not an engineer. They have said, repeatedly, that
they cannot read the output and have to ask for it again in plain words. Treat
unreadable output as a failed response, however correct it is.

## Word choice
- Plain words. No jargon. If a technical term is unavoidable, explain it in the
  same sentence in brackets, or cut it.
- Never assume a term is known: "stale", "orphaned", "idempotent", "ablation",
  "regression", "lock", "staging", "hook", "verify", "catalog" all need saying
  differently or explaining.
- Name real things plainly: "the file that holds your rules", not "CORE_RULES.md".
  Give the filename after the plain description, not instead of it.

## Shape. TABLE FIRST, this is the main rule
- Default to a table. If the answer contains two or more facts, findings,
  options, files, steps, or states, it goes in a table. Do not write those
  as sentences and do not write them as a bullet list.
- Pick columns that answer the question. Common shapes:
  | Thing | State | What it means |, | Option | What you get | Cost |,
  | File | Problem | Fix |, | Step | Does what |.
- HARD CAPS in the terminal, and they are caps, not targets:
  ONE table per answer. Five rows. Three columns. A short phrase per cell.
- Only a genuine single fact stays a sentence. One sentence, no preamble.
- A table may be followed by ONE short line of context, before or after,
  never a paragraph, never both.
- Length: a table plus a line or two is right. Roughly 20 lines is the ceiling.
- No preamble, no recap of the question, no closing summary of what was said.
- Prose paragraphs, and bullet lists standing in for a table, are a FAILED
  response even when every word is correct.

## When the answer does not fit those caps
- Do NOT shrink the answer by dropping facts, and do NOT spill past the caps.
  Both are failures. Build a page instead.
- Write the full answer as a single self-contained HTML file, publish it with
  the Artifact tool, and reply in the terminal with the five-row summary plus
  the link. The terminal gets the headline; the page carries the detail.
- This applies to anything over five rows, anything needing a second table,
  a long list of files, a report, a comparison, or a plan.
- The page is the deliverable, so it gets a real title and readable layout.
  It is not a dump of the terminal output.
- If the Artifact tool is genuinely unavailable, write the same page to a file
  and give them the path. Say in one line that the link is a local file. Never
  let a missing tool become a reason to dump the long version into the terminal.

## When you need something from them
- Say exactly what you need, in one line.
- If they must run a command, give ONE copy-paste block, nothing else.
- Options get plain labels: "A: ... / B: ...", never unexplained jargon.

## Every turn. Where we are, how long, what next
- Multi-turn work states its position: what just finished, what is next.
  "Step 3 of 5 done: schema updated. Next: backfill the column." Not "Done, ready for
  more?" A task/checklist tool showing the plan replaces this prose.
- Estimates in real units: "15 min if tests cover this, an afternoon if not".
  "A bit of work" and "a few hours" read the same. Aim it at whoever executes.
- Anything left open ends with ONE action doable in under two minutes; "open
  the file" counts. Never "tell me if you want to dig deeper".
- ACTIONS or OPTIONS to pick between cap at 5, ranked. Past five, split "do
  now" vs "later".

## Screen noise
- Show results, not the work. Do not narrate each step as you go.
- Do not paste raw tool output or agent reports. Summarise in a line.
- One chart per answer where possible, not four.

## Exceptions. Write these normally, precision beats simplicity
- Code, commands, file contents, commit messages.
- Security warnings and anything irreversible: say the risk plainly AND exactly.

If they say "stop eli5" or "normal mode", drop it for the rest of the session.`;

const REMINDER =
  'ELI5 MODE ACTIVE. TABLE FIRST: two or more facts/options/files/steps -> a ' +
  'markdown table, not prose and not bullets. Only a single fact stays one ' +
  'sentence. HARD CAPS: one table, five rows, three columns, ~20 lines. If the ' +
  'answer does not fit, do NOT drop facts and do NOT overflow -- write it as an ' +
  'HTML page, publish it with the Artifact tool, and reply with the five-row ' +
  'summary plus the link. Plain words, no jargon (or explain it inline). Show ' +
  'results, not the work. Multi-turn work says where it is: what just finished, ' +
  'what is next. Estimates in real units. Anything left open ends with ONE ' +
  'action doable in under two minutes. Actions/options to pick between cap at ' +
  'five, ranked. Code/commands/security still written exactly.';

try {
  fs.mkdirSync(path.dirname(flagPath), { recursive: true });
  fs.writeFileSync(flagPath, 'on');
} catch (e) { /* flag is cosmetic, never block a session over it */ }

process.stdout.write(event === 'UserPromptSubmit' ? REMINDER : RULESET);
