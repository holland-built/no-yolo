#!/usr/bin/env python3
"""check-coherence.py — find terms/mechanisms a SKILL.md refers to but never defines.

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

Two modes now run over every file:

  token  — a single identifier (`Found`, `--flag`, CamelCase) is branched on
           and occurs exactly once, in the construct that consumes it.
  phrase — a definite/possessive reference to a NAMED MECHANISM ("the approval
           gate", "any skipped checks", "the regression gate") whose noun
           phrase occurs nowhere else in the file. Catches the release and
           checkup breaks, which were lowercase prose with no token in them.

HOW TOKEN MODE WORKS
--------------------
1. Pull tokens out of a tight list of CONDITIONAL / FILTERING constructs
   (`where X =`, `rows where X`, `if X =`, `X ==`, `Mark X`, and the loose
   phrase forms `only if ...` / `only when ...` / `Skip ... if ...`).
2. Count each token's occurrences in the SAME file (whole file, code fences
   and frontmatter included — a definition anywhere counts as a definition).
3. A token that occurs exactly ONCE, in the consuming construct, is the
   finding: it is branched on but never set.

HOW PHRASE MODE WORKS
---------------------
1. Extract `<determiner> <modifier>{1,2} <head>` where head is one of a tiny
   closed set of mechanism nouns (gate / check / guard / rule / step / list /
   table) — e.g. "the approval gate", "any skipped checks". A bare "the gate"
   (no modifier) is not a named mechanism and is never extracted.
2. Normalise: lowercase, strip markdown emphasis and backticks, singularise
   the head noun. The determiner is dropped — only the noun phrase matters.
3. Count that noun phrase across the WHOLE normalised file. Any other
   occurrence — a heading, a **bold label**, a table cell, a code fence, plain
   prose — counts as the definition.
4. Exactly ONE occurrence (the reference itself) = phrase orphan.

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

and phrase mode additionally ignores:
  - headings and frontmatter as SOURCES (a heading is a definition, not a
    reference) — both still count as definitions;
  - positional//generic modifiers (PHRASE_MOD_STOPWORDS: "the next step", "the
    same rule", "the first check") — those name a position, not a mechanism;
  - any line pointing OUTWARD (a /slash-command, docs/, ~/.claude, CORE_RULES,
    or a markdown link) — the mechanism legitimately lives in another file.

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

# ==========================================================================
# PHRASE MODE — references to a named mechanism that nothing in the file names
# ==========================================================================

# The closed set of nouns that name a MECHANISM (a thing the file must define
# somewhere). Deliberately tiny: adding nouns adds false positives fast.
# `list` and `table` were tried and REMOVED: they are ordinary English nouns,
# so "the surviving Criticals list" / "the P0 findings list" are descriptions
# of a previous step's output, not names of a mechanism. They produced only
# false positives on the current tree and caught neither historical break.
PHRASE_HEADS = r"(?:gate|check|guard|rule|step)"

# Determiners that make the reference definite/possessive — i.e. "the one we
# already established", which is exactly the assumption that breaks.
# "all"/"no"/"every" are deliberately NOT here: "no build step", "all feed the
# Step 2 briefs" are ordinary English, not back-references to a named thing.
PHRASE_DETS = r"(?:the|its|their|this|that|these|those|any)"

# A reference: determiner + 1-2 modifier words + mechanism noun.
# A bare "the gate" has no modifier and names nothing — not extracted.
RE_PHRASE = re.compile(
    r"\b" + PHRASE_DETS + r"\s+((?:[a-z][a-z0-9-]*\s+){1,2})(" + PHRASE_HEADS + r")s?\b"
)

# Modifiers that describe a POSITION or a generic quality rather than naming a
# mechanism. "the next step" / "the same rule" / "the first check" refer to
# something structural, not to a named thing that must be defined elsewhere.
PHRASE_MOD_STOPWORDS = {
    # positional / ordinal
    "first", "second", "third", "fourth", "fifth", "next", "last", "final",
    "previous", "prior", "preceding", "following", "above", "below", "later",
    "earlier", "former", "latter", "current", "remaining", "rest",
    # identity / quantity
    "same", "other", "another", "whole", "entire", "single", "sole", "only",
    "one", "two", "three", "few", "many", "several", "most", "least", "more",
    "less", "both", "either", "neither", "own", "such",
    # generic quality
    "new", "old", "real", "actual", "usual", "normal", "main", "big", "small",
    "quick", "fast", "slow", "easy", "hard", "simple", "basic", "good", "bad",
    "best", "worst", "right", "wrong", "full", "short", "long", "extra",
    "important", "relevant", "necessary", "obvious", "plain", "exact",
    # articles / determiners caught mid-phrase ("this is a list of options")
    "a", "an", "the", "this", "that", "these", "those", "each", "every", "any",
    "all", "no", "some", "which", "what", "its", "their",
    # prepositions — these mean the regex ran across a phrase boundary
    # ("amend the briefing before Step 7" is not a "briefing before step")
    "of", "in", "on", "at", "to", "from", "for", "with", "without", "by",
    "via", "per", "into", "onto", "within", "during", "under", "over",
    "about", "across", "between", "after", "before", "against", "through",
    "as", "than", "like", "upon", "out", "off", "up", "down",
    # adverbs / copulas — likewise a boundary, not a name
    "is", "are", "was", "were", "be", "been", "and", "or", "not", "then",
    "very", "also", "still", "just", "even", "once", "twice", "again",
    "always", "never", "often", "usually", "sometimes", "here", "there",
    "now", "already", "yet", "so", "too",
}

# Legitimate phrase references that tripped the check. Same discipline as
# ALLOWLIST: add the pair with a reason, do not loosen a rule.
PHRASE_ALLOWLIST = {
    # (basename of skill dir, normalised noun phrase) pairs.
    # e.g. ("some-skill", "approval gate"),  # reason it is fine
}

# A reference that points at ANOTHER file legitimately lives there. Any of
# these on the line and phrase mode leaves the line alone.
RE_OUTWARD = re.compile(
    r"(?:"
    r"/[A-Za-z][\w.-]*"          # /slash-command or a path segment
    r"|\bCORE_RULES\b"
    r"|~/\.claude"
    r"|\[[^\]]*\]\([^)]*\)"      # markdown link
    r"|\.md\b"                   # names another doc
    r")"
)

RE_EMPHASIS = re.compile(r"[`*_~]+")
RE_WS = re.compile(r"\s+")


def normalise(text):
    """Lowercase, drop markdown emphasis/backticks, collapse whitespace."""
    return RE_WS.sub(" ", RE_EMPHASIS.sub(" ", text.lower()))


def phrase_candidates(line):
    """Yield normalised `<modifier(s)> <head>` noun phrases referenced as an
    already-established mechanism on this line."""
    clean = normalise(line)
    for m in RE_PHRASE.finditer(clean):
        mods = m.group(1).split()
        # Drop leading positional filler ("the same approval gate" -> approval).
        while mods and mods[0] in PHRASE_MOD_STOPWORDS:
            mods.pop(0)
        if not mods or any(w in PHRASE_MOD_STOPWORDS for w in mods):
            continue
        yield " ".join(mods + [m.group(2)])


RE_WORD = re.compile(r"[a-z0-9]+")

# How far apart the words of the noun phrase may sit and still count as the
# same reference. Wide on purpose: checkup's fix for the historical break was
# "a missing dependency or no network SKIPs that check with a noted reason" —
# same mechanism, words reordered and re-inflected. A narrow matcher would
# have called the FIXED file broken.
PHRASE_WINDOW = 8


def stem(word):
    """Crudest possible stemmer — no dependency, just enough to tie
    skip/skips/skipped and gate/gates to one form. Over-stemming is safe here:
    it can only make a phrase look MORE defined, never less."""
    w = word
    if w.endswith("ies") and len(w) > 4:
        w = w[:-3] + "y"
    elif w.endswith("ing") and len(w) > 5:
        w = w[:-3]
    elif w.endswith("ed") and len(w) > 4:
        w = w[:-2]
    elif w.endswith("es") and len(w) > 4:
        w = w[:-2]
    elif w.endswith("s") and not w.endswith("ss") and len(w) > 3:
        w = w[:-1]
    if len(w) > 3 and w[-1] == w[-2]:   # skipp -> skip, runn -> run
        w = w[:-1]
    if w.endswith("e") and len(w) > 3:  # gate/gates -> gat, rule/rules -> rul
        w = w[:-1]
    return w


def stem_words(text):
    return [stem(w) for w in RE_WORD.findall(text)]


def outward_paragraphs(lines):
    """Return a set of 1-based line numbers whose PARAGRAPH points outward.

    Scope is the paragraph, not the line, because the pointer and the reference
    routinely sit on different lines of the same block — design-audit says
    "run the install guard first" on one line and "it is the same mechanism
    defined in `/design` Step 0" two lines later. Same block, same referent.
    """
    outward, block = set(), []
    for i, line in enumerate(lines + [""], 1):
        if line.strip():
            block.append((i, line))
            continue
        if block and RE_OUTWARD.search(" ".join(t for _, t in block)):
            outward.update(n for n, _ in block)
        block = []
    return outward


def phrase_occurrences(text_stems, phrase):
    """Count places in the file where the whole noun phrase is present —
    headings, **bold labels**, table cells, code fences and plain prose all
    count as the definition. Matching is stem-based and windowed, not literal:
    a definition that says the same thing in different word order still counts.
    """
    words = [stem(w) for w in RE_WORD.findall(phrase)]
    head, mods = words[-1], set(words[:-1])
    hits = 0
    for i, w in enumerate(text_stems):
        if w != head:
            continue
        near = set(text_stems[max(0, i - PHRASE_WINDOW): i + PHRASE_WINDOW + 1])
        if mods <= near:
            hits += 1
    return hits


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
    """Return [(mode, lineno, term, line_text)] for terms/mechanisms a file
    consumes or refers to but never defines."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
    except OSError:
        return []

    skill = os.path.basename(os.path.dirname(path))
    text_stems = stem_words(normalise(text))
    findings, seen, seen_ph, in_fence = [], set(), set(), False
    lines = text.splitlines()
    outward = outward_paragraphs(lines)
    heading_stems = set()
    # Frontmatter is metadata, not skill logic: never a phrase SOURCE.
    fm_end = 0
    if lines and lines[0].strip() == "---":
        for j, line in enumerate(lines[1:], 2):
            if line.strip() == "---":
                fm_end = j
                break

    for i, line in enumerate(lines, 1):
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
                findings.append(("token", i, tok, line.strip()))

        if line.lstrip().startswith("#"):
            # A heading is a definition site, never a reference — and it names
            # what its whole section is about, so "this mutation gate" under
            # "### Step 3 — Approve-all gate" is defined by the heading itself.
            heading_stems = set(stem_words(normalise(line)))
            continue
        if i <= fm_end or i in outward:
            continue  # frontmatter / this block points at another file
        for phrase in phrase_candidates(line):
            if phrase in seen_ph or (skill, phrase) in PHRASE_ALLOWLIST:
                continue
            if stem(phrase.split()[-1]) in heading_stems:
                continue  # the enclosing section heading names this mechanism
            if phrase_occurrences(text_stems, phrase) == 1:
                seen_ph.add(phrase)
                findings.append(("phrase", i, phrase, line.strip()))
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
        for mode, lineno, term, text in check_file(path):
            total += 1
            label = ("consumed-but-undefined term" if mode == "token"
                     else "referenced-but-undefined mechanism")
            print("%s:%d: [%s] %s %r\n    %s" % (path, lineno, mode, label, term, text))
    if total:
        print("\n%d consumed/referenced-but-undefined term(s) across %d file(s)."
              % (total, len(targets)))
        return 1
    print("no consumed/referenced-but-undefined terms (%d files checked)" % len(targets))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

# KNOWN LIMITATIONS (honest, tested):
#
# TOKEN MODE
#  - A term defined only in a code fence counts as defined (deliberate).
#
# PHRASE MODE — what it DOES catch (both proven red-then-green against the
# real ee49914 breaks, and green across all 31 current SKILL.md files):
#  - "Skip the approval gate only if ... --auto" with no approval gate named
#    anywhere (skills/release) — still LIVE in the tree as of this writing;
#    commit 0cb12a2 restored 12 other cut rules but not this one.
#  - "Disclose ... any skipped checks + reasons" with nothing permitting a skip
#    (skills/checkup, since fixed by a rule that says a missing dependency
#    "SKIPs that check with a noted reason" — different words, so matching is
#    stem-based and windowed rather than literal, or the FIX would read broken).
#
# PHRASE MODE — what it does NOT catch, on purpose:
#  - Any head noun outside PHRASE_HEADS (gate/check/guard/rule/step). A dangling
#    "the escalation ladder", "the severity budget", "the rollback plan" sails
#    through. `list` and `table` were tried and pulled back out: pure noise.
#  - Bare "the gate" / "the check" with no modifier — nothing to look up.
#  - Anything whose paragraph mentions a /slash-command, docs/, ~/.claude,
#    CORE_RULES, a .md filename or a markdown link. That is a big blind spot:
#    most SKILL.md paragraphs cross-reference something, so real orphans that
#    happen to share a paragraph with a pointer are invisible.
#  - A reference inside a section whose HEADING already names the mechanism
#    noun ("this mutation gate" under "### Step 3 — Approve-all gate").
#  - Verb-phrase breaks with no noun at all ("re-run it until it settles" where
#    nothing says what settling is). Still needs semantics; still out of reach.
#  - The mechanism named once in a table row or fenced block and referenced
#    once elsewhere reads as 2 occurrences = defined, even if the "definition"
#    is only another mention. This check proves a name EXISTS, never that the
#    thing behind it is specified.
