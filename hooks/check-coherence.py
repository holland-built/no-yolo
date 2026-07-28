#!/usr/bin/env python3
"""check-coherence.py — find terms a SKILL.md branches on but never defines.

WHY THIS EXISTS
---------------
A de-duplication pass once cut lines from 24 files in ~/.claude and left four
skills logically broken while verify.sh reported 14/14 PASS the whole time:

  - skills/antislop/SKILL.md  Step 4 said "Emit only rows where Found = yes".
                              The lines that said when to mark something `Found`
                              were deleted. `Found` survived in exactly ONE
                              place: the filter that consumed it.
  - skills/release/SKILL.md   "Skip the approval gate only if ... --auto" —
                              the approval gate was defined nowhere.
  - skills/checkup/SKILL.md   disclosed "skipped checks + reasons" that no
                              surviving rule could produce.

Shape in every case: a file branches on a term that nothing in the file
defines. Structure checks (headings, frontmatter, link targets) cannot see it.
Only a definition-vs-use check can.

HOW IT WORKS
------------
1. Pull tokens out of a tight list of CONDITIONAL / FILTERING constructs
   (`where X =`, `rows where X`, `if X =`, `X ==`, `Mark X`, and the loose
   phrase forms `only if ...` / `only when ...` / `Skip ... if ...`).
2. Count each token's occurrences in the SAME file (whole file, code fences
   and frontmatter included — a definition anywhere counts as a definition).
3. A token that occurs exactly ONCE, in the consuming construct, is the
   finding: it is branched on but never set.

FALSE POSITIVES MAKE THIS WORTHLESS
-----------------------------------
A noisy check gets disabled and then protects nothing. So this is deliberately
conservative and WILL miss things (see KNOWN LIMITATIONS at the bottom):
  - fenced code blocks are ignored as extraction sources (shell examples, not
    skill logic) — but still count as definitions;
  - markdown table rows and URLs are ignored;
  - only tokens that LOOK like defined terms count: CamelCase, ALLCAPS,
    --flag, a backticked identifier, or (in the strict token constructs only)
    a single Capitalized word;
  - common English words are filtered out via STOPWORDS;
  - ALLOWLIST holds legitimate patterns that tripped it, each with a reason.

Missing a case is fine. Crying wolf is not.

Python 3 stdlib only. Usage:
    check-coherence.py                 # walk ~/.claude/skills/**/SKILL.md
    check-coherence.py FILE [FILE...]  # check specific files
Exit 1 if findings (so it is usable standalone); verify.sh deliberately
ignores the exit code and reports this WARN-only for now.
"""

import os
import re
import sys

SKILLS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "skills")

# Words that are English, not defined terms. A token here is never reported.
STOPWORDS = {
    "The", "A", "An", "It", "This", "That", "These", "Those", "All", "Any",
    "No", "Yes", "True", "False", "None", "Not", "And", "Or", "But", "If",
    "Then", "Else", "When", "Where", "While", "Only", "Skip", "Use", "Run",
    "You", "We", "I", "Is", "Are", "Was", "Be", "Do", "Does", "Did", "Has",
    "Have", "Had", "Can", "Will", "Would", "Should", "Must", "May", "One",
    "Two", "Three", "Each", "Every", "Both", "Same", "Other", "Some", "Such",
    "Its", "Their", "There", "Here", "Now", "New", "Old", "Set", "Get",
    "Read", "Write", "Edit", "Bash", "Stop", "Start", "End", "Step", "Note",
    "Output", "Input", "Rule", "Rules", "Never", "Always", "Ask", "Say",
    "OK", "TODO", "NOTE", "AND", "OR", "NOT", "IF", "ALL", "ANY", "NO",
    "YES", "ONLY", "MUST", "STOP",
}

# Legitimate patterns that tripped the check. Add here, with the reason, rather
# than loosening a rule — loosening costs coverage everywhere.
ALLOWLIST = {
    # (basename of skill dir, token) pairs.
    # e.g. ("some-skill", "SomeTerm"),  # reason it is fine
}

# --- what a "defined term" looks like -------------------------------------
RE_BACKTICKED = re.compile(r"^[A-Za-z_][A-Za-z0-9_.:-]*$")
RE_ALLCAPS = re.compile(r"^[A-Z][A-Z0-9]+(?:_[A-Z0-9]+)*$")
RE_CAMEL = re.compile(r"^[A-Z][a-z]+(?:[A-Z][a-z0-9]*)+$")
RE_CAPWORD = re.compile(r"^[A-Z][a-z]{2,}$")
RE_FLAG = re.compile(r"^--[a-z][a-z0-9-]+$")

# Token as it may appear inline: `backticked`, --flag, or a bare word.
TOKEN = r"(?:`[^`]+`|--[a-z][a-z0-9-]+|[A-Za-z_][A-Za-z0-9_]*)"

# --- the conditional / filtering constructs we trust ----------------------
# Strict: the token sits in a fixed slot, so even a plain Capitalized word
# there is almost certainly a defined term.
STRICT_PATTERNS = [
    re.compile(r"\brows?\s+where\s+(" + TOKEN + r")\b"),
    re.compile(r"\bwhere\s+(" + TOKEN + r")\s*(?:=[^=]|==|\bis\b)"),
    re.compile(r"\bif\s+(" + TOKEN + r")\s*=[^=]"),
    re.compile(r"(" + TOKEN + r")\s*==\s*\S"),
    re.compile(r"\bMark\s+(" + TOKEN + r")\b"),
]

# Loose: a whole clause follows, so we only accept unambiguous term shapes
# (CamelCase / ALLCAPS / --flag / backticked) from it — never a bare
# Capitalized word, which at the start of a clause is usually just English.
LOOSE_PATTERNS = [
    re.compile(r"\bonly\s+if\b(.*)$", re.IGNORECASE),
    re.compile(r"\bonly\s+when\b(.*)$", re.IGNORECASE),
    re.compile(r"\bSkip\b.*?\bif\b(.*)$"),
]

RE_URL = re.compile(r"https?://\S+")
RE_FENCE = re.compile(r"^\s*(?:```|~~~)")


def strip_ticks(tok):
    return tok[1:-1] if tok.startswith("`") and tok.endswith("`") else tok


def looks_defined(tok, strict, backticked):
    """Does this token look like a defined term (vs ordinary English)?

    `strict` = the token came from a fixed slot in a conditional (`where X =`),
    so weaker shapes are trustworthy there. In a loose clause (`only if ...`)
    anything not explicitly marked as an identifier is assumed to be prose.
    """
    if tok in STOPWORDS:
        return False
    if backticked:
        # Backticks are the author explicitly marking an identifier. Trust them.
        return bool(RE_BACKTICKED.match(tok))
    if RE_FLAG.match(tok) or RE_CAMEL.match(tok):
        return True
    if RE_ALLCAPS.match(tok):
        # SCREAMING_SNAKE is always a term. Bare ALLCAPS is this repo's prose
        # emphasis convention ("it REFUSES if...", "surface it as a FINDING"),
        # so it is only trusted in a strict slot. This alone removed every
        # false positive the first version produced on the current tree.
        return "_" in tok or strict
    # A bare Capitalized word is only trusted inside a strict construct.
    return strict and bool(RE_CAPWORD.match(tok))


def candidates(line):
    """Yield tokens consumed by a conditional/filtering construct in this line."""
    clean = RE_URL.sub(" ", line)
    for pat in STRICT_PATTERNS:
        for m in pat.finditer(clean):
            raw = m.group(1)
            tok = strip_ticks(raw)
            if looks_defined(tok, True, raw.startswith("`")):
                yield tok
    for pat in LOOSE_PATTERNS:
        m = pat.search(clean)
        if not m:
            continue
        for raw in re.findall(TOKEN, m.group(1)):
            tok = strip_ticks(raw)
            if looks_defined(tok, False, raw.startswith("`")):
                yield tok


def occurrences(text, tok):
    """Count tok in the whole file, case-sensitively. A definition anywhere —
    including inside a code fence — counts, so this only fires on true orphans."""
    if re.match(r"^\w", tok) and re.search(r"\w$", tok):
        return len(re.findall(r"\b" + re.escape(tok) + r"\b", text))
    return len(re.findall(re.escape(tok), text))


def check_file(path):
    """Return [(lineno, token, line_text)] for tokens consumed but never defined."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError:
        return []

    skill = os.path.basename(os.path.dirname(path))
    findings, seen, in_fence = [], set(), False

    for i, line in enumerate(text.splitlines(), 1):
        if RE_FENCE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue  # shell/example blocks are not skill logic
        if line.lstrip().startswith("|"):
            continue  # markdown table row

        for tok in candidates(line):
            if tok in seen or (skill, tok) in ALLOWLIST:
                continue
            if occurrences(text, tok) == 1:
                seen.add(tok)
                findings.append((i, tok, line.strip()))
    return findings


def walk(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [
            d for d in dirnames
            if d != "plugins" and not os.path.islink(os.path.join(dirpath, d))
        ]
        if "SKILL.md" in filenames:
            p = os.path.join(dirpath, "SKILL.md")
            if not os.path.islink(p):
                yield p


def main(argv):
    targets = argv[1:] or sorted(walk(SKILLS_DIR))
    total = 0
    for path in targets:
        for lineno, tok, text in check_file(path):
            total += 1
            print("%s:%d: consumed-but-undefined term %r\n    %s" % (path, lineno, tok, text))
    if total:
        print("\n%d consumed-but-undefined term(s) across %d file(s)." % (total, len(targets)))
        return 1
    print("no consumed-but-undefined terms (%d files checked)" % len(targets))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

# KNOWN LIMITATIONS (honest, tested):
#  - Phrase-based breaks are NOT caught. skills/checkup/SKILL.md's historical
#    break was a step disclosing "skipped checks + reasons" with no rule
#    producing them — lowercase prose, no token, nothing to count. Likewise
#    release's "Skip the approval gate only if ... --auto": the orphan was the
#    lowercase phrase "approval gate", while `--auto` legitimately occurs twice.
#    Catching those needs semantic analysis, which cannot be made conservative
#    enough to keep false positives near zero.
#  - A term defined only in a code fence counts as defined (deliberate).
