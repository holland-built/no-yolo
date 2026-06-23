#!/usr/bin/env bash
# setup.sh — idempotent post-clone setup for ~/.claude (no-yolo)
#
# Usage:
#   bash ~/.claude/setup.sh           # full install — tools, CLI plugins, skill symlinks
#   bash ~/.claude/setup.sh --md-only # rules only — no tools, skill triggers stripped from CLAUDE.md
#
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
MODE="full"
[[ "${1:-}" == "--md-only" ]] && MODE="md-only"

echo "==> Mode: $MODE"
echo ""

# ── Step 1: settings.json ────────────────────────────────────────────────────
echo "==> 1. settings.json"
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  echo "    settings.json already exists — skipping copy"
else
  cp "$CLAUDE_DIR/settings.example.json" "$CLAUDE_DIR/settings.json"
  echo "    Created settings.json from template"
fi
echo "    ACTION REQUIRED: edit settings.json — update node path and add your MCP servers"

# ── Step 2: hook permissions ─────────────────────────────────────────────────
echo ""
echo "==> 2. chmod hooks"
if ls "$CLAUDE_DIR"/hooks/*.sh >/dev/null 2>&1; then
  chmod +x "$CLAUDE_DIR"/hooks/*.sh
  echo "    Hook scripts made executable"
else
  echo "    No hook scripts found — skipping"
fi

# ── MD-only: strip skill triggers from CLAUDE.md, then exit ─────────────────
if [[ "$MODE" == "md-only" ]]; then
  echo ""
  echo "==> 3. Strip skill triggers from CLAUDE.md"
  echo "    (reads current file — no hardcoded skill names)"

  python3 - "$CLAUDE_DIR/CLAUDE.md" <<'PYEOF'
import re, sys, pathlib

p = pathlib.Path(sys.argv[1])
text = p.read_text()

# Remove @memory/CLAUDE.generated.md import line (memory system not included)
text = re.sub(r'^@memory/CLAUDE\.generated\.md\n?', '', text, flags=re.MULTILINE)

# Remove skill trigger blocks. Each block is exactly:
#   # skillname                (single lowercase word/hyphens)
#   - **skillname** ...        (description + trigger)
#   When the user types ...    (invocation line — may repeat for multi-phrase triggers)
text = re.sub(
    r'^# [a-z][a-z0-9-]+\n- \*\*.*\n(?:When the user .*\n?)+',
    '',
    text,
    flags=re.MULTILINE
)

# Collapse triple+ blank lines left behind
text = re.sub(r'\n{3,}', '\n\n', text)

p.write_text(text)
print("    Removed: @memory import + all skill trigger blocks")
PYEOF

  echo ""
  echo "==> Done (MD-only)."
  echo "    Core rules load automatically when you open Claude Code in any project."
  echo "    Skills folder still present but Claude won't trigger them — safe to ignore or delete."
  echo ""
  echo "    To install tools later: run bash ~/.claude/setup.sh (safe to re-run — skips anything already installed)"
  exit 0
fi

# ── Full install ─────────────────────────────────────────────────────────────

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
echo "==> 4. Plugin skills"
echo "    Installing trim..."
npx skills@latest add holland-built/trim || echo "    ! trim install failed"
echo "    Installing improve..."
npx skills@latest add shadcn/improve || echo "    ! improve install failed"
echo ""
echo "    Note: two more plugins install inside Claude Code (not the terminal):"
echo "      /plugin marketplace add impeccable     # magazine-style design theme (optional)"
echo "      /plugin marketplace add JuliusBrussee/caveman  # terse mode (optional)"

echo ""
echo "==> 5. Plugins (Claude Code marketplace)"
PLUGINS_JSON="$CLAUDE_DIR/plugins/installed_plugins.json"
if [ -f "$PLUGINS_JSON" ] && command -v python3 >/dev/null 2>&1; then
  python3 - "$PLUGINS_JSON" <<'PYEOF'
import json, sys
try:
    plugins = json.load(open(sys.argv[1])).get("plugins", {})
except (ValueError, OSError):
    print("    ! installed_plugins.json is unreadable — skipping"); sys.exit(0)
if not plugins:
    print("    No plugins installed yet."); sys.exit(0)
print(f"    Found {len(plugins)} installed plugins:")
print(f"    {'NAME':<42} {'VERSION':<14} SCOPE")
for name, entries in plugins.items():
    e = entries[0] if entries else {}
    print(f"    {name:<42} {e.get('version','?'):<14} {e.get('scope','?')}")
PYEOF
else
  echo "    No installed_plugins.json found — install recommended plugins inside Claude Code:"
  echo "      /plugin marketplace add JuliusBrussee/caveman       # terse mode"
  echo "      /plugin marketplace add ecc-plugins/ecc             # agent types + code review"
  echo "      /plugin marketplace add karpathy/karpathy-skills     # Karpathy skill set"
  echo "      /plugin marketplace add design-plugins/design-and-refine  # UI design"
  echo "      /plugin marketplace add AgriciDaniel/claude-obsidian # Obsidian integration"
fi
echo "    To check for plugin updates: run /plugin list in Claude Code, then /plugin update <name>"

echo ""
echo "==> 6. Environment variables (add to ~/.zshrc or ~/.bash_profile)"
cat <<'ENVEOF'

    export GROQ_API_KEY=your_key_here               # video-to-kb, graphify (Whisper)
    export OBSIDIAN_VAULT="$HOME/path/to/your/vault"  # video-to-kb vault root

ENVEOF

echo "==> Done."
echo ""
echo "    Verify setup: claude --version"
echo "    Check skills: run /my-skills in Claude Code"
echo ""
echo "    See README.md for full documentation."
