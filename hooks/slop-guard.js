#!/usr/bin/env node
// slop-guard — Stop hook. Scans the assistant's last message for a short list of
// literal slop phrases from docs/ANTISLOP.md. WARNS ONLY: writes to stderr and
// always exits 0. It can never block a reply, and a broken/missing pattern file
// or transcript makes it exit 0 in silence rather than break a session.
//
// ---------------------------------------------------------------------------
// WHAT A CLEAN RUN PROVES — AND WHAT IT DOES NOT
// ---------------------------------------------------------------------------
// A clean run proves exactly one thing: none of the phrases listed in
// hooks/slop-patterns.json appeared in the text of the last reply. That is all.
// It is NOT a "this reply is not slop" verdict, and must never be reported as one.
//
// This hook is blind to every one of the following, all of which are in
// docs/ANTISLOP.md and several of which matter far more than anything it can see:
//   * Parroting the user's ask back at them instead of thinking.
//   * Invented or static filler values — fake percentages, made-up durations,
//     placeholder costs, unmeasured benchmarks. ANTISLOP.md calls fake precision
//     the worst tell in the file, and it is the user's single biggest complaint.
//     No regex can tell a measured number from an invented one.
//   * Padding, rule-of-three padding, symmetrical bullet grids, table abuse.
//   * Fake caveats — balance performed for its own sake.
//   * Overclaimed completion phrased in words this list does not happen to carry
//     ("all tests green", "verified", "ready to ship") with nothing run behind it.
//   * Agree-then-fold: reversing a correct position because of the user's tone.
//   * Bullet abuse and bolded-lead-in walls (deliberately not shipped — the
//     patterns for them flag this repo's own docs; see .audit-2026-07-31-detail/
//     phase3.md §6).
//   * ANY GUI slop. All 42 GUI tells are visual judgment, not text matching.
//
// So: silence here means "no listed phrase matched". It does not mean the reply
// was honest, useful, or free of slop. Judgement still lives with /antislop and
// with the reader.
// ---------------------------------------------------------------------------

const fs = require('fs');
const path = require('path');
const os = require('os');

const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const patternsPath = path.join(claudeDir, 'hooks', 'slop-patterns.json');

const MAX_SCAN_CHARS = 200000; // a runaway reply should not stall the Stop hook
const SNIPPET_CHARS = 70;
const MAX_REPORTED = 6;

// Loads the swappable pattern file. Any failure — missing file, bad JSON, a
// pattern that will not compile — yields fewer patterns (or none) rather than an
// exception. A broken pattern file must never break a session.
function loadPatterns(filePath) {
  let parsed;
  try {
    parsed = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (e) {
    return [];
  }
  if (!Array.isArray(parsed)) return [];

  const out = [];
  for (const entry of parsed) {
    if (!entry || typeof entry.pattern !== 'string' || typeof entry.tell !== 'string') continue;
    const minMatches = Number.isInteger(entry.minMatches) && entry.minMatches > 1 ? entry.minMatches : 1;
    let flags = typeof entry.flags === 'string' ? entry.flags : '';
    if (!flags.includes('g')) flags += 'g'; // needed to count occurrences
    let re;
    try {
      re = new RegExp(entry.pattern, flags);
    } catch (e) {
      continue; // one bad regex drops itself, not the whole file
    }
    out.push({ tell: entry.tell, re, minMatches });
  }
  return out;
}

// Pulls the last non-sidechain assistant text block out of a transcript JSONL.
// Returns '' for anything unreadable — the hook then has nothing to say.
function lastAssistantText(transcriptPath) {
  if (!transcriptPath || typeof transcriptPath !== 'string') return '';
  let raw;
  try {
    raw = fs.readFileSync(transcriptPath, 'utf8');
  } catch (e) {
    return '';
  }
  const lines = raw.split('\n');
  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i].trim();
    if (!line) continue;
    let entry;
    try {
      entry = JSON.parse(line);
    } catch (e) {
      continue;
    }
    if (entry.isSidechain === true) continue;
    const msg = entry.message;
    if (!msg || msg.role !== 'assistant') continue;

    let text = '';
    if (typeof msg.content === 'string') {
      text = msg.content;
    } else if (Array.isArray(msg.content)) {
      text = msg.content
        .filter(b => b && b.type === 'text' && typeof b.text === 'string')
        .map(b => b.text)
        .join('\n');
    }
    if (text.trim()) return text;
  }
  return '';
}

// Removes the places where a slop phrase is being QUOTED or shown as code rather
// than committed: fenced blocks, inline code, double-quoted spans, blockquotes.
// Without this, any reply that discusses ANTISLOP.md — including ANTISLOP.md
// itself — trips nearly every pattern.
function stripQuotedAndCode(text) {
  return text
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/`[^`\n]*`/g, ' ')
    .replace(/"[^"\n]{0,300}"/g, ' ')
    .replace(/“[^”\n]{0,300}”/g, ' ')
    .replace(/^[ \t]*>.*$/gm, ' ');
}

function scan(text, patterns) {
  const body = stripQuotedAndCode(text.slice(0, MAX_SCAN_CHARS));
  const findings = [];
  for (const p of patterns) {
    p.re.lastIndex = 0;
    const matches = body.match(p.re);
    if (!matches || matches.length < p.minMatches) continue;
    const sample = String(matches[0]).replace(/\s+/g, ' ').trim().slice(0, SNIPPET_CHARS);
    findings.push({ tell: p.tell, sample, count: matches.length });
  }
  return findings;
}

function formatWarning(findings) {
  const shown = findings.slice(0, MAX_REPORTED);
  const lines = [
    `slop-guard: ${findings.length} listed phrase${findings.length === 1 ? '' : 's'} matched in the reply just sent.`,
  ];
  for (const f of shown) {
    lines.push(`  - ${f.tell}: ${f.sample}${f.count > 1 ? ` (x${f.count})` : ''}`);
  }
  if (findings.length > shown.length) {
    lines.push(`  - ...and ${findings.length - shown.length} more`);
  }
  lines.push('String match only, not a verdict on the reply. It cannot see fake numbers,');
  lines.push('parroting, padding, or GUI slop — see the header of hooks/slop-guard.js.');
  return lines.join('\n') + '\n';
}

function main() {
  let input = '';
  process.stdin.on('data', chunk => { input += chunk; });
  process.stdin.on('end', () => {
    try {
      const data = JSON.parse(input || '{}');
      const text = lastAssistantText(data.transcript_path);
      if (text) {
        const findings = scan(text, loadPatterns(patternsPath));
        if (findings.length) process.stderr.write(formatWarning(findings));
      }
    } catch (e) {
      // Silent fail — a warning-only hook must never make noise about itself.
    }
    process.exit(0);
  });
  // No stdin at all (run by hand with no args): end the read and exit clean.
  process.stdin.on('error', () => process.exit(0));
}

if (require.main === module) main();

module.exports = {
  loadPatterns,
  lastAssistantText,
  stripQuotedAndCode,
  scan,
  formatWarning,
  patternsPath,
};
