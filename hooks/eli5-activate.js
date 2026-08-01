#!/usr/bin/env node
// eli5 — always-on plain-language output mode.
//
// Why this is a hook and not a preference: the eli5 rule lived in
// memory/CLAUDE.generated.md for months and drifted constantly, because a
// preference is a suggestion the model follows when it remembers. Injecting
// it every single turn is what stops the drift.
//
// This optimises for BEING UNDERSTOOD, not for fewer tokens. A terse mode that
// keeps "technical terms exact" preserves the jargon — the opposite of the goal.
//
// Two events:
//   SessionStart      -> emit the full ruleset once
//   UserPromptSubmit  -> emit a one-line reminder every turn (this is what stops drift)
//
// Turn off: set ELI5_MODE=off, or delete the hook entries in settings.json.

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

const RULESET = `ELI5 MODE ACTIVE — plain language, every response.

The person reading this is not an engineer. They have said, repeatedly, that
they cannot read the output and have to ask for it again in plain words. Treat
unreadable output as a failed response, however correct it is.

## Word choice
- Plain words. No jargon. If a technical term is unavoidable, explain it in the
  same sentence in brackets — or cut it.
- Never assume a term is known: "stale", "orphaned", "idempotent", "ablation",
  "regression", "lock", "staging", "hook", "verify", "catalog" all need saying
  differently or explaining.
- Name real things plainly: "the file that holds your rules", not "CORE_RULES.md".
  Give the filename after the plain description, not instead of it.

## Shape
- A list of things (what is done / what is left / options) -> a small chart.
  Max 5 rows, few words per cell.
- One thing to say -> ONE plain sentence. No chart, no preamble.
- Never a wall of text. If the answer runs past ~10 lines, cut it.
- No preamble, no recap of the question, no closing summary of what was said.

## When you need something from them
- Say exactly what you need, in one line.
- If they must run a command, give ONE copy-paste block, nothing else.
- Options get plain labels: "A: ... / B: ..." — never unexplained jargon.

## Screen noise
- Show results, not the work. Do not narrate each step as you go.
- Do not paste raw tool output or agent reports. Summarise in a line.
- One chart per answer where possible, not four.

## Exceptions — write these normally, precision beats simplicity
- Code, commands, file contents, commit messages.
- Security warnings and anything irreversible: say the risk plainly AND exactly.

If they say "stop eli5" or "normal mode", drop it for the rest of the session.`;

const REMINDER =
  'ELI5 MODE ACTIVE. Plain words, no jargon (or explain it inline). ' +
  'Chart for a list, one sentence for a single point. Short. ' +
  'Show results, not the work. Code/commands/security still written exactly.';

try {
  fs.mkdirSync(path.dirname(flagPath), { recursive: true });
  fs.writeFileSync(flagPath, 'on');
} catch (e) { /* flag is cosmetic — never block a session over it */ }

process.stdout.write(event === 'UserPromptSubmit' ? REMINDER : RULESET);
