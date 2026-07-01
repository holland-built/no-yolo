#!/usr/bin/env node
// lockstep — PreToolUse guard for Edit/Write/NotebookEdit
// Blocks file mutation while ~/.claude/.lockstep-active exists.
// Toggle with the /lockstep skill.

const fs = require('fs');
const path = require('path');
const os = require('os');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const flagPath = path.join(claudeDir, '.lockstep-active');

if (fs.existsSync(flagPath)) {
  process.stderr.write(
    'LOCKSTEP ACTIVE — file edits are blocked until the user agrees. ' +
    'Do not retry this tool call. Summarize what you were about to change and why, ' +
    'then wait for the user to say "go" / "agreed" or run /lockstep off before editing anything.'
  );
  process.exit(2);
}

process.exit(0);
