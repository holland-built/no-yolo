#!/bin/sh
# Install or update no-yolo on this machine. Safe to run again: it backs up what
# it is about to replace, and skips anything already in place.
set -eu

REPO=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CLAUDE="$HOME/.claude"

say() { printf '%s\n' "$*"; }

# settings.json runs the codex reaper from this exact path.
if [ "$REPO" != "$HOME/AI/no-yolo" ]; then
  say "Note: this clone is at $REPO, not $HOME/AI/no-yolo."
  say "The session-start hook in settings.json looks for the second path and will"
  say "fail until you move the clone or edit that line."
fi

# 1. Back up, so there is a way back from the copy below.
if [ -d "$CLAUDE" ]; then
  BACKUP="$HOME/.claude-backup-$(date +%Y%m%d-%H%M%S)"
  # copy the contents, not the folder: ~/.claude is sometimes a link, and copying
  # the link would give you a backup pointing at the files about to be replaced.
  mkdir -p "$BACKUP"
  cp -R "$CLAUDE/." "$BACKUP/"
  say "Backed up your old setup to $BACKUP"
fi

# 2. Copy the rules, the style, the skills and the checker's rules in.
mkdir -p "$CLAUDE/skills" "$CLAUDE/output-styles" "$CLAUDE/shared"
cp "$REPO/CLAUDE.md" "$REPO/settings.json" "$REPO/statusline.sh" "$CLAUDE/"
cp -R "$REPO/skills/." "$CLAUDE/skills/"
cp -R "$REPO/output-styles/." "$CLAUDE/output-styles/"
# CLAUDE.md imports shared/AGENTS.md, the rules Claude and Codex both follow.
cp -R "$REPO/shared/." "$CLAUDE/shared/"
chmod +x "$CLAUDE/shared/build-codex-agents.sh"
chmod +x "$CLAUDE/statusline.sh"
say "Copied the rules, style, skills and checker into $CLAUDE"

# Codex has no file import, so if it is installed, build its rules file from the shared one.
if command -v codex >/dev/null 2>&1; then
  if [ -f "$HOME/.codex/AGENTS.md" ]; then
    cp "$HOME/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md.backup-$(date +%Y%m%d-%H%M%S)"
    say "Backed up your old ~/.codex/AGENTS.md next to it"
  fi
  if "$CLAUDE/shared/build-codex-agents.sh"; then
    say "Codex now follows the same shared rules"
  else
    say "Could not build ~/.codex/AGENTS.md. Run ~/.claude/shared/build-codex-agents.sh to retry."
  fi
fi

# 3. Install gitleaks, which the secret guard calls. Without it the guard does nothing.
if command -v gitleaks >/dev/null 2>&1; then
  say "gitleaks already installed: $(gitleaks version 2>&1 | head -1)"
elif command -v brew >/dev/null 2>&1; then
  brew install gitleaks || say "brew could not install gitleaks. The guard stays off until it is."
elif command -v apk >/dev/null 2>&1; then
  # these need root, and this script does not ask for it. A failure here must not
  # stop the rest of the setup, so say what to run and carry on.
  apk add gitleaks || say "Installing gitleaks needs root. Run: sudo apk add gitleaks"
elif command -v apt-get >/dev/null 2>&1; then
  apt-get install -y gitleaks || say "Installing gitleaks needs root. Run: sudo apt-get install gitleaks"
else
  say "Could not install gitleaks: no brew, apk or apt-get here."
  say "Take the binary for your machine from https://github.com/gitleaks/gitleaks/releases"
  say "and put it on your PATH. Until you do, the secret guard lets everything through."
fi

# 3b. Install exiftool, which /github-readme uses to strip hidden data (device, date, location)
# from screenshots before they are published. Only that step needs it, so a failure is a note.
if command -v exiftool >/dev/null 2>&1; then
  say "exiftool already installed: $(exiftool -ver)"
elif command -v brew >/dev/null 2>&1; then
  brew install exiftool || say "brew could not install exiftool. Install it before /github-readme publishes a screenshot."
elif command -v apk >/dev/null 2>&1; then
  apk add exiftool || say "Installing exiftool needs root. Run: sudo apk add exiftool"
elif command -v apt-get >/dev/null 2>&1; then
  apt-get install -y libimage-exiftool-perl || say "Installing exiftool needs root. Run: sudo apt-get install libimage-exiftool-perl"
else
  say "Could not install exiftool: no brew, apk or apt-get here. Install it before /github-readme publishes a screenshot."
fi

# 4. Point git at the guard, keeping any hooks path you already had.
EXISTING=$(git config --global --get core.hooksPath || true)
if [ -n "$EXISTING" ] && [ "$EXISTING" != "$REPO/hooks" ]; then
  say "Left your hooks path alone: git already uses $EXISTING."
  say "To take the guard instead, run: git config --global core.hooksPath \"$REPO/hooks\""
else
  git config --global core.hooksPath "$REPO/hooks"
  chmod +x "$REPO/hooks/pre-commit"
  say "Every repo on this machine now refuses a commit holding a secret."
  say "This also stops any hook of your own in a repo's .git/hooks from running,"
  say "because git uses one hooks folder at a time. Undo with:"
  say "  git config --global --unset core.hooksPath"
fi

say ""
say "Done. Restart Claude Code, then type /fix: it should ask what is broken instead of guessing."
