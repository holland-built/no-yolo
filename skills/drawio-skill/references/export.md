# Export — Windows, Linux/Headless/CI, WSL2

Read this when exporting on Windows, Linux/headless/CI, or WSL2 — macOS export
is covered inline in SKILL.md's `## Export`.

## Windows

```bash
"C:\Program Files\draw.io\draw.io.exe" -x -f png -e -s 2 -o diagram.drawio.png input.drawio
```

## Linux (headless — requires xvfb-run)

```bash
export HOME=${HOME:-/tmp}
xvfb-run -a --server-args="-screen 0 1280x1024x24" \
  drawio -x -f png -e -s 2 -o diagram.drawio.png input.drawio --disable-gpu
# Running as root (CI / Docker)? Append --no-sandbox AT THE END (placing it earlier makes drawio treat it as the input filename)
```

## Fallback chain

When tools are unavailable, degrade gracefully:

| Scenario | Behavior |
|----------|----------|
| draw.io CLI missing, Python available | Use browser fallback (diagrams.net URL) |
| draw.io CLI missing, Python missing | Generate `.drawio` XML only; instruct user to open in draw.io desktop or diagrams.net manually |
| draw.io CLI crashes / no output in macOS sandbox isolation | Treat CLI as unavailable in-sandbox; use browser fallback / XML-only; ask user to run CLI exports in a non-sandboxed host environment |
| Vision unavailable for self-check | Skip self-check (step 5); proceed directly to showing user the exported PNG |
| Export fails (Chromium/display issues) | On Linux, retry with `xvfb-run -a`; if still failing, deliver `.drawio` XML and suggest manual export |
| Export fails on Linux server (headless) | Try in order: (1) `xvfb-run -a`, (2) append `--no-sandbox` at the very end if root, (3) add `--disable-gpu`, (4) `export HOME=/tmp`, (5) install apt deps (`libgtk-3-0 libnotify4 libnss3 libgbm1 libasound2t64` etc.), (6) fall back to [tomkludy/drawio-renderer](https://hub.docker.com/r/tomkludy/drawio-renderer) Docker (REST API for headless export) |

## Checking if drawio is in PATH

```bash
# Prefer the Homebrew / Linux-package binary name (no dot)
if command -v drawio &>/dev/null; then
  DRAWIO="drawio"
# Fall back to the dot-named binary (older installs, manual symlinks)
elif command -v draw.io &>/dev/null; then
  DRAWIO="draw.io"
# macOS .app bundle (binary inside the bundle keeps the dot)
elif [ -f "/Applications/draw.io.app/Contents/MacOS/draw.io" ]; then
  DRAWIO="/Applications/draw.io.app/Contents/MacOS/draw.io"
# WSL2: the CLI is the Windows desktop exe, reached via /mnt/c (note the space)
elif grep -qi microsoft /proc/version 2>/dev/null && [ -f "/mnt/c/Program Files/draw.io/draw.io.exe" ]; then
  DRAWIO="/mnt/c/Program Files/draw.io/draw.io.exe"
else
  echo "drawio not found — install from https://github.com/jgraph/drawio-desktop/releases (Homebrew: brew install --cask drawio)"
fi
```

## WSL2 / Windows specifics

- Browser-fallback URLs: `open "$URL"` (macOS) / `xdg-open "$URL"` (Linux) works directly, but on **WSL2 / Windows**, `cmd.exe` drops the `#fragment` — write a `.url` shortcut file and open that instead (see `references/troubleshooting.md` → "WSL2 / Windows specifics").
- Opening exported files and browser-fallback URLs on **WSL2 / native Windows** needs path conversion + the same `.url`-file workaround (`cmd.exe` drops URL `#fragment`s) — see the "WSL2 / Windows specifics" section in `references/troubleshooting.md`.
