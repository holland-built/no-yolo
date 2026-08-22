#!/bin/bash
# The line at the bottom of every Claude Code session.
# Reads the statusLine JSON on stdin; prints one ANSI-coloured line; exits 0.
#
# Rewritten from a blank page 2026-08-22 as part of the machinery rebuild the
# owner ordered (docs/DECISIONS.md records the order). The contract it must meet
# is hooks/tests/statusline.test.sh, written the day before by a different
# session against the observed behaviour, so the referee predates this text.
#
# Segments, left to right, each dropped when its datum is absent:
#   LITERAL badge · model + effort + thinking mark · ctx% · 5h allowance ·
#   weekly allowance · work profile dot · folder(+dirty *) · environment
#
# Two hard rules, both asserted by the test:
#   - It never fails and never blocks. Whatever arrives on stdin, a bar comes
#     out and the exit code is 0. A statusline that errors prints its stack
#     under the prompt on every keystroke, and nobody reports it.
#   - Nothing on stderr on the ordinary path, for the same reason.

INPUT=$(cat)

# The literal-mode badge comes from the sibling script, found relative to THIS
# file. A $HOME-anchored path was the old defect: under a second config profile
# ($CLAUDE_CONFIG_DIR pointing elsewhere) it read the personal profile's mode
# onto the work bar. Siblings ship together; a sibling lookup cannot miss.
BADGE=$(bash "$(dirname "${BASH_SOURCE[0]}")/literal-statusline.sh" 2>/dev/null)

# Everything the JSON can tell us, extracted in ONE python pass that prints
# shell-safe NAME=VALUE lines. The previous design piped a \x1f-joined record
# into a bash `read` with positional placeholder variables that existed only to
# land later fields in the right slots; deriving assignments instead removes the
# placeholders and the field-order coupling in one move.
eval "$(printf '%s' "$INPUT" | python3 -c '
import json, sys, time, shlex

def emit(name, value):
    print(f"{name}={shlex.quote(str(value))}")

try:
    d = json.load(sys.stdin)
    if not isinstance(d, dict):
        raise ValueError
except Exception:
    # Malformed or empty input still draws a bar naming a model. The harness
    # sends nothing during startup; a vanishing bar is how breakage hides.
    emit("S_MODEL", "Claude")
    for k in ("S_CWD","S_EFFORT","S_THINK","S_CTX","S_5H","S_WK"):
        emit(k, "")
    sys.exit(0)

ws    = d.get("workspace") or {}
model = d.get("model") or {}

emit("S_CWD",   ws.get("current_dir") or d.get("cwd") or "")
emit("S_MODEL", model.get("display_name") or "Claude")

effort = (d.get("effort") or {}).get("level") or ""
if effort in ("default", "null", "None"):
    effort = ""
emit("S_EFFORT", effort)
emit("S_THINK", "think" if (d.get("thinking") or {}).get("enabled") else "")

used = (d.get("context_window") or {}).get("used_percentage")
emit("S_CTX", f"{round(used)}%" if used is not None else "")

def allowance(bucket):
    b = bucket or {}
    pct = b.get("used_percentage")
    if pct is None:
        return ""
    left = ""
    resets = b.get("resets_at")
    if resets:
        s = int(resets) - int(time.time())
        if s <= 0:            left = "now"
        elif s >= 86400:      left = f"{s // 86400}d"
        elif s >= 3600:       left = f"{s // 3600}h"
        else:                 left = f"{s // 60}m"
    return f"{round(pct)}% {left}".rstrip()

limits = d.get("rate_limits") or {}
emit("S_5H", allowance(limits.get("five_hour")))
emit("S_WK", allowance(limits.get("seven_day")))
' 2>/dev/null)" 2>/dev/null

# Defaults for the impossible case where the extractor itself produced nothing:
# a bar still appears and still names a model.
: "${S_MODEL:=Claude}" "${S_CWD:=}" "${S_EFFORT:=}" "${S_THINK:=}"
: "${S_CTX:=}" "${S_5H:=}" "${S_WK:=}"

# Git state for the folder segment. Errors (not a repo, no git) mean no branch
# and no dirty mark, silently.
FOLDER=""
DIRTY=""
BRANCH=""
if [ -n "$S_CWD" ]; then
  FOLDER=$(basename "$S_CWD")
  BRANCH=$(git -C "$S_CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$BRANCH" ] && [ -n "$(git -C "$S_CWD" status --porcelain 2>/dev/null)" ]; then
    DIRTY="*"
  fi
fi

# Which config profile is live. Only the non-default one earns a segment: the
# personal bar stays quiet, the work bar says so.
PROFILE=""
case "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" in
  *claude-work*) PROFILE="work" ;;
esac

# Environment: an env var wins; otherwise the branch name maps to a label.
ENV_LABEL="${APP_ENV:-${DEPLOY_ENV:-${ENVIRONMENT:-${ENV:-$NODE_ENV}}}}"
if [ -z "$ENV_LABEL" ]; then
  case "$BRANCH" in
    main|master|prod|production) ENV_LABEL="prod" ;;
    stag*)                       ENV_LABEL="staging" ;;
    dev|develop|development)     ENV_LABEL="dev" ;;
    ""|HEAD)                     ENV_LABEL="" ;;
    *)                           ENV_LABEL="$BRANCH" ;;
  esac
fi
case "$ENV_LABEL" in
  prod*) ENV_COLOR="38;5;203" ;;   # red: you are somewhere mistakes travel
  stag*) ENV_COLOR="38;5;215" ;;   # amber
  dev*)  ENV_COLOR="38;5;114" ;;   # green
  *)     ENV_COLOR="38;5;75"  ;;   # blue: an unmapped branch name
esac

# Composition. seg() appends one coloured piece with the dot separator, so the
# join logic lives in one place instead of on every line.
GREY="38;5;245"
SEP="\033[38;5;240m · \033[0m"
OUT=""
seg() {  # $1 colour  $2 text
  [ -z "$2" ] && return 0
  [ -n "$OUT" ] && OUT="${OUT}${SEP}"
  OUT="${OUT}\033[${1}m${2}\033[0m"
}

[ -n "$BADGE" ] && { [ -n "$OUT" ] && OUT="${OUT}${SEP}"; OUT="${OUT}${BADGE//\[LITERAL\]/LITERAL}"; }

MODEL_TEXT="${S_MODEL//_/ }"
[ -n "$S_EFFORT" ] && MODEL_TEXT="${MODEL_TEXT} ${S_EFFORT}"
[ -n "$S_THINK" ]  && MODEL_TEXT="${MODEL_TEXT} ✦"
seg "$GREY" "$MODEL_TEXT"

[ -n "$S_CTX" ] && seg "$GREY" "${S_CTX}ctx"
[ -n "$S_5H" ]  && seg "$GREY" "5h ${S_5H}"
[ -n "$S_WK" ]  && seg "$GREY" "wk ${S_WK}"
[ -n "$PROFILE" ] && seg "38;5;215" "● ${PROFILE}"
[ -n "$FOLDER" ]  && seg "38;5;255" "${FOLDER}${DIRTY}"
[ -n "$ENV_LABEL" ] && seg "$ENV_COLOR" "⬢ ${ENV_LABEL}"

printf '%b' "$OUT"
exit 0
