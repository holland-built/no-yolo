#!/usr/bin/env node
// prompt-scan-nudge — SessionStart hook
// Surfaces the model recorded in the last /prompt-scan so Claude can compare
// it against its own current model ID (which it always knows) and offer to
// re-run /prompt-scan if they differ. The hook can't see the current model
// itself — only Claude, from its system prompt, can make that comparison.

const fs = require('fs');
const path = require('path');
const os = require('os');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const learningsPath = path.join(claudeDir, 'learnings.md');

let lastScan = null;
try {
  const content = fs.readFileSync(learningsPath, 'utf8');
  const matches = [...content.matchAll(/^## Scan (\S+) — model: (\S+)/gm)];
  if (matches.length) lastScan = matches[matches.length - 1];
} catch (e) { /* learnings.md absent — first run */ }

if (lastScan) {
  process.stdout.write(
    `PROMPT-SCAN CHECK: last /prompt-scan was ${lastScan[1]}, model "${lastScan[2]}". ` +
    `If your current model ID differs, proactively tell the user and offer to run /prompt-scan to refresh learnings.md.`
  );
} else {
  process.stdout.write(
    'PROMPT-SCAN CHECK: no learnings.md found. Proactively offer to run /prompt-scan once to establish a baseline for /better_prompt.'
  );
}
