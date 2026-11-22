#!/bin/sh
# Install, update or remove no-yolo on this machine. Safe to run again.
#   ./install.sh             the safe default
#   ./install.sh --full      also lets Claude merge and release, and adds upkeep jobs
#   ./install.sh --uninstall removes only what this installer recorded
set -eu

REPO=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v python3 >/dev/null 2>&1; then
  echo "no-yolo needs python3. Install it, then run this again." >&2
  exit 1
fi
if ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))'; then
  echo "no-yolo needs Python 3.9 or newer." >&2
  exit 1
fi

PYTHONDONTWRITEBYTECODE=1 exec python3 "$REPO/installer/no_yolo.py" "$@"
