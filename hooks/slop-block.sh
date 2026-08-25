#!/usr/bin/env bash
# Reports machine-writing tells in a file that was just written or edited.
# Wired in settings.json as a PostToolUse hook on Write and Edit.
# Exit 2 returns the message to Claude, which fixes the file before continuing.
#
# Only patterns a program can decide are here. Judgement rules live in docs/PROSE.md,
# where a person applies them.
#
# Code is not prose. Fenced blocks and inline code spans are filtered out before any
# rule runs, because the specimens inside them are the subject rather than the writing:
# a shell command, an output template, or a glossary row quoted to show its shape. The
# first version of this hook checked raw lines and cried wolf on six files in this repo
# on 2026-08-21, four of them its own. A guard that cries wolf gets switched off.
set -uo pipefail

# Read the payload ONCE. Everything below asks jq about this string rather than about stdin,
# which can only be consumed once and used to be consumed by the line that finds the file path.
PAYLOAD="$(cat)"
ask() { printf '%s' "$PAYLOAD" | jq -r "$1" 2>/dev/null; }

f="$(ask '.tool_input.file_path // ""')"
[ -z "$f" ] || [ ! -f "$f" ] && exit 0

case "$f" in
  *.md|*.txt|*.mdx) ;;
  *) exit 0 ;;
esac

PROSE="$(mktemp)"
NEWTEXT="$(mktemp)"
TOUCHED="$(mktemp)"
trap 'rm -f "$PROSE" "$NEWTEXT" "$TOUCHED"' EXIT

# ── REPORT WHAT THIS EDIT WROTE, NOT WHAT THE FILE CONTAINS ──────────────────────────────
#
# This hook used to check the whole file every time, and on a long document that buries the
# finding it exists to surface. Measured 2026-08-25 on a 1,130-line design document: a
# three-line edit returned 53 long-dash reports, 52 of them about prose written months earlier
# by somebody who is not being asked to change it now. Reading 53 findings to learn whether one
# of them is yours is the cost, every edit, forever — and a check that expensive to read is a
# check people stop reading, which is the same end state as switching it off.
#
# It is NOT solved by exempting the file or softening the rule. Both throw away a standard that
# is right, to fix a reporting problem. What is scoped is the REPORT: every rule still runs over
# the whole prose, and a finding is printed only when it sits on a line this tool call wrote.
#
# Whole-file coverage is not lost, and was never this hook's job. `.vale.ini` says so in its own
# words: the hook fires on Write and Edit so it only ever sees a file an agent just touched,
# while vale runs over every tracked .md from verify.sh and reaches the files nobody edited
# today. The two reaches were always meant to be different. This makes that true.
#
# Matched by line CONTENT rather than by offset, so it holds when an edit shifts every line
# below it. A Write carries the whole file as `content`, so a Write reports everything, which is
# right: all of it was just written. When the payload names no new text at all the filter is
# empty and every finding is printed, because a filter that cannot tell what changed must not
# decide that nothing did.
ask '[.tool_input.new_string?, .tool_input.content?, (.tool_input.edits // [])[]?.new_string?]
     | map(select(type == "string")) | join("\n")' > "$NEWTEXT"

# Shared awk source. Held once so the two passes cannot disagree about what a fence is.
# Nothing here writes to /dev/stderr or uses a GNU extension: the file is read by BSD awk
# on macOS and by mawk or gawk on the Linux CI runner, and the balance pass reports
# through its exit status instead, which every awk agrees on.
read -r -d '' AWK_FENCE <<'AWKEOF' || true
  function fence_len(s, ch,   n) {
    n = 0
    while (substr(s, n + 1, 1) == ch) n++
    return n
  }
  # An opening or closing fence: at most three spaces of indent, then three or more of
  # ` or ~. A run of one character never closes a fence opened with the other, and a
  # short run never closes a longer one, so ```` in a ``` block stays inside it.
  function marker(line,   ind, rest, ch, n) {
    ind = match(line, /[^ ]/)
    if (ind == 0 || ind > 4) return ""
    rest = substr(line, ind)
    ch = substr(rest, 1, 1)
    if (ch != "`" && ch != "~") return ""
    n = fence_len(rest, ch)
    if (n < 3) return ""
    return ch " " n " " substr(rest, n + 1)
  }
  # True when this line closes a fence opened with character oc and run length ol.
  function closes(m, oc, ol,   p, tail) {
    split(m, p, " ")
    if (p[1] != oc || p[2] + 0 < ol) return 0
    tail = substr(m, index(m, p[2]) + length(p[2]))
    gsub(/[ \t]/, "", tail)
    return tail == ""
  }
  # Drop every inline code span whose opening run of backticks has a closing run of the
  # SAME length, which is the CommonMark rule. An unmatched run is left in place along
  # with the prose after it, so a stray backtick cannot blank the rest of the line.
  function strip(s,   out, i, len, run, j, run2, found) {
    out = ""; i = 1; len = length(s)
    while (i <= len) {
      if (substr(s, i, 1) != "`") { out = out substr(s, i, 1); i++; continue }
      run = fence_len(substr(s, i), "`")
      j = i + run; found = 0
      while (j <= len) {
        if (substr(s, j, 1) == "`") {
          run2 = fence_len(substr(s, j), "`")
          if (run2 == run) { found = j; break }
          j += run2
        } else j++
      }
      if (found) { i = found + run } else { out = out substr(s, i, run); i += run }
    }
    return out
  }
AWKEOF

# Do the fences balance? Exit 0 yes, 1 no. An unterminated fence is a defect of its own
# and is reported below; it must never switch the remaining rules off, or a single stray
# ``` would silence the file and a check a typo can silence is worse than no check.
fences_balanced() {
  awk "$AWK_FENCE"'
    { m = marker($0)
      if (m == "") next
      if (!open) { split(m, p, " "); open = 1; oc = p[1]; ol = p[2] + 0; next }
      if (closes(m, oc, ol)) open = 0
    }
    END { exit open ? 1 : 0 }
  ' "$1"
}

# Two passes over the file. The first decides whether the fences balance; the second
# writes one line per input line, so every line number below still points at the real
# file. A fenced line becomes empty, and an inline code span is dropped from its line.
#
# When the fences do NOT balance, the second pass treats nothing as fenced and checks
# every line. Otherwise a single stray ``` would switch the rest of the file off, and a
# check that can be silenced by a typo is worse than no check. The unterminated fence
# is reported in its own right below.
balanced=1
fences_balanced "$f" || balanced=0

awk "$AWK_FENCE"'
  BEGIN { inb = 0 }
  {
    if (!balanced) { print strip($0); next }
    m = marker($0)
    if (m != "") {
      if (!inb) { split(m, p, " "); inb = 1; ic = p[1]; il = p[2] + 0; print ""; next }
      if (closes(m, ic, il)) { inb = 0; print ""; next }
    }
    if (inb) { print ""; next }
    print strip($0)
  }
' balanced="$balanced" "$f" > "$PROSE"

# The line numbers of $f whose content this tool call wrote. $PROSE is line-aligned with $f, so
# a number here selects the same line in both. Whitespace is trimmed on both sides of the
# comparison because an edit's text carries the indentation it was given, not the file's.
awk '
  NR == FNR {
    s = $0; sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
    if (s != "") want[s] = 1
    next
  }
  {
    s = $0; sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
    if (s != "" && (s in want)) print FNR
  }
' "$NEWTEXT" "$f" > "$TOUCHED"

# Keep only the findings on those lines. An empty filter means the payload named no new text,
# and then every finding is printed: a filter that cannot tell what changed must not be the
# thing that decides nothing did.
mine() {
  if [ ! -s "$TOUCHED" ]; then cat; return; fi
  # -E and not -F: the patterns below are `^<n>:`, and under -F the caret is a literal
  # character rather than an anchor, so every one of them matches nothing. Line numbers are
  # digits, so there is nothing here needing an escape.
  grep -E -f <(sed 's/^/^/; s/$/:/' "$TOUCHED") || true
}

findings=""

if [ "$balanced" = 0 ]; then
  findings="${findings}A code fence is opened and never closed, so every regex rule below ran
against the whole file rather than its prose. Close the fence. (Vale, at the end,
parses the file itself and is unaffected.)
"
fi

# The em-dash, in prose only.
dash=$(grep -n '—' "$PROSE" 2>/dev/null | mine || true)
[ -n "$dash" ] && findings="${findings}Long dash in prose. Use a full stop, a comma, or a colon:
${dash}
"

# Vocabulary, counted. One is nothing; three on a page is the signal.
vocab=$(grep -onEi '\b(elevate|seamless|unleash|tapestry|testament|holistic|meticulous(ly)?|nuanced|myriad|embark|unlock|underscore|showcasing)\b' "$PROSE" 2>/dev/null | mine || true)
n=$(printf '%s' "$vocab" | grep -c . || true)
[ "${n:-0}" -ge 3 ] && findings="${findings}${n} machine-vocabulary words. Say the specific thing instead:
${vocab}
"

# Sign-offs that add no next step.
cta=$(grep -nEi 'feel free to (ask|reach)|let me know if you (need|have)|don.t hesitate to' "$PROSE" 2>/dev/null | mine || true)
[ -n "$cta" ] && findings="${findings}Closing line with no next action. Name the action, or end:
${cta}
"

# ── Vale, the maintained second opinion ─────────────────────────────────────
# The rules above are hand-kept regexes. Vale runs styles/NoYolo/*.yml, which
# transcribe the rest of docs/PROSE.md, and it is a real Markdown parser rather
# than a fence-stripping awk script.
#
# ABSENT MEANS SILENT. No vale on PATH, or no .vale.ini, and this block does
# nothing and says nothing. A hook that warns about a missing optional tool on
# every single edit is a hook people turn off, and everything above still runs.
#
# THE ORIGINAL FILE, NEVER $PROSE. Vale drops fenced blocks and inline code
# spans itself. Handing it the stripped copy would filter twice, and the copy's
# blanked lines would push its column numbers off the real text.
#
# 2>&1 ON PURPOSE. Vale exits 0 whether it found warnings or nothing at all, and
# writes a parse failure (E201 on malformed YAML frontmatter, say) to stderr with
# exit 2. Both are worth reporting, so the two streams are merged.
#
# BUT A BROKEN VALE MUST NOT BLOCK THE EDIT. Exit 2 covers the file's own fault
# (bad frontmatter) AND vale's (a StylesPath that is not there, a rule file that
# will not parse). The second kind is true of every file, so blocking on it turns
# one bad config into a hook that refuses every markdown write until somebody
# notices. `--output line` prints findings as `<path>:<line>:<col>:...`, so the
# path being absent from the output is what separates the tool's fault from the
# file's: that case is reported on stderr and left out of `findings`.
#
# WHICH .vale.ini. The hook's own directory answers first. This file ships beside
# the config and the styles it uses, so a checkout anywhere finds them: a CI
# runner's workspace, or a clone somewhere other than ~/.claude. In a real install
# that path IS ~/.claude/.vale.ini, so the CLAUDE_CONFIG_DIR fallback below changes
# nothing there and still covers a hook copied out of the repo. Asking HOME alone
# left CI silent on a file its own test expected vale to catch.
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)"
VALE_INI="${HOOK_DIR:-}/.vale.ini"
[ -f "$VALE_INI" ] || VALE_INI="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.vale.ini"
if command -v vale >/dev/null 2>&1 && [ -f "$VALE_INI" ]; then
  vale_out=$(vale --config "$VALE_INI" --output line --no-wrap "$f" 2>&1)
  vale_rc=$?
  if [ "$vale_rc" -ge 2 ] && ! printf '%s' "$vale_out" | grep -qF "$f"; then
    printf 'slop-block: vale could not run (exit %s), so its half was not checked:\n%s\n' \
      "$vale_rc" "$vale_out" >&2
  else
    # Scoped like the rules above. Vale prints `<path>:<line>:<col>:<rule>:<message>`, so the
    # line number sits in field 2 and the same touched-line filter applies — with the path
    # stripped off the front first, because it contains colons of its own on no platform this
    # runs on but is noise in a report about one file.
    vale_mine=$(printf '%s' "$vale_out" | sed "s|^$f:||" | mine)
    [ -n "$vale_mine" ] && findings="${findings}Vale:
${vale_mine}
"
  fi
fi

if [ -n "$findings" ]; then
  printf 'Writing check on %s\n\n%s\nRules: docs/PROSE.md\n' "$f" "$findings" >&2
  exit 2
fi

exit 0
