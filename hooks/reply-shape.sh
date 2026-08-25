#!/bin/bash
# Stop hook. Blocks a reply the owner cannot read. Two gates, computed independently.
#
# WHY THERE ARE NOW TWO. The output style `output-styles/plain.md` carries six rules. This hook
# used to check exactly one of them, rule 2 (word count), and its header said so proudly: the
# other five need judgement, and a script that guesses at them fires on legitimate answers and
# gets switched off. Codex ruled on that at the second plan gate and it still stands.
#
# What changed on 2026-08-25 is that the owner read a session of replies that all PASSED the
# word count and said "I still cant understand a damn thing". Length was never the complaint.
# The replies were short and dense with file paths, commit ids and tool names, which is rule 6
# of the style ("name the real thing plainly, then the filename") going unenforced.
#
# Counting how many distinct technical references a reply drops on the reader needs no
# judgement at all, which is what makes it a legal check here by the hook's own standard. It
# does NOT try to detect jargon words like "payload" or "regex"; that would be judgement, and
# Codex named it as such. It counts references to THINGS: files, paths and commit ids.
#
# THE CAP IS MEASURED, NOT CHOSEN. Codex's blocking finding on the first draft was that a cap
# of four was asserted rather than calibrated. Counted against five real replies from the
# session that produced the complaint:
#
#   the reply the owner could not read                     10 references
#   the two replies they could read                         0 and 1
#   a reply whose commands are all inside a fenced block     0
#   a paragraph of ordinary English ("defaced", "facade")    0
#
# Three sits clear of both sides. It is a ratchet on the shape of an answer, not a target.
#
# WHY BACKTICKS ARE REQUIRED FOR A COMMIT ID. The first draft also counted bare 7-to-40
# character hex words, to catch a commit id written without backticks. `defaced` is seven
# characters and every one of them is a hex digit, and so are `facade`, `decade` and `beaded`.
# Codex caught it; a test below keeps it caught.
#
# ESCAPES, all deterministic, and the two gates do NOT share them. That is the point: a reply
# can be legitimately long and still unreadable, and the first draft let a fenced code block
# switch off both gates at once.
#   Length: a fenced code block or `<!-- long -->` exempts outright. A markdown table raises
#     the cap to the hard one. Tables are the shape the owner asked for by name, so they get
#     room, but a 900-word table is still a wall.
#   References: fenced blocks are REMOVED before counting rather than exempting the reply,
#     because code must stay exact and unlimited while the prose around it must still be
#     readable. `<!-- terms -->` exempts, for the rare answer that genuinely names many files.
#
# BOTH FAILURES ARE REPORTED TOGETHER. Reporting one, being corrected, then reporting the
# other is the loop that gets a hook switched off.
#
# FAILS OPEN. No input, unparseable input, a missing reply, or an unbalanced fence exits 0. A
# gate on every single turn that guesses wrong is worse than no gate.
#
# BASH-3.2 CLEAN (stock macOS): no associative arrays, no case-changing expansions.
set -uo pipefail

SOFT_CAP="${REPLY_SOFT_CAP:-150}"   # plain prose ceiling
HARD_CAP="${REPLY_HARD_CAP:-600}"   # ceiling even with a table present
REF_CAP="${REPLY_REF_CAP:-3}"       # distinct files, paths and commit ids named in prose

# The caps are overridable by environment variable, so they are inputs and get validated like
# any other. A non-numeric value would reach `-gt`, print a shell error into the session, and
# wave the reply through while looking like it had been checked.
case "$SOFT_CAP" in ''|*[!0-9]*) SOFT_CAP=150 ;; esac
case "$HARD_CAP" in ''|*[!0-9]*) HARD_CAP=600 ;; esac
case "$REF_CAP"  in ''|*[!0-9]*) REF_CAP=3   ;; esac

input="$(cat 2>/dev/null || true)"
[ -n "$input" ] || exit 0

# Pull the assistant's reply out of the hook payload. Tries each key in turn; the harness has
# used more than one name for it.
reply="$(printf '%s' "$input" | LC_ALL=C awk '
function ws(c){return c==" "||c=="\t"||c=="\n"||c=="\r"}
function fv(s,key,   p,i,n,c,o,e){
  p="\"" key "\""; i=index(s,p); if(i==0) return ""
  i+=length(p); n=length(s)
  while(i<=n){ if(ws(substr(s,i,1))) i++; else break }
  if(substr(s,i,1)!=":") return ""
  i++
  while(i<=n){ if(ws(substr(s,i,1))) i++; else break }
  if(substr(s,i,1)!="\"") return ""
  i++; o=""; e=0
  while(i<=n){
    c=substr(s,i,1)
    if(e){ o=o c; e=0; i++; continue }
    if(c=="\\"){ o=o c; e=1; i++; continue }
    if(c=="\"") break
    o=o c; i++
  }
  return o
}
{ d = d $0 }
END{
  split("last_assistant_message,assistant_response,message", ks, ",")
  for (j=1; j<=3; j++) { v=fv(d, ks[j]); if (v!="") { printf "%s", v; exit } }
}' 2>/dev/null || true)"

[ -n "$reply" ] || exit 0

# ── gate one: length ────────────────────────────────────────────────────────
fence='```'
length_msg=""
length_exempt=0
case "$reply" in
  *'<!-- long -->'*) length_exempt=1 ;;
  *"$fence"*)        length_exempt=1 ;;
esac

if [ "$length_exempt" -eq 0 ]; then
  has_table=0
  case "$reply" in
    *'|---'*|*'| ---'*) has_table=1 ;;
  esac

  # The reply arrives JSON-encoded, so a line break inside it is the two characters backslash
  # and n, not an actual newline. Left alone they glue words together and `wc -w` undercounts
  # badly: a measured ten-word, four-line reply counted as seven. Found by Codex at the review
  # gate and confirmed by running the extractor against a fixture.
  words="$(printf '%s' "$reply" | sed 's/\\n/ /g; s/\\t/ /g; s/\\r/ /g' | tr '\n' ' ' | wc -w | tr -d '[:space:]')"
  case "$words" in
    ''|*[!0-9]*) words="" ;;   # unparseable count, fail open on this gate
  esac

  if [ -n "$words" ]; then
    cap="$SOFT_CAP"
    [ "$has_table" -eq 1 ] && cap="$HARD_CAP"
    if [ "$words" -gt "$cap" ]; then
      length_msg="Reply is $words words against a $cap-word limit (output-styles/plain.md rule 2).
Cut it to the decision and the next action. Move the working to a file and name the file.
A table, a code block, or the marker <!-- long --> exempts a reply that genuinely needs the length."
    fi
  fi
fi

# ── gate two: how many things the reader has to hold ────────────────────────
refs_msg=""
refs_exempt=0
case "$reply" in
  *'<!-- terms -->'*) refs_exempt=1 ;;
esac

if [ "$refs_exempt" -eq 0 ]; then
  # Counted on the DECODED reply, because the fence logic is line-based and the payload's line
  # breaks are still two literal characters at this point.
  refs_out="$(printf '%s' "$reply" | LC_ALL=C awk '
    { gsub(/\\n/, "\n"); gsub(/\\t/, " "); gsub(/\\r/, ""); print }
  ' 2>/dev/null | LC_ALL=C awk '
    BEGIN { infence = 0; opener = ""; n = 0; unbalanced = 0 }
    # Fence toggling. Both ``` and ~~~ open and close, and the closer must be the same
    # character as the opener, so a ``` shown inside a ~~~ block does not end it.
    /^[ \t]*```/ { if (!infence) { infence = 1; opener = "`" } else if (opener == "`") { infence = 0 } ; next }
    /^[ \t]*~~~/ { if (!infence) { infence = 1; opener = "~" } else if (opener == "~") { infence = 0 } ; next }
    { if (infence) next
      rest = $0
      while (match(rest, /`[^`]+`/)) {
        tok = substr(rest, RSTART + 1, RLENGTH - 2)
        rest = substr(rest, RSTART + RLENGTH)
        gsub(/\\/, "", tok)                        # a stray escape from the JSON payload
        sub(/:[0-9]+([-,][0-9]+)?$/, "", tok)      # a trailing :142 line number
        if (tok ~ /\//) { keep(tok); continue }
        if (tok ~ /\.(sh|md|json|yml|yaml|js|mjs|txt|html|toml|py|ts)$/) { keep(tok); continue }
        # A commit id, and ONLY inside backticks: bare 7-character hex words include
        # "defaced", "facade", "decade" and "beaded".
        if (tok ~ /^[0-9a-f]{7,40}$/) { keep(tok); continue }
      }
    }
    function keep(t,   i) {
      for (i = 1; i <= n; i++) if (seen[i] == t) return
      n++; seen[n] = t
    }
    END {
      # An unclosed fence means the rest of the reply was swallowed and never counted, so the
      # count is not trustworthy and this gate stands down.
      if (infence) { print "SKIP"; exit }
      out = ""
      for (i = 1; i <= n; i++) out = out (i > 1 ? ", " : "") seen[i]
      printf "%d\t%s\n", n, out
    }' 2>/dev/null || true)"

  case "$refs_out" in
    ''|SKIP*) : ;;                       # fail open
    *)
      n_refs="${refs_out%%	*}"
      ref_list="${refs_out#*	}"
      case "$n_refs" in
        ''|*[!0-9]*) : ;;                # fail open
        *)
          if [ "$n_refs" -gt "$REF_CAP" ]; then
            refs_msg="Reply names $n_refs different files, paths or commit ids against a limit of $REF_CAP (output-styles/plain.md, the Words section).
    $ref_list
The owner is not a developer. Say what the thing IS and what it means for them, then the name once.
Move the rest to a file and name that file. Commands inside a fenced code block are not counted.
The marker <!-- terms --> exempts a reply that genuinely has to name them all."
          fi ;;
      esac ;;
  esac
fi

# ── one verdict ─────────────────────────────────────────────────────────────
# Both failures are printed together. Reporting one, being corrected, and then reporting the
# other is the correction loop that gets a hook switched off.
if [ -n "$length_msg" ] || [ -n "$refs_msg" ]; then
  [ -n "$length_msg" ] && printf '%s\n' "$length_msg" >&2
  [ -n "$refs_msg" ] && printf '%s\n' "$refs_msg" >&2
  exit 2
fi

exit 0
