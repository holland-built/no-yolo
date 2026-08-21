#!/usr/bin/env bash
# setup.sh — post-clone setup for ~/.claude (no-yolo). Safe to run again.
#
# Usage:
#   bash ~/.claude/setup.sh
#
# What it does: checks the tools this setup needs, seeds settings.json and the
# deny-list from their templates, makes the hooks executable, and installs the
# pre-commit secret scanner into this clone.
#
# What it does NOT do: install anything from the internet. The rebuild of
# 2026-08-21 moved that out. Seven optional outside tools are listed in
# INSTALL.md with one command that installs all of them, and every file that
# reaches for one carries a fallback, so a machine with none of them works.
#
# Two flags were removed in the same rebuild:
#   --md-only    stripped @imports out of CLAUDE.md. CLAUDE.md has no imports
#                now, and the flag kept a pristine copy at CLAUDE.md.pre-md-only
#                that a later full run would move back over the current file. A
#                stale copy from before the rebuild would have silently restored
#                the old thirty-five-rule setup.
#   --core-only  skipped the third-party installs, which no longer happen here.
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"

if [ "${1:-}" != "" ]; then
  echo "Unknown option: ${1}"
  echo "Usage: bash setup.sh          (no flags; optional extras are in INSTALL.md)"
  exit 2
fi

# ── Preflight: tool availability ─────────────────────────────────────────────
echo "==> Preflight"
# NOTE: nothing bash-4-only in this file. Stock macOS ships bash 3.2 and the
# documented install command is `bash setup.sh`, so associative arrays, line-reading
# builtins and case-changing expansions are all out. verify.sh enforces this by
# grepping for them, and the grep reads comments too, so they cannot be named here
# either.
PRE_TOOLS="git node jq python3 claude"
PRE_MISSING=" "
for t in $PRE_TOOLS; do
  if command -v "$t" >/dev/null 2>&1; then
    printf "    %-8s found\n" "$t"
  else
    PRE_MISSING="${PRE_MISSING}${t} "
    printf "    %-8s missing\n" "$t"
  fi
done

pre_missing() { case "$PRE_MISSING" in *" $1 "*) return 0;; *) return 1;; esac; }

if pre_missing git; then
  echo ""
  echo "    ! git missing — required: the pre-commit secret-scanner install needs it."
  echo "      Install: see README.md Prerequisites"
  exit 1
fi

# jq is not optional. Both guard hooks read their input with it, and
# hooks/safety-net.sh refuses every command when jq is absent rather than
# waving them through, so a missing jq is a wall, not a degradation.
if pre_missing jq; then
  echo ""
  echo "    ! jq missing — the two guard hooks cannot read their input without it,"
  echo "      and safety-net.sh refuses every Bash command rather than failing open."
  if [ "$(uname -s)" = "Darwin" ]; then
    echo "      Fix: brew install jq"
  else
    echo "      Fix: sudo apt install jq"
  fi
  exit 1
fi

# Node MAJOR version gate. The .js hooks run under it, and Node 18 is missing
# APIs they use. On Ubuntu 24.04 `apt install nodejs` still gives v18.
if ! pre_missing node; then
  NODE_MAJOR="$(node --version 2>/dev/null | sed 's/^v//; s/[.].*//')"
  case "$NODE_MAJOR" in
    ""|*[!0-9]*) : ;;   # unreadable version — let the hooks speak for themselves
    *)
      if [ "$NODE_MAJOR" -lt 20 ]; then
        echo ""
        echo "    ! node $(node --version) is too old — need 20 or newer (22 recommended)."
        if [ "$(uname -s)" = "Darwin" ]; then
          echo "      Fix: brew install node@22"
        else
          echo "      Fix: curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt install -y nodejs"
          echo "           (Ubuntu's own 'apt install nodejs' is v18 and will not work)"
        fi
        exit 1
      fi
      ;;
  esac
else
  echo ""
  echo "    ! node missing — the .js hooks will not run. Install: https://nodejs.org/"
  exit 1
fi

if pre_missing claude; then
  echo "    ! claude (Claude Code) not found on PATH — install: https://docs.anthropic.com/en/docs/claude-code"
fi

if command -v codex >/dev/null 2>&1; then
  echo "    codex    found (the second-model check will run)"
else
  echo "    codex    not installed — the second-model check reports itself as unrun; see rules/codex.md"
fi

# ── 1. settings.json ─────────────────────────────────────────────────────────
echo ""
echo "==> 1. settings.json"
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  echo "    settings.json already exists — left alone"
else
  cp "$CLAUDE_DIR/settings.example.json" "$CLAUDE_DIR/settings.json"
  echo "    Created settings.json from settings.example.json"
fi

# ── 2. hooks ─────────────────────────────────────────────────────────────────
echo ""
echo "==> 2. Hooks"
if ls "$CLAUDE_DIR"/hooks/*.sh >/dev/null 2>&1; then
  chmod +x "$CLAUDE_DIR"/hooks/*.sh
  echo "    Hook scripts made executable"
else
  echo "    No hook scripts found — skipping"
fi

# Install the tracked pre-commit hook into this clone's .git/hooks. Without this,
# a fresh clone of a PUBLIC repo commits with NO secret scanning. The source is
# tracked at hooks/pre-commit; git never copies it into .git/hooks on its own.
if [ -f "$CLAUDE_DIR/hooks/pre-commit" ] && git -C "$CLAUDE_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  HOOKS_DIR="$(git -C "$CLAUDE_DIR" rev-parse --git-path hooks)"
  # rev-parse may return a path relative to CLAUDE_DIR
  case "$HOOKS_DIR" in /*) : ;; *) HOOKS_DIR="$CLAUDE_DIR/$HOOKS_DIR" ;; esac
  mkdir -p "$HOOKS_DIR"
  cp "$CLAUDE_DIR/hooks/pre-commit" "$HOOKS_DIR/pre-commit"
  chmod +x "$HOOKS_DIR/pre-commit"
  echo "    Installed the pre-commit secret scanner into $HOOKS_DIR"
else
  echo "    No git dir or hooks/pre-commit — skipping the scanner install"
fi

# Seed the local (gitignored) deny-list from the template if absent, so the
# mechanism is discoverable on a fresh install. Never overwrites an existing one.
if [ -f "$CLAUDE_DIR/.no-yolo-deny.example.txt" ] && [ ! -f "$CLAUDE_DIR/.no-yolo-deny.txt" ]; then
  cp "$CLAUDE_DIR/.no-yolo-deny.example.txt" "$CLAUDE_DIR/.no-yolo-deny.txt"
  echo "    Seeded .no-yolo-deny.txt from its template (edit it for your private terms)"
fi

# ── 3. memory index ──────────────────────────────────────────────────────────
echo ""
echo "==> 3. Memory index"
if [ -f "$CLAUDE_DIR/memory/MEMORY.md" ]; then
  echo "    memory/MEMORY.md already exists — left alone"
else
  mkdir -p "$CLAUDE_DIR/memory/facts"
  cp "$CLAUDE_DIR/memory/MEMORY.example.md" "$CLAUDE_DIR/memory/MEMORY.md"
  echo "    Created memory/MEMORY.md from its template (gitignored, like memory/facts/)"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "==> Done."
echo ""
echo "    Check it: bash $CLAUDE_DIR/verify.sh    (every row should read PASS)"
echo "    Then open Claude Code anywhere and type /checkup."
echo ""
echo "    Optional extras, and the one command that installs all seven: INSTALL.md"
