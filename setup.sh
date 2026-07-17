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
echo "    ACTION REQUIRED: ensure 'node' is on PATH for GUI-launched apps, then add your MCP servers to settings.json"

# ── Step 2: hook permissions ─────────────────────────────────────────────────
echo ""
echo "==> 2. chmod hooks"
if ls "$CLAUDE_DIR"/hooks/*.sh >/dev/null 2>&1; then
  chmod +x "$CLAUDE_DIR"/hooks/*.sh
  echo "    Hook scripts made executable"
else
  echo "    No hook scripts found — skipping"
fi

# Install the tracked pre-commit hook into this clone's .git/hooks. Without
# this, a fresh clone of a PUBLIC template repo commits with NO secret scanning
# — the guard that blocks personal data, LAN IPs, and deny-listed terms from
# reaching GitHub would simply not exist. The source is tracked at
# hooks/pre-commit; git never copies it into .git/hooks on its own.
if [[ -f "$CLAUDE_DIR/hooks/pre-commit" ]] && git -C "$CLAUDE_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  HOOKS_DIR="$(git -C "$CLAUDE_DIR" rev-parse --git-path hooks)"
  # rev-parse may return a path relative to CLAUDE_DIR
  case "$HOOKS_DIR" in /*) : ;; *) HOOKS_DIR="$CLAUDE_DIR/$HOOKS_DIR" ;; esac
  mkdir -p "$HOOKS_DIR"
  cp "$CLAUDE_DIR/hooks/pre-commit" "$HOOKS_DIR/pre-commit"
  chmod +x "$HOOKS_DIR/pre-commit"
  echo "    Installed pre-commit secret-scanner into $HOOKS_DIR"
else
  echo "    No git dir or hooks/pre-commit — skipping hook install"
fi

# Seed the local (gitignored) deny-list from the template if absent, so the
# deny-list mechanism is discoverable on a fresh install. Never overwrites an
# existing one. Mirrors the settings.example.json -> settings.json pattern.
if [[ -f "$CLAUDE_DIR/.no-yolo-deny.example.txt" && ! -f "$CLAUDE_DIR/.no-yolo-deny.txt" ]]; then
  cp "$CLAUDE_DIR/.no-yolo-deny.example.txt" "$CLAUDE_DIR/.no-yolo-deny.txt"
  echo "    Seeded .no-yolo-deny.txt from template (edit it for your company/private terms)"
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

# Remove @docs/SKILL_TRIGGERS.md import line (triggers not included in md-only install)
text = re.sub(r'^@docs/SKILL_TRIGGERS\.md\n?', '', text, flags=re.MULTILINE)

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
print("    Removed: @memory + @docs/SKILL_TRIGGERS imports")
PYEOF

  echo ""
  echo "==> Done (MD-only)."
  echo "    Core rules load automatically when you open Claude Code in any project."
  echo "    Skills folder still present but Claude won't trigger them — safe to ignore or delete."
  echo "    docs/SKILL_TRIGGERS.md remains on disk but is no longer imported — safe to ignore or delete."
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
# upstream ships without user-invocable, which kills /improve — re-apply the
# local patch (docs/THIRD_PARTY_SKILLS.md); harmless if already present
IMPROVE_MD="$HOME/.agents/skills/improve/SKILL.md"
if [ -f "$IMPROVE_MD" ] && ! grep -q '^user-invocable: true' "$IMPROVE_MD"; then
  awk 'NR==1{print; print "user-invocable: true"; next} {print}' "$IMPROVE_MD" > "$IMPROVE_MD.tmp" \
    && mv "$IMPROVE_MD.tmp" "$IMPROVE_MD" \
    && echo "    Applied user-invocable patch to improve (see docs/THIRD_PARTY_SKILLS.md)"
fi
echo "    Installing emilkowalski/skills (design-eng taste rules — used by /design)..."
npx skills@latest add emilkowalski/skills || echo "    ! emilkowalski/skills install failed"
echo ""
echo "    Note: one more plugin installs inside Claude Code (not the terminal):"
echo "      /plugin marketplace add JuliusBrussee/caveman  # terse mode (optional)"
echo ""
echo "    Optional: design pipeline MCP servers (add to settings.json mcpServers block):"
echo "      lazyweb (reference screens)      — github.com/aboul3ata/lazyweb-skill"
echo "      interface-design (design memory) — github.com/Dammyjay93/interface-design"
echo "      design-refine (variant compare)  — github.com/0xdesign/design-plugin"

echo ""
echo "==> 5. Plugins (Claude Code marketplace)"
PLUGINS_JSON="$CLAUDE_DIR/plugins/installed_plugins.json"
if [ -f "$PLUGINS_JSON" ] && command -v python3 >/dev/null 2>&1; then
  # shared lister — one source of truth, also used by /update (skills/update/SKILL.md)
  OUT=$(python3 "$CLAUDE_DIR/hooks/list-plugins.py" "$PLUGINS_JSON")
  case "$OUT" in
    "No plugins"*|"installed_plugins.json"*) echo "    $OUT" ;;
    *)
      echo "    Found $(printf '%s\n' "$OUT" | wc -l | tr -d ' ') installed plugins:"
      printf "    %-42s %-14s %s\n" "NAME" "VERSION" "SCOPE"
      printf '%s\n' "$OUT" | awk -F'\t' '{printf "    %-42s %-14s %s\n",$1,$2,$3}' ;;
  esac
else
  echo "    No installed_plugins.json found — install recommended plugins inside Claude Code:"
  echo "      /plugin marketplace add JuliusBrussee/caveman       # terse mode"
  echo "      /plugin marketplace add pbakaus/impeccable          # frontend polish (/design hands off to it)"
  echo "    Maintainer's extras (optional, not required by any skill):"
  echo "      /plugin marketplace add ecc-plugins/ecc             # agent types + code review"
  echo "      /plugin marketplace add karpathy/karpathy-skills     # Karpathy skill set"
  echo "      /plugin marketplace add design-plugins/design-and-refine  # UI design"
  echo "      /plugin marketplace add AgriciDaniel/claude-obsidian # Obsidian integration"
fi
echo "    To check for plugin updates: run /plugin list in Claude Code, then /plugin update <name>"

echo ""
echo "==> 6. Environment variables (add to ~/.zshrc or ~/.bash_profile)"
cat <<'ENVEOF'

    export GROQ_API_KEY=your_key_here               # video-to-kb (Whisper transcription)
    export OBSIDIAN_VAULT="$HOME/path/to/your/vault"  # video-to-kb vault root

ENVEOF

echo "==> Done."
echo ""
echo "    Verify setup: claude --version"
echo "    Check skills: run /my-skills in Claude Code"
echo ""
echo "    See README.md for full documentation."
