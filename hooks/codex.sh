#!/usr/bin/env bash
# The one place the Codex invocation lives. Every stage calls this.
# Usage: codex.sh "<prompt>" [output-file]
# Why each flag is here: rules/codex.md
set -euo pipefail

if ! command -v codex >/dev/null 2>&1; then
  echo "CODEX_DID_NOT_RUN|codex is not installed"
  exit 3
fi

prompt="${1:?usage: codex.sh \"<prompt>\" [output-file]}"
out="${2:-}"

run() {
  codex exec --sandbox read-only --skip-git-repo-check "$prompt" < /dev/null 2>&1
}

if [ -n "$out" ]; then
  run > "$out"
else
  run
fi
