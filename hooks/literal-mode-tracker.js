#!/usr/bin/env node
// literal-mode — UserPromptSubmit hook to track sticky "literal mode"
// Inspects user input for /literal commands and inline safewords, and
// writes/removes an existence-based flag file (contents irrelevant).

const fs = require('fs');
const path = require('path');
const os = require('os');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const flagPath = path.join(claudeDir, '.literal-active');

// One-turn safewords: exact, anchored, case-insensitive phrases. Must not
// false-positive on ordinary uses like "fix the literal string" or "the
// literal value" — every pattern anchors on word boundaries around the full
// phrase, not a bare substring match on "literal".
const INLINE_SAFEWORDS = [
  /\bjust do it\b/i,
  /\bdo exactly what i say\b/i,
  /\bno ai\b/i,
  /\bliterally do\b/i,
  /\bno pushback\b/i,
];

// Existence-based, symlink-refusing check — the flag's presence IS the
// state; contents are never read. Self-contained (does not reuse
// caveman-config's readFlag, which whitelists caveman mode strings and
// would reject a content-less/literal flag).
function isFlagPresent(targetPath) {
  try {
    const st = fs.lstatSync(targetPath);
    if (st.isSymbolicLink()) return false;
    return st.isFile();
  } catch (e) {
    return false;
  }
}

// Symlink-safe, atomic flag creation. Mirrors caveman-config's
// safeWriteFlag pattern (O_NOFOLLOW + 0600 + temp/rename) but simplified:
// the flag is existence-based so the written content is a placeholder.
function safeCreateFlag(targetPath) {
  try {
    const dir = path.dirname(targetPath);
    fs.mkdirSync(dir, { recursive: true });

    // Refuse to write through a symlinked flag path.
    try {
      if (fs.lstatSync(targetPath).isSymbolicLink()) return;
    } catch (e) {
      if (e.code !== 'ENOENT') return;
    }

    const tempPath = path.join(dir, `.literal-active.${process.pid}.${Date.now()}`);
    const O_NOFOLLOW = typeof fs.constants.O_NOFOLLOW === 'number' ? fs.constants.O_NOFOLLOW : 0;
    const flags = fs.constants.O_WRONLY | fs.constants.O_CREAT | fs.constants.O_EXCL | O_NOFOLLOW;
    let fd;
    try {
      fd = fs.openSync(tempPath, flags, 0o600);
      fs.writeSync(fd, '1');
      try { fs.fchmodSync(fd, 0o600); } catch (e) { /* best-effort on Windows */ }
    } finally {
      if (fd !== undefined) fs.closeSync(fd);
    }
    fs.renameSync(tempPath, targetPath);
  } catch (e) {
    // Silent fail — flag is best-effort
  }
}

// Symlink-refusing flag removal — never unlink-follows a symlink planted at
// the predictable flag path.
function safeRemoveFlag(targetPath) {
  try {
    const st = fs.lstatSync(targetPath);
    if (st.isSymbolicLink()) return;
    fs.unlinkSync(targetPath);
  } catch (e) {
    // Silent fail — missing file or race is fine
  }
}

// Parses the sticky toggle. Returns 'on', 'off', or null (no toggle this turn).
function parseStickyToggle(prompt) {
  if (/^\/literal(?:\s+on)?$/i.test(prompt)) return 'on';
  if (/^\/literal\s+off$/i.test(prompt)) return 'off';
  if (/\bstop literal\b/i.test(prompt) || /\bnormal mode\b/i.test(prompt)) return 'off';
  return null;
}

function applyStickyToggle(toggle) {
  if (toggle === 'on') {
    safeCreateFlag(flagPath);
  } else if (toggle === 'off') {
    safeRemoveFlag(flagPath);
  }
}

function detectInlineSafeword(prompt) {
  return INLINE_SAFEWORDS.some(re => re.test(prompt));
}

function emitReinforcement() {
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: "LITERAL MODE ACTIVE — obey the user's words literally; do NOT propose " +
        "alternatives, challenge, or wait; do NOT generate mockups unless explicitly asked."
    }
  }));
}

function main() {
  let input = '';
  process.stdin.on('data', chunk => { input += chunk; });
  process.stdin.on('end', () => {
    try {
      const data = JSON.parse(input);
      const prompt = (data.prompt || '').trim();

      const toggle = parseStickyToggle(prompt);
      applyStickyToggle(toggle);

      let inlineFired = false;
      if (toggle === null) {
        inlineFired = detectInlineSafeword(prompt);
      }

      if (isFlagPresent(flagPath) || inlineFired) {
        emitReinforcement();
      }
    } catch (e) {
      // Silent fail
    }
    process.exit(0);
  });
}

if (require.main === module) main();

module.exports = {
  isFlagPresent,
  safeCreateFlag,
  safeRemoveFlag,
  parseStickyToggle,
  applyStickyToggle,
  detectInlineSafeword,
  emitReinforcement,
  flagPath,
};
