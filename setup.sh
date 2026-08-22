#!/usr/bin/env bash
# Post-clone setup for ~/.claude. Safe to run again; it never overwrites
# anything you have edited.
#
#   bash ~/.claude/setup.sh
#
# Rewritten from a blank page 2026-08-22 (machinery rebuild).
#
# WHAT IT DOES: checks the tools this setup needs and stops early with a fix
# line when a required one is missing; seeds settings.json, the deny-list and
# the memory index from their tracked templates; makes the hooks executable;
# and installs the pre-commit secret scanner into this clone's .git/hooks.
#
# WHAT IT DOES NOT DO: reach the network. Every `brew`/`curl`/`apt` string in
# this file is inside a message telling YOU what to run, never executed here.
# The optional outside tools live in INSTALL.md, and every file that reaches
# for one carries a fallback, so a machine with none of them works.
#
# BASH 3.2 CLEAN. Stock macOS ships bash 3.2 and the documented command is
# `bash setup.sh`, so a bash-4-only construct hard-blocks every un-provisioned
# Mac. verify.sh greps this file for that whole class, and its grep reads
# comments too, so they cannot be named here either.
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"

if [ "${1:-}" != "" ]; then
  echo "Unknown option: ${1}"
  echo "Usage: bash setup.sh          (no flags; optional extras are in INSTALL.md)"
  exit 2
fi

step() { printf '\n==> %s\n' "$1"; }
note() { printf '    %s\n' "$1"; }
stop() { printf '\n    ! %s\n' "$1"; shift; for l in "$@"; do printf '      %s\n' "$l"; done; exit 1; }

is_mac() { [ "$(uname -s)" = "Darwin" ]; }

# ── Preflight ───────────────────────────────────────────────────────────────
step "Preflight"

have() { command -v "$1" >/dev/null 2>&1; }

for t in git node jq python3 claude; do
  if have "$t"; then printf '    %-8s found\n' "$t"; else printf '    %-8s missing\n' "$t"; fi
done

have git || stop "git missing, and it is required: the pre-commit scanner is installed with it." \
                 "Install: see README.md Prerequisites"

# jq is not optional and not a degradation. Both guard hooks read their input
# with it, and hooks/safety-net.sh refuses EVERY command when jq is absent
# rather than waving them through, so a missing jq is a wall.
if ! have jq; then
  if is_mac; then
    stop "jq missing. The guard hooks cannot read their input without it," \
         "and safety-net.sh refuses every Bash command rather than failing open." \
         "Fix: brew install jq"
  else
    stop "jq missing. The guard hooks cannot read their input without it," \
         "and safety-net.sh refuses every Bash command rather than failing open." \
         "Fix: sudo apt install jq"
  fi
fi

if ! have node; then
  stop "node missing, so the .js hooks cannot run." "Install: https://nodejs.org/"
fi

# Node major-version gate. The .js hooks use APIs Node 18 does not have, and on
# Ubuntu 24.04 `apt install nodejs` still gives v18.
NODE_MAJOR="$(node --version 2>/dev/null | sed 's/^v//; s/[.].*//')"
case "$NODE_MAJOR" in
  ""|*[!0-9]*) : ;;   # unreadable version: let the hooks speak for themselves
  *)
    if [ "$NODE_MAJOR" -lt 20 ]; then
      if is_mac; then
        stop "node $(node --version) is too old; 20 or newer is needed (22 recommended)." \
             "Fix: brew install node@22"
      else
        stop "node $(node --version) is too old; 20 or newer is needed (22 recommended)." \
             "Fix: curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt install -y nodejs" \
             "(Ubuntu's own 'apt install nodejs' is v18 and will not work)"
      fi
    fi
    ;;
esac

have claude || note "! claude (Claude Code) not on PATH: https://docs.anthropic.com/en/docs/claude-code"

if have codex; then
  note "codex    found (the second-model check will run)"
else
  note "codex    not installed; the second-model check reports itself unrun. See rules/codex.md"
fi

# ── Templates ───────────────────────────────────────────────────────────────
# Every seed is create-if-absent. Re-running this must never overwrite a file
# you have edited, which is what makes the script safe to repeat.
step "Templates"

seed() {  # $1 template, $2 destination, $3 description
  if [ -f "$2" ]; then
    note "$(basename "$2") already exists, left alone"
  elif [ -f "$1" ]; then
    cp "$1" "$2"
    note "Created $(basename "$2") from $(basename "$1") ($3)"
  fi
}

seed "$CLAUDE_DIR/settings.example.json" "$CLAUDE_DIR/settings.json" "yours, and gitignored"
seed "$CLAUDE_DIR/.no-yolo-deny.example.txt" "$CLAUDE_DIR/.no-yolo-deny.txt" "add your private terms"

if [ ! -f "$CLAUDE_DIR/memory/MEMORY.md" ] && [ -f "$CLAUDE_DIR/memory/MEMORY.example.md" ]; then
  mkdir -p "$CLAUDE_DIR/memory/facts"
  cp "$CLAUDE_DIR/memory/MEMORY.example.md" "$CLAUDE_DIR/memory/MEMORY.md"
  note "Created memory/MEMORY.md and memory/facts/ (both gitignored)"
else
  note "memory/MEMORY.md already exists, left alone"
fi

# ── Hooks ───────────────────────────────────────────────────────────────────
step "Hooks"

if ls "$CLAUDE_DIR"/hooks/*.sh >/dev/null 2>&1; then
  chmod +x "$CLAUDE_DIR"/hooks/*.sh
  note "Hook scripts made executable"
fi

# git never copies a tracked hook into .git/hooks on its own, so without this a
# fresh clone of a PUBLIC repo would commit with NO secret scanning at all.
# verify.sh check 8c compares the installed copy against the tracked source and
# goes red when they drift, which is what catches a stale copy later.
if [ -f "$CLAUDE_DIR/hooks/pre-commit" ] && git -C "$CLAUDE_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  HOOKS_DIR="$(git -C "$CLAUDE_DIR" rev-parse --git-path hooks)"
  case "$HOOKS_DIR" in /*) : ;; *) HOOKS_DIR="$CLAUDE_DIR/$HOOKS_DIR" ;; esac
  mkdir -p "$HOOKS_DIR"
  cp "$CLAUDE_DIR/hooks/pre-commit" "$HOOKS_DIR/pre-commit"
  chmod +x "$HOOKS_DIR/pre-commit"
  note "Installed the pre-commit secret scanner into $HOOKS_DIR"
else
  note "No git dir or hooks/pre-commit, so the scanner install was skipped"
fi

# ── Done ────────────────────────────────────────────────────────────────────
step "Done."
echo ""
note "Check it:  bash $CLAUDE_DIR/verify.sh    (every row should read PASS)"
note "Then open Claude Code anywhere and type /checkup."
note "Optional extras, and the command that installs them: INSTALL.md"
echo ""
