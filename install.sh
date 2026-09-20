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
mkdir -p "$CLAUDE/skills" "$CLAUDE/output-styles"
cp "$REPO/CLAUDE.md" "$REPO/settings.json" "$REPO/statusline.sh" "$CLAUDE/"
cp -R "$REPO/skills/." "$CLAUDE/skills/"
cp -R "$REPO/output-styles/." "$CLAUDE/output-styles/"
cp -R "$REPO/tools" "$CLAUDE/"
chmod +x "$CLAUDE/statusline.sh"
say "Copied the rules, style, skills and checker into $CLAUDE"

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

# 5. Download the linter the /slop rules run on.
if command -v npm >/dev/null 2>&1; then
  if (cd "$CLAUDE/tools/anti-slop" && npm install --silent --save-exact oxlint@1.83.0 @oxlint/plugins@1.83.0); then
    say "Installed the linter behind /slop"
  else
    say "npm could not install the linter, so /slop has no linter yet."
  fi
else
  say "No npm here, so /slop has no linter. Install Node.js, then run this script again."
fi

say ""
say "Done. Restart Claude Code, then type /fix: it should ask what is broken instead of guessing."
