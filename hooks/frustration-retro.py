#!/usr/bin/env python3
"""When the user sounds frustrated about a repeated mistake, remind Claude to run the retro skill.

The retro skill's description alone loaded only some of the time in trigger tests, so this
UserPromptSubmit hook adds a reminder whenever the message matches one of the phrases below.
Typing /retro still works on its own. Add phrases here when a new one shows up.
"""
import json
import re
import sys

PHRASES = [
    r"told you (that|this|it)?\s*\d*\s*(times|before|already)",
    r"how many times",
    r"keep (doing|making|forgetting|ignoring)",
    r"(still|again) (doing|broken|wrong|not)",
    r"what went wrong",
    r"why did (this|that|it) take so long",
    r"(i|we) (already )?said (that|this) (before|already)",
    r"for the \w+ time",
    r"not again",
]

try:
    prompt = json.load(sys.stdin).get("prompt", "")
except Exception:
    sys.exit(0)

if prompt.lstrip().startswith("/retro"):
    sys.exit(0)

if any(re.search(p, prompt, re.I) for p in PHRASES):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "The user sounds frustrated about something repeating. Fix the thing first, "
                             "then run the retro skill on this chat (CLAUDE.md: a repeated correction gets a retro).",
    }}))
