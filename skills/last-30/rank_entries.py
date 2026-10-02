#!/usr/bin/env python3
"""rank-entries: a pre-filter for /last-30. Jev rates how much each changelog or release entry matters
to the reader, so Claude reads in full only the ones that do. It never edits anything.

Input JSON (file path or stdin):
  {"topic": "Codex CLI", "entries": [{"date": "2026-09-20", "title": "...", "text": "..."}, ...]}

The reader is described in ~/.config/typesafe/last30-profile.txt (one short paragraph). Without that
file a generic developer is assumed.

An entry is READ when its score is at least READ_FROM, when Jev was unsure (low confidence), when it
could not be rated, or when its title or text contains a watch word. Watch words are the defaults below
plus any lines in ~/.config/typesafe/last30-watch.txt (tools, flags and commands this setup uses). Only
clearly low, confident scores with no watch word are left out. The entries are public text, cut to
MAX_CHARS each.
"""
import json, os, sys
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "jev-judge"))
import jev_judge as j
from jev_judge import JevFailed

PROFILE_PATH = os.path.expanduser("~/.config/typesafe/last30-profile.txt")
WATCH_PATH = os.path.expanduser("~/.config/typesafe/last30-watch.txt")
DEFAULT_WATCH = ["breaking", "deprecat", "removed", "security"]
DEFAULT_PROFILE = "A developer who uses AI coding assistants daily and wants to know what changed in those tools."
MAX_CHARS = 800
READ_FROM = 1.3        # untuned, from one real run: empty alpha builds scored 1.1, real releases 1.5 or more
UNSURE_BELOW = 0.3     # untuned: confidence under this means read it
WORKERS = 6
LEVELS = ["Irrelevant to this reader",
          "Minor: a small fix or detail the reader would not act on",
          "Worth knowing: changes how a tool behaves or what is available",
          "Worth acting on: the reader should change something or try something now"]


def check_score(answer):
    if not isinstance(answer["score"], (int, float)) or not 0 <= answer["score"] <= len(LEVELS) - 1 \
            or not isinstance(answer["confidence"], (int, float)):
        raise ValueError


def load_profile(path=PROFILE_PATH):
    try:
        with open(path) as f:
            return f.read().strip() or DEFAULT_PROFILE
    except OSError:
        return DEFAULT_PROFILE


def load_watch(path=WATCH_PATH):
    words = list(DEFAULT_WATCH)
    try:
        with open(path) as f:
            words += [line.strip().casefold() for line in f if line.strip() and not line.strip().startswith("#")]
    except OSError:
        pass
    return words


def rate(entry, topic, profile, post, watch):
    state = {"reader": profile, "topic": topic,
             "entry": {"date": entry.get("date", ""), "title": entry.get("title", ""),
                       "text": entry.get("text", "")[:MAX_CHARS]}}
    questions = {"rate": {"type": "score",
                          "instructions": "How much does this entry matter to the reader?",
                          "criteria": LEVELS}}
    haystack = (entry.get("title", "") + " " + entry.get("text", "")).casefold()
    hit = next((w for w in watch if w in haystack), None)
    try:
        a = post(state, questions, check_score, timeout=15)["rate"]
        score, confidence = a["score"], a["confidence"]
    except JevFailed:
        return {**entry, "score": None, "confidence": None, "read": True, "why": "unrated"}
    if score >= READ_FROM:
        why = "score"
    elif confidence < UNSURE_BELOW:
        why = "unsure"
    elif hit:
        why = f"watch word: {hit}"
    else:
        why = None
    return {**entry, "score": score, "confidence": confidence, "read": why is not None, "why": why}


def rank(entries, topic, profile, post=j.post, watch=None):
    watch = DEFAULT_WATCH if watch is None else watch
    numbered = [{**e, "n": i} for i, e in enumerate(entries, 1)]
    with ThreadPoolExecutor(max_workers=WORKERS) as pool:
        return list(pool.map(lambda e: rate(e, topic, profile, post, watch), numbered))


def first_line(text):
    return " ".join(text.split())[:90]


def report(rows):
    ordered = sorted(rows, key=lambda r: (r["score"] is not None, r["score"] or 0), reverse=True)
    out = ["READ these in full (highest first):"]
    for r in ordered:
        if r["read"]:
            tag = "unrated" if r["score"] is None else f"{r['score']:.1f}"
            note = "" if r["why"] == "score" else f"  [{r['why']}]"
            out.append(f"  - #{r['n']}  {tag}  {r.get('date', '')}  {r.get('title', '')}{note}")
    left = [r for r in ordered if not r["read"]]
    out.append(f"{len(left)} of {len(rows)} left out as ranked low (spot-check any of them):")
    for r in left:
        out.append(f"  - #{r['n']}  {r['score']:.1f}  {r.get('date', '')}  {r.get('title', '')}: {first_line(r.get('text', ''))}")
    return "\n".join(out)


if __name__ == "__main__":
    raw = open(sys.argv[1]).read() if len(sys.argv) > 1 else sys.stdin.read()
    data = json.loads(raw)
    rows = rank(data["entries"], data.get("topic", ""), load_profile(), watch=load_watch())
    if rows and all(r["score"] is None for r in rows):
        sys.exit("Jev: couldn't tell. No entry could be rated, so read them all.")
    print(report(rows))
