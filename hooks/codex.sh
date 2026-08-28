#!/usr/bin/env bash
# The one place the Codex invocation lives. Every stage calls this.
# Usage: codex.sh [--tier <name>] "<prompt>" [output-file]
# Why each flag is here, and what each tier costs: rules/codex.md
#
# TIERS. Six jobs are automated against Codex and they are not one job. Until
# 2026-08-28 this file sent all six to gpt-5.6-sol at high effort, so the cheap
# ones paid the expensive rate. The tier decides the model and the reasoning
# effort together, because a small model at high effort and a large one at low
# effort are different trades and the caller should not have to know that.
#
# Omitting --tier keeps the old behaviour. A caller that has not been updated
# stays on the heavy tier rather than silently getting a weaker answer: this
# setup ran every call at the LOWEST effort for its whole life until 2026-08-21
# and the reviews were worse for it, so the default fails toward quality.
set -euo pipefail

if ! command -v codex >/dev/null 2>&1; then
  echo "CODEX_DID_NOT_RUN|codex is not installed"
  exit 3
fi

model="gpt-5.6-sol"
effort="high"

if [ "${1:-}" = "--tier" ]; then
  [ $# -ge 2 ] || { echo "CODEX_DID_NOT_RUN|--tier needs a name"; exit 3; }
  case "$2" in
    plan)   model="gpt-5.6-sol";   effort="xhigh"  ;;
    mockup) model="gpt-5.6-sol";   effort="low"    ;;
    review) model="gpt-5.6-terra"; effort="high"   ;;
    rival)  model="gpt-5.6-terra"; effort="medium" ;;
    tests)  model="gpt-5.6-luna";  effort="high"   ;;
    gaps)   model="gpt-5.6-luna";  effort="medium" ;;
    *) echo "CODEX_DID_NOT_RUN|unknown tier: $2 (plan mockup review rival tests gaps)"; exit 3 ;;
  esac
  shift 2
fi

prompt="${1:?usage: codex.sh [--tier <name>] \"<prompt>\" [output-file]}"
out="${2:-}"

run() {
  codex exec --sandbox read-only --skip-git-repo-check \
    -m "$model" -c model_reasoning_effort="$effort" \
    "$prompt" < /dev/null 2>&1
}

if [ -n "$out" ]; then
  run > "$out"
else
  run
fi
