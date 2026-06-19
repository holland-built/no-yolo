#!/bin/bash
# Custom statusline for Claude Code.
# Shows: caveman badge · context% · model · cwd · git branch
# Reads the statusLine JSON from stdin.

INPUT=$(cat)
printf '%s' "$INPUT" > "/tmp/sl-stdin-$(echo "$INPUT" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("workspace",{}).get("current_dir","x").split("/")[-1])' 2>/dev/null).json"

# --- caveman badge (reuse hardened script) ---
CAVE=$(bash "$HOME/.claude/hooks/caveman-statusline.sh" 2>/dev/null)

# --- parse stdin JSON (tab-delimited so paths with spaces survive) ---
IFS=$'\x1f' read -r CWD MODEL_ID MODEL_NAME TRANSCRIPT COST REASON THINK CTX FIVEH WK <<EOF
$(printf '%s' "$INPUT" | python3 -c '
import json,sys,time
SEP="\x1f"
try:
    d=json.load(sys.stdin)
except Exception:
    print(SEP.join([".","unknown","Claude",".","0","","","","",""])); sys.exit(0)
ws=d.get("workspace",{}) or {}
m=d.get("model",{}) or {}
c=d.get("cost",{}) or {}
cwd=ws.get("current_dir") or d.get("cwd") or "."
# reasoning effort: prefer effort.level, then legacy fallbacks
eff=(d.get("effort",{}) or {})
reason=(eff.get("level") or m.get("reasoning_effort") or d.get("reasoning_effort")
        or (d.get("output_style",{}) or {}).get("name") or "")
if reason in ("default","null","None"): reason=""
think="think" if (d.get("thinking",{}) or {}).get("enabled") else ""
# context window: % used
cw=(d.get("context_window",{}) or {})
up=cw.get("used_percentage")
ctx=f"{round(up)}%" if up is not None else ""
# rate limits: % used + reset countdown
def reset(ep):
    if not ep: return ""
    s=int(ep)-int(time.time())
    if s<=0: return "now"
    if s>=86400: return f"{s//86400}d"
    if s>=3600: return f"{s//3600}h"
    return f"{s//60}m"
def lim(o):
    o=o or {}
    p=o.get("used_percentage")
    if p is None: return ""
    r=reset(o.get("resets_at"))
    return f"{round(p)}% {r}" if r else f"{round(p)}%"
rl=(d.get("rate_limits",{}) or {})
fiveh=lim(rl.get("five_hour"))
wk=lim(rl.get("seven_day"))
print(SEP.join([cwd, m.get("id","unknown"), m.get("display_name","Claude"),
                d.get("transcript_path","."), str(c.get("total_cost_usd",0) or 0),
                reason, think, ctx, fiveh, wk]))
')
EOF

# --- cwd basename ---
DIR=$(basename "$CWD")

# --- git branch + dirty flag ---
BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
DIRTY=""
if [ -n "$BRANCH" ] && [ -n "$(git -C "$CWD" status --porcelain 2>/dev/null)" ]; then
  DIRTY="*"
fi

# --- cost: format "$0.42", blank when zero/absent ---
COSTSTR=""
if [ -n "$COST" ]; then
  COSTSTR=$(COST="$COST" python3 -c 'import os; c=float(os.environ.get("COST") or 0); print(f"${c:.2f}" if c>0 else "")' 2>/dev/null)
fi

# --- cc-whoami: active config profile (work vs personal) ---
CC_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
case "$CC_DIR" in
  *claude-work*) WHO_LABEL="work";     WHO_COLOR="38;5;215" ;;  # amber
  *)             WHO_LABEL="personal"; WHO_COLOR="38;5;114" ;;  # green
esac

# --- model: full display name + optional reasoning effort ---
MODEL_SEG="${MODEL_NAME//_/ }"
[ -n "$REASON" ] && MODEL_SEG="${MODEL_SEG} ${REASON}"
[ -n "$THINK" ] && MODEL_SEG="${MODEL_SEG} ✦"

# --- environment: env var first, else map git branch ---
ENV_RAW="${APP_ENV:-${DEPLOY_ENV:-${ENVIRONMENT:-${ENV:-$NODE_ENV}}}}"
if [ -z "$ENV_RAW" ]; then
  case "$BRANCH" in
    main|master|prod|production) ENV_RAW="prod" ;;
    stag*|staging)               ENV_RAW="staging" ;;
    dev|develop|development)     ENV_RAW="dev" ;;
    ""|HEAD)                     ENV_RAW="" ;;
    *)                           ENV_RAW="$BRANCH" ;;
  esac
fi
case "$ENV_RAW" in
  prod*|production) ENV_COLOR="38;5;203" ;;  # red
  stag*)            ENV_COLOR="38;5;215" ;;  # amber
  dev*)             ENV_COLOR="38;5;114" ;;  # green
  *)                ENV_COLOR="38;5;75"  ;;  # blue
esac

# --- compose: caveman · model · work · folder · env ---
SEP="\033[38;5;240m · \033[0m"
# caveman badge: strip [brackets], match plain font (keep amber color)
CAVE_TXT="${CAVE//\[CAVEMAN\]/CAVEMAN}"
OUT=""
[ -n "$CAVE_TXT" ] && OUT="${CAVE_TXT}${SEP}"
OUT="${OUT}\033[38;5;245m${MODEL_SEG}\033[0m"
[ -n "$CTX" ]   && OUT="${OUT}${SEP}\033[38;5;245m${CTX}ctx\033[0m"
[ -n "$FIVEH" ] && OUT="${OUT}${SEP}\033[38;5;245m5h ${FIVEH}\033[0m"
[ -n "$WK" ]    && OUT="${OUT}${SEP}\033[38;5;245mwk ${WK}\033[0m"
[ "$WHO_LABEL" = "work" ] && OUT="${OUT}${SEP}\033[${WHO_COLOR}m● ${WHO_LABEL}\033[0m"
OUT="${OUT}${SEP}\033[38;5;255m${DIR}${DIRTY}\033[0m"
[ -n "$ENV_RAW" ] && OUT="${OUT}${SEP}\033[${ENV_COLOR}m⬢ ${ENV_RAW}\033[0m"

printf '%b' "$OUT"
