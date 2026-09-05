#!/bin/bash
# Stop hook: block a reply that is too long OR too dense to read.
#
# Length alone was the wrong measure. A previous version of this passed a reply
# on word count while the reply named ten files and commits and was unreadable.
# So this counts two things: prose lines, and distinct named things (paths,
# commands, repos) outside code blocks.
#
# Fails open: any missing input, bad JSON, or absent jq lets the turn through.
# A guard that blocks on its own bug is worse than no guard.

in=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Never block twice on one turn: the rewrite must be allowed to land.
[ "$(printf '%s' "$in" | jq -r '.stop_hook_active // false' 2>/dev/null)" = "true" ] && exit 0

msg=$(printf '%s' "$in" | jq -r '.last_assistant_message // ""' 2>/dev/null)
[ -z "$msg" ] && exit 0

# Prose only: drop fenced code blocks and blank lines. Code is free.
prose=$(printf '%s\n' "$msg" | awk '/^[[:space:]]*```/{f=!f;next} !f')
lines=$(printf '%s\n' "$prose" | grep -c '[^[:space:]]')

# Density: distinct backticked things and bare paths in the prose.
named=$(printf '%s\n' "$prose" \
  | grep -oE '`[^`]+`|\b[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+\b' \
  | sort -u | grep -c . )

# Unfinished-work gate (the other half of ECC's delivery-gate).
# A finish line is written when work starts. While it exists and is unmet, I do not
# get to stop. Deterministic: the file is there or it is not. No inference.
# Collected, not returned here: firing immediately hid the two checks below for
# as long as a finish line was armed, and since a hook only blocks once per turn
# the rewrite then went out unchecked.
FL="$HOME/.claude/.finish-line"
finish=""
if [ -f "$FL" ] && ! grep -q '^DONE:' "$FL" 2>/dev/null; then
  goal=$(head -c 400 "$FL" | tr '\n' ' ')
  finish="Work is not finished. The finish line still reads: $goal

Either cross it and append a DONE: line to ~/.claude/.finish-line saying which command proved it, or tell the user plainly what is blocking and ask. Do not stop in the middle."
fi

# Rationalization check (idea from ECC's delivery-gate).
# These phrases are how work gets declared done without being done. The list is
# deliberately narrow: ECC warns rather than blocks here because loose regex
# false-positives. A phrase only counts when the reply offers no command as proof.
# Strip quoted text first: naming a phrase is not using it. This fired on a reply
# that listed its own trigger words as examples.
unquoted=$(printf '%s\n' "$prose" | sed -E 's/"[^"]*"//g; s/\u201c[^\u201d]*\u201d//g; s/`[^`]*`//g; s/^>.*$//')
rat=$(printf '%s\n' "$unquoted" | grep -ioE "skip(ping)? (the )?tests? for now|pre-existing (bug|issue|failure)|should (work|be fine)|good enough for now|out of scope for this|will fix (that )?later|leaving that as is|assuming (this|that|it) works" | sort -u | head -3)
excuse=""
if [ -n "$rat" ] && ! printf '%s\n' "$msg" | grep -qE '^\s*(\$|>|`)?\s*(git|npm|node|python3|bash|jq|pytest|curl|ls|grep) '; then
  excuse="This reply excuses something without proving it: \"$(printf '%s' "$rat" | tr '\n' ';')\". Either run the command that settles it and show the output, or say plainly that you did not check. Do not ship the excuse."
fi

# Jargon check. He told me twice he cannot follow what I say. Short sentences were
# never the problem; these words were. A word here only counts in plain prose:
# backticks and quotes are already stripped above, so naming a command is fine.
jargon=$(printf '%s\n' "$unquoted" | grep -ioE "\\b(marketplace|symlink|frontmatter|subagent|idempotent|deep-merge[ds]?|regex|stdout|stderr|monorepo|tokeni[sz]er|LSP|MCP)\\b" | tr 'A-Z' 'a-z' | sort -u | head -4)
jarg=""
if [ -n "$jargon" ]; then
  jarg="These words need the reader to have read a file: $(printf '%s' "$jargon" | tr '\n' ' '). Say what the thing does instead. Use the real name only if he must type it, and say what it does in the same sentence."
fi

# Long sentences. The rule says under 20 words. A sentence is text ending in . ? or !
# Table rows, list markers and headings are not sentences, so drop those lines first.
sentences=$(printf '%s\n' "$prose" \
  | grep -vE '^[[:space:]]*([|#*+-]|[0-9]+\.)' \
  | tr '\n' ' ' | sed -E 's/([.?!])[[:space:]]+/\1\n/g')
long=$(printf '%s\n' "$sentences" | awk '{if(NF>20)c++} END{print c+0}')
# Coach, do not just count: show the worst sentence and where to cut it.
worst=$(printf '%s\n' "$sentences" | awk '{if(NF>n){n=NF;s=$0}} END{print s}')
worst_n=$(printf '%s' "$worst" | wc -w | tr -d ' ')
cut_at=$(printf '%s' "$worst" | grep -oiE '\b(and|but|because|so|which|that|while|when)\b' | head -1)

# Bullets with no table. Four facts in a row read better as a table.
# A bullets-into-a-table check lived here. It was removed. Two versions of it
# blocked good replies: numbered steps, then any bullet starting "Note:".
# Whether a list is really a table is a judgement, and a regex cannot make it.

max_lines=${REPLY_MAX_LINES:-15}
max_named=${REPLY_MAX_NAMED:-6}

reason=""
[ "$lines" -gt "$max_lines" ] && reason="$lines prose lines (limit $max_lines)"
if [ "$named" -gt "$max_named" ]; then
  [ -n "$reason" ] && reason="$reason and "
  reason="${reason}$named distinct named things (limit $max_named)"
fi
if [ "$long" -gt 0 ]; then
  [ -n "$reason" ] && reason="$reason and "
  reason="${reason}$long sentence(s) over 20 words"
fi

# Coaching: one line per fault, saying what to do, not just what is wrong.
coach=""
add_coach(){ [ -n "$coach" ] && coach="$coach
"; coach="$coach- $1"; }

[ "$lines" -gt "$max_lines" ] && add_coach "Cut to the answer. Delete the working, the recap and the closing line."
[ "$named" -gt "$max_named" ] && add_coach "Too many names. Keep the two that matter in prose. Put the rest in one code block."
if [ "$long" -gt 0 ]; then
  if [ -n "$cut_at" ]; then
    add_coach "Longest sentence is $worst_n words. Cut it at \"$cut_at\" and make two sentences."
  else
    add_coach "Longest sentence is $worst_n words. Say the main point, then start a new sentence."
  fi
  add_coach "It starts: \"$(printf '%s' "$worst" | cut -c1-70)...\""
fi

shape=""
if [ -n "$reason" ]; then
  shape="Reply is $reason. Fix it:
$coach

Answer first. Code blocks are free."
fi

# One message carrying whatever fired, so no check masks another.
out=""
for part in "$excuse" "$jarg" "$shape" "$finish"; do
  [ -z "$part" ] && continue
  [ -n "$out" ] && out="$out

"
  out="$out$part"
done
[ -z "$out" ] && exit 0

jq -n --arg r "$out" '{decision:"block", reason:$r}'
