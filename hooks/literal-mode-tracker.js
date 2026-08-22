#!/usr/bin/env node
// Tracks literal mode. UserPromptSubmit hook: reads {prompt} on stdin, keeps
// the mode's state as the existence of one flag file, and — while the mode is
// on, or an inline safeword fired this turn — hands the session a reminder to
// do exactly what was asked.
//
// Rewritten from a blank page 2026-08-22 (machinery rebuild). The contract is
// hooks/tests/literal-mode-tracker.test.js, which runs this file as a black
// box: prompt in, exit code + stdout + flag-file state out.
//
// STATE IS EXISTENCE, NOT CONTENT. The flag file's bytes are never read by
// anything — not here, not by the statusline badge. That one decision removes
// the whole class of "what does the file say" bugs, and it is why every
// filesystem touch below refuses symlinks: a file whose presence is the state
// is a file an attacker plants a link at, and following the link would read or
// delete whatever it points to.
//
// TWO TRIGGERS, DIFFERENT LIFETIMES:
//   /literal, /literal on          -> flag created: the mode is STICKY
//   /literal off, "stop literal",
//   "normal mode"                  -> flag removed
//   an inline safeword             -> reminder for THIS turn only; the flag is
//                                     never created, so nothing lingers
// Safewords are whole anchored phrases. "fix the literal string" must not trip
// anything, which is what the word boundaries are for.

const fs = require('fs');
const os = require('os');
const path = require('path');

const FLAG = path.join(
  process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude'),
  '.literal-active'
);

const SAFEWORDS = [
  /\bjust do it\b/i,
  /\bdo exactly what i say\b/i,
  /\bno ai\b/i,
  /\bliterally do\b/i,
  /\bno pushback\b/i,
];

// 'on', 'off', or null when the prompt is not a toggle at all.
function readToggle(prompt) {
  if (/^\/literal(\s+on)?$/i.test(prompt)) return 'on';
  if (/^\/literal\s+off$/i.test(prompt)) return 'off';
  if (/\bstop literal\b/i.test(prompt) || /\bnormal mode\b/i.test(prompt)) return 'off';
  return null;
}

function flagIsOn() {
  try {
    const st = fs.lstatSync(FLAG);
    return st.isFile() && !st.isSymbolicLink();
  } catch {
    return false;
  }
}

// Create via a fresh O_EXCL temp file renamed into place: never writes through
// a pre-planted symlink, and a crash mid-way leaves no half-state.
function turnOn() {
  try {
    try {
      if (fs.lstatSync(FLAG).isSymbolicLink()) return;
    } catch (e) {
      if (e.code !== 'ENOENT') return;
    }
    const dir = path.dirname(FLAG);
    fs.mkdirSync(dir, { recursive: true });
    const temp = path.join(dir, `.literal-active.${process.pid}.${Date.now()}`);
    const noFollow = fs.constants.O_NOFOLLOW || 0;
    const fd = fs.openSync(
      temp,
      fs.constants.O_WRONLY | fs.constants.O_CREAT | fs.constants.O_EXCL | noFollow,
      0o600
    );
    try {
      fs.writeSync(fd, '1');
    } finally {
      fs.closeSync(fd);
    }
    fs.renameSync(temp, FLAG);
  } catch {
    /* best effort: a mode that could not persist is a mode that is off */
  }
}

function turnOff() {
  try {
    if (fs.lstatSync(FLAG).isSymbolicLink()) return;
    fs.unlinkSync(FLAG);
  } catch {
    /* already gone, or a race lost: both mean off */
  }
}

function remind() {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        additionalContext:
          "LITERAL MODE ACTIVE — obey the user's words literally; do NOT propose " +
          'alternatives, challenge, or wait; do NOT generate mockups unless explicitly asked.',
      },
    })
  );
}

let input = '';
process.stdin.on('data', (chunk) => (input += chunk));
process.stdin.on('end', () => {
  try {
    const prompt = (JSON.parse(input).prompt || '').trim();
    const toggle = readToggle(prompt);
    if (toggle === 'on') turnOn();
    if (toggle === 'off') turnOff();
    // A toggle turn is about switching, not obeying: the inline check is
    // skipped so "/literal off" cannot fire a safeword on its own text.
    const inline = toggle === null && SAFEWORDS.some((re) => re.test(prompt));
    if (flagIsOn() || inline) remind();
  } catch {
    /* unreadable payload: nothing to track, nothing to say */
  }
  process.exit(0);
});
