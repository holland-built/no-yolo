#!/usr/bin/env python3
"""Print installed Claude Code plugins as TSV: name<TAB>version<TAB>scope.
Shared by setup.sh (Step 5) and skills/update/SKILL.md — edit here, not there."""
import json
import os
import sys

path = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.claude/plugins/installed_plugins.json")
if not os.path.exists(path):
    print("No plugins installed.")
    sys.exit(0)
try:
    plugins = json.load(open(path)).get("plugins", {})
except (ValueError, OSError):
    print("installed_plugins.json unreadable.")
    sys.exit(0)
if not plugins:
    print("No plugins installed.")
    sys.exit(0)
for name, entries in plugins.items():
    e = entries[0] if entries else {}
    print(f"{name}\t{e.get('version', '?')}\t{e.get('scope', '?')}")
