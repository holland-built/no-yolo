#!/usr/bin/env python3
"""Print the newest stable Astryx release that is at least a week old.

Astryx is in beta and ships often. Waiting a week means a bad release is usually caught by someone
else first, and asking at install time keeps new work current with no pinned number to maintain.
"""
import datetime
import json
import re
import subprocess

MIN_AGE = datetime.timedelta(days=7)
STABLE = re.compile(r"^\d+\.\d+\.\d+$")

times = json.loads(subprocess.run(["npm", "view", "@astryxdesign/core", "time", "--json"],
                                  capture_output=True, text=True, timeout=60, check=True).stdout)
cutoff = datetime.datetime.now(datetime.timezone.utc) - MIN_AGE
ready = [version for version, stamp in times.items() if STABLE.match(version)
         and datetime.datetime.fromisoformat(stamp.replace("Z", "+00:00")) <= cutoff]
print(max(ready, key=lambda version: tuple(int(part) for part in version.split("."))))
