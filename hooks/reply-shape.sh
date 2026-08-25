#!/bin/bash
# Stop hook. Blocks a reply that is longer than the owner can read.
#
# WHY THIS IS THE ONLY CHECK HERE. The output style `output-styles/plain.md` carries six
# rules. Five of them ("the answer is sentence one", "the decision, not the working") need
# judgement, and a script that guesses at them fires on legitimate answers and gets switched
# off. Codex ruled on exactly that at the second plan gate. So this hook checks the one thing
# a machine can decide without judgement: how many words the reply is. The other five live in
# the output style, which the model reads and is reminded of mid-session.
#
# ESCAPES, all deterministic, and they are not all the same strength.
#   Exempt outright: a fenced code block, or the marker `<!-- long -->`. Code and file
#     contents must stay exact and can be any length.
#   Raised to the hard cap: a markdown table. Tables are the shape the owner asked for by
#     name, so they get room, but not unlimited room. A 900-word table is still a wall.
# Codex found this comment claiming tables were exempt while the code raised their cap. The
# code was right and the comment was wrong; the comment is what changed.
#
# FAILS OPEN. No input, unparseable input, or a missing reply exits 0. A gate on every single
# turn that guesses wrong is worse than no gate: it would block work with no way through.
#
# BASH-3.2 CLEAN (stock macOS): no associative arrays, no case-changing expansions.
set -uo pipefail

SOFT_CAP="${REPLY_SOFT_CAP:-150}"   # plain prose ceiling
HARD_CAP="${REPLY_HARD_CAP:-600}"   # ceiling even with a table present

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

# Escapes. Any one of them exempts the reply entirely.
fence='```'
case "$reply" in
  *'<!-- long -->'*) exit 0 ;;
  *"$fence"*)        exit 0 ;;
esac

has_table=0
case "$reply" in
  *'|---'*|*'| ---'*) has_table=1 ;;
esac

# The reply arrives JSON-encoded, so a line break inside it is the two characters backslash
# and n, not an actual newline. Left alone they glue words together and `wc -w` undercounts
# badly: a measured ten-word, four-line reply counted as seven. Turn the encoded whitespace
# escapes back into spaces before counting. Found by Codex at the review gate and confirmed by
# running the extractor against a fixture.
words="$(printf '%s' "$reply" | sed 's/\\n/ /g; s/\\t/ /g; s/\\r/ /g' | tr '\n' ' ' | wc -w | tr -d '[:space:]')"
case "$words" in
  ''|*[!0-9]*) exit 0 ;;   # unparseable count, fail open
esac

# The caps are overridable by environment variable, so they are inputs and get validated like
# any other. A non-numeric value would reach `-gt`, print a shell error into the session, and
# wave the reply through while looking like it had been checked.
case "$SOFT_CAP" in ''|*[!0-9]*) SOFT_CAP=150 ;; esac
case "$HARD_CAP" in ''|*[!0-9]*) HARD_CAP=600 ;; esac

cap="$SOFT_CAP"
[ "$has_table" -eq 1 ] && cap="$HARD_CAP"

if [ "$words" -gt "$cap" ]; then
  printf 'Reply is %s words against a %s-word limit (output-styles/plain.md rule 2).\n' \
    "$words" "$cap" >&2
  printf 'Cut it to the decision and the next action. Move the working to a file and name the file.\n' >&2
  printf 'A table, a code block, or the marker <!-- long --> exempts a reply that genuinely needs the length.\n' >&2
  exit 2
fi

exit 0
