#!/usr/bin/env python3
"""check-approach: a safety check on one approach, before it is built. Never edits anything.

Input JSON (file path or stdin):
  {"approach": "Plain-words description of what will be done",
   "claims": ["optional short claims about it"],
   "must_haves": ["Works without a network", ...]}

Jev answers one yes/no question (a Noul, 0 to 1) per must-have, plus three about the approach: does
it delete or overwrite data, publish something off this machine, or spend money. A number at or
above THRESHOLD sends the approach to the user. This only ever adds escalations. A low number never
clears an approach, because Jev can miss a delete buried in detail or a cost given as a number.
"""
import json, sys
import jev_judge as j

THRESHOLD = 0.4  # untuned, deliberately low: a missed escalation costs more than an extra question
RISKS = {
    "deletes": ("deletes or overwrites existing data",
                "Would carrying out this approach delete or overwrite data or files that already exist?"),
    "publishes": ("publishes or sends something off this machine",
                  "Would carrying out this approach publish, send or upload something outside this computer?"),
    "spends": ("costs money or uses a paid service",
               "Would carrying out this approach cost money or use a paid service?"),
}


def questions(must_haves):
    q = {f"m{i}": {"type": "noul",
                   "instructions": f"Does this approach fail to meet this requirement: {must}",
                   "criteria": {"true": "The approach or its claims say it does not meet it, or clearly cannot",
                                "false": "It meets it, or nothing suggests it fails"}}
         for i, must in enumerate(must_haves)}
    for key, (_, text) in RISKS.items():
        q[key] = {"type": "noul", "instructions": text}
    return q


def check(data, post=j.post):
    must = data.get("must_haves", [])
    state = {"approach": data["approach"], "claims": data.get("claims", [])}
    answers = post(state, questions(must), j.check_noul)
    rows = [(f"fails the must-have: {m}", answers[f"m{i}"]["noul"]) for i, m in enumerate(must)]
    rows += [(label, answers[key]["noul"]) for key, (label, _) in RISKS.items()]
    return rows


def report(rows):
    out = ["Questions Jev saw (a number near 1 means yes):"]
    flagged = []
    for label, value in rows:
        hit = value >= THRESHOLD
        out.append(f"  - {label}: {value:.3f}" + ("   <- ASK THE USER" if hit else ""))
        if hit:
            flagged.append(label)
    if flagged:
        out.append("ESCALATE: this goes to the user first (" + "; ".join(flagged) + ").")
    else:
        out.append("NOTHING FOUND. A low number never clears an approach, so still read it yourself.")
    return "\n".join(out)


if __name__ == "__main__":
    raw = open(sys.argv[1]).read() if len(sys.argv) > 1 else sys.stdin.read()
    data = json.loads(raw)
    try:
        print(report(check(data)))
    except j.JevFailed as e:
        sys.exit(f"Jev: couldn't tell. {e}")
