#!/usr/bin/env bash
# setup.sh — idempotent post-clone setup for ~/.claude (no-yolo)
# Run once after cloning: bash ~/.claude/setup.sh
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"

echo "==> 1. settings.json"
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  echo "    settings.json already exists — skipping copy"
else
  cp "$CLAUDE_DIR/settings.example.json" "$CLAUDE_DIR/settings.json"
  echo "    Created settings.json from template"
fi
echo "    ACTION REQUIRED: edit settings.json — update node path and add your MCP servers"

echo ""
echo "==> 2. chmod hooks"
if ls "$CLAUDE_DIR"/hooks/*.sh >/dev/null 2>&1; then
  chmod +x "$CLAUDE_DIR"/hooks/*.sh
  echo "    Hook scripts made executable"
else
  echo "    No hook scripts found — skipping"
fi

echo ""
echo "==> 3. CLI tools"

if command -v fallow >/dev/null 2>&1; then
  echo "    fallow already installed"
else
  echo "    Installing fallow..."
  npm install -g fallow || echo "    ! fallow install failed — install manually: npm install -g fallow"
fi

if command -v graphify >/dev/null 2>&1; then
  echo "    graphify already installed"
else
  echo "    Installing graphify..."
  if command -v uv >/dev/null 2>&1; then
    uv tool install graphify || echo "    ! graphify install failed"
  else
    echo "    ! uv not found — install uv first: curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "      then run: uv tool install graphify"
  fi
fi

if command -v gh >/dev/null 2>&1; then
  echo "    gh already installed"
else
  echo "    ! gh missing — install: brew install gh && gh auth login"
fi

if command -v dot >/dev/null 2>&1; then
  echo "    Graphviz already installed"
else
  echo "    ! Graphviz missing — install: brew install graphviz  (used by drawio-skill)"
fi

echo ""
echo "==> 4. Plugin skills (symlinks into ~/.agents/skills/)"
echo "    Installing ponytail..."
npx skills@latest add DietrichGebert/ponytail || echo "    ! ponytail install failed"
echo "    Installing improve..."
npx skills@latest add shadcn/improve || echo "    ! improve install failed"
echo ""
echo "    Note: plugin skills install inside Claude Code (not the terminal):"
echo "      /plugin marketplace add superpowers    # writing-plans, executing-plans, subagent-driven-development, +"
echo "      /plugin marketplace add ecc            # ecc:* agent types (optional)"
echo "      /plugin marketplace add impeccable     # magazine-style design theme (optional)"
echo "      /plugin marketplace add JuliusBrussee/caveman  # terse mode (optional)"

echo ""
echo "==> 5. Environment variables (add to ~/.zshrc or ~/.bash_profile)"
cat <<'ENVEOF'

    export GROQ_API_KEY=your_key_here      # video-to-kb, graphify (Whisper)
    export OBSIDIAN_VAULT="$HOME/path/to/your/vault"  # video-to-kb vault root

ENVEOF

echo "==> Done."
echo ""
echo "    Verify setup: claude --version"
echo "    Check skills: run /my-skills in Claude Code"
echo ""
echo "    See README.md for full documentation."
