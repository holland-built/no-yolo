#!/usr/bin/env python3
"""jev-judge: advice when two models disagree. Never edits anything.

Input JSON (file path or stdin):
  {"criteria": ["Keeps the file format unchanged", ...],
   "a": {"name": "Claude", "claims": {"Keeps the file format unchanged": ["...", "..."]}},
   "b": {"name": "Codex",  "claims": {"Keeps the file format unchanged": ["..."]}}}

Claims are filed under the criterion they speak to, and each question shows Jev
only the claims filed under it. A criterion with no claims from either side goes
to the user without asking Jev, because Jev answers confidently even when the
claims say nothing about it.

For every other criterion Jev answers a Choice (a / b / neither), asked twice
with the sides swapped. It counts only if both orders agree and confidence is
at least MIN_CONF. Otherwise it goes to the user. The verdict is advice.
"""
import http, http.client, json, os, sys, urllib.error, urllib.request

URL = "https://api.typesafe.ai/v1/systemone"
MODEL = "jev-1.13.0"
MIN_CONF = 0.5  # untuned: held up on 2 real cases. Recheck once there are 5 or more real picks
KEY_FILE = "~/.config/typesafe/key"


class JevFailed(Exception):
    """A call to Jev failed. The message is safe to print: it never holds the key."""


class NoRedirect(urllib.request.HTTPRedirectHandler):
    """urllib would resend the Authorization header to wherever a redirect points."""
    def redirect_request(self, *args, **kwargs):
        return None


OPENER = urllib.request.build_opener(NoRedirect)


def api_key():
    key = os.environ.get("TYPESAFE_API_KEY")
    if not key:
        try:
            with open(os.path.expanduser(KEY_FILE)) as f:
                key = f.read().strip()
        except OSError:
            raise JevFailed(f"no key: set TYPESAFE_API_KEY or put the key in {KEY_FILE}") from None
    if not key or not key.isascii() or not key.isprintable() or any(ch.isspace() for ch in key):
        raise JevFailed("the TypeSafe key is empty, or has spaces, line breaks or odd characters in it")
    return key


def choice_in(options):
    """A check for post(): the answer must be a Choice naming one of `options`."""
    def check(answer):
        if answer["choice"] not in options or not isinstance(answer["confidence"], (int, float)):
            raise ValueError
    return check


def check_noul(answer):
    if not isinstance(answer["noul"], (int, float)) or not 0 <= answer["noul"] <= 1:
        raise ValueError


def post(state, questions, check, timeout=30):
    """Send one request to Jev and return its answers. `check` raises ValueError for an answer in
    the wrong shape. Every failure becomes a JevFailed whose message is safe to print."""
    body = json.dumps({"model": MODEL, "state": state, "questions": questions}).encode()
    req = urllib.request.Request(URL, body, {
        "Authorization": "Bearer " + api_key(),
        "Content-Type": "application/json"})
    try:
        with OPENER.open(req, timeout=timeout) as r:
            answers = json.load(r)["answers"]
        for k in questions:
            check(answers[k])
        return answers
    except urllib.error.HTTPError as e:
        e.close()
        try:
            phrase = " " + http.HTTPStatus(e.code).phrase  # our own table, never the server's words
        except ValueError:
            phrase = ""
        raise JevFailed(f"HTTP {e.code}{phrase}") from None
    except (OSError, http.client.HTTPException):
        raise JevFailed("no answer from api.typesafe.ai (network error or timeout)") from None
    except (ValueError, KeyError, TypeError):
        raise JevFailed("Jev's answer was not in the expected shape") from None


def ask(state, questions):
    return post(state, questions, choice_in(("X", "Y", "neither")))


def build(i, criterion, first, second):
    """State holds the two options as the claims filed under this criterion. Labels are X and Y."""
    state = {"X": first["claims"].get(criterion, []), "Y": second["claims"].get(criterion, [])}
    questions = {
        f"c{i}": {
            "type": "choice",
            "instructions": f"Which option, `X` or `Y`, better satisfies this criterion: {criterion}",
            "criteria": {"X": "`X` clearly better satisfies it",
                         "Y": "`Y` clearly better satisfies it",
                         "neither": "Equal, or the claims say nothing about it"},
        }}
    return state, questions


def judge(data, ask_fn=ask):
    a, b, criteria = data["a"], data["b"], data["criteria"]
    for side in (a, b):
        unknown = set(side["claims"]) - set(criteria)
        if unknown:
            raise ValueError(f"{side['name']} has claims for criteria not in the list: {sorted(unknown)}")
    rows = []
    for i, c in enumerate(criteria):
        if not (a["claims"].get(c) or b["claims"].get(c)):
            rows.append((c, "no evidence", None))
            continue
        f = ask_fn(*build(i, c, a, b))[f"c{i}"]                   # X=a, Y=b
        s = ask_fn(*build(i, c, b, a))[f"c{i}"]                   # X=b, Y=a
        f_pick = {"X": "a", "Y": "b", "neither": "neither"}[f["choice"]]
        s_pick = {"X": "b", "Y": "a", "neither": "neither"}[s["choice"]]
        conf = min(f["confidence"], s["confidence"])
        if f_pick == s_pick and conf >= MIN_CONF:
            rows.append((c, f_pick, conf))
        else:
            rows.append((c, "ask", conf))
    return rows


def report(data, rows):
    names = {"a": data["a"]["name"], "b": data["b"]["name"], "neither": "neither"}
    wins = {"a": 0, "b": 0}
    out = ["Questions Jev saw (one per criterion, both orders):"]
    for c, pick, conf in rows:
        if pick == "no evidence":
            out.append(f"  - {c}  ->  ASK THE USER (no claims from either side, Jev not asked)")
            continue
        out.append(f"  - {c}  ->  {names.get(pick, 'ASK THE USER')}  (confidence {conf:.2f})")
        if pick in wins:
            wins[pick] += 1
    asks = sum(1 for _, p, _ in rows if p in ("ask", "no evidence"))
    if asks or wins["a"] == wins["b"]:
        out.append("VERDICT: ask the user "
                   f"({asks} criteria unsettled, {names['a']} {wins['a']} - {wins['b']} {names['b']}).")
    else:
        w = "a" if wins["a"] > wins["b"] else "b"
        out.append(f"ADVICE: {names[w]} ({wins['a']} - {wins['b']}). Advice only; the user decides. "
                   "Code correctness is for tests, not this.")
    return "\n".join(out)


if __name__ == "__main__":
    raw = open(sys.argv[1]).read() if len(sys.argv) > 1 else sys.stdin.read()
    data = json.loads(raw)
    try:
        print(report(data, judge(data)))
    except JevFailed as e:
        sys.exit(f"Jev: couldn't tell. {e}")
