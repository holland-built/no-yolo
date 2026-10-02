#!/usr/bin/env python3
"""route-video: for /claude-video. Jev says which vault topic pages a source bears on, so Claude opens
those first instead of scanning every topic page. It never edits anything.

  python3 route_video.py <path to the source page, e.g. .../wiki/sources/vid-x.md>

It reads only the page's title, Summary and Key Claims (never the transcript or the Evidence), finds
the vault from the path, and loads every page in wiki/topics/*/ (title and the first Overview
paragraph). One request asks, for every topic page, "does this source bear on it?", plus which domain
the source belongs to and whether it is mostly promotion.

What is sent to TypeSafe: the source's title, Summary and Key Claims (each cut to MAX_FIELD
characters), and for every topic page its title and the first Overview paragraph (300 characters).
That is video content plus the vault's own topic notes. Keep anything private out of topic Overviews.
"""
import glob, json, os, re, sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "jev-judge"))
import jev_judge as j
from jev_judge import JevFailed

OPEN_FROM = 0.5     # untuned: a topic page to open
MAYBE_FROM = 0.25   # untuned: worth a look
PROMO_FROM = 0.5
MAX_FIELD = 3000
DOMAINS = ("ai", "ha", "neither")


def vault_root(page):
    path = os.path.abspath(page)
    marker = os.sep + "wiki" + os.sep
    if marker not in path:
        raise ValueError("the page is not under a wiki/ folder")
    return path[:path.index(marker)]


def frontmatter(text):
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    return m.group(1) if m else ""


def field(front, name):
    m = re.search(rf"^{name}:\s*(.*)$", front, re.M)
    return m.group(1).strip().strip('"') if m else ""


def section(text, heading):
    m = re.search(rf"^## {heading}\s*\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    return m.group(1).strip() if m else ""


def read_source(page):
    with open(page) as f:
        text = f.read()
    front = frontmatter(text)
    tagged = re.findall(r"[\w-]+", field(front, "topics").strip("[]"))
    return {"title": field(front, "title"), "summary": section(text, "Summary")[:MAX_FIELD],
            "key_claims": section(text, "Key Claims")[:MAX_FIELD], "tagged": tagged}


def load_topics(root):
    topics = []
    for path in sorted(glob.glob(os.path.join(root, "wiki", "topics", "*", "*.md"))):
        with open(path) as f:
            text = f.read()
        overview = section(text, "Overview").split("\n\n")[0]
        topics.append({"id": f"{os.path.basename(os.path.dirname(path))}/{os.path.basename(path)[:-3]}",
                       "title": field(frontmatter(text), "title") or os.path.basename(path)[:-3],
                       "overview": " ".join(overview.split())[:300]})
    return topics


def questions(topics):
    q = {"domain": {"type": "choice",
                    "instructions": "Which knowledge-base domain does this source belong to?",
                    "criteria": {"ai": "AI models, tools, agents, prompting or coding assistants",
                                 "ha": "Home Assistant or home automation",
                                 "neither": "Neither of those"}},
         "promo": {"type": "noul",
                   "instructions": "Is this source mostly promotion for a product or service, so its claims and numbers need checking?"}}
    for i, t in enumerate(topics):
        q[f"t{i}"] = {"type": "noul",
                      "instructions": f"Does this source bear on the topic \"{t['title']}\"? The topic covers: {t['overview']}",
                      "criteria": {"true": "The source adds to, supports or contradicts something this topic covers",
                                   "false": "The source is not about this topic"}}
    return q


def check(answer):
    if "noul" in answer:
        j.check_noul(answer)
    else:
        j.choice_in(DOMAINS)(answer)


def route(src, topics, post=j.post):
    state = {"source": {"title": src["title"], "summary": src["summary"], "key_claims": src["key_claims"]}}
    answers = post(state, questions(topics), check, timeout=20)
    try:
        scored = sorted(({"id": t["id"], "score": answers[f"t{i}"]["noul"]} for i, t in enumerate(topics)),
                        key=lambda r: r["score"], reverse=True)
        domain = (answers["domain"]["choice"], answers["domain"]["confidence"])
        promo = answers["promo"]["noul"]
    except (KeyError, TypeError):
        raise JevFailed("Jev's answer was not in the expected shape") from None
    opened = [r for r in scored if r["score"] >= OPEN_FROM]
    maybe = [r for r in scored if MAYBE_FROM <= r["score"] < OPEN_FROM]
    missed = [s for s in src["tagged"] if s not in {r["id"].split("/")[-1] for r in opened}]
    return {"domain": domain, "promo": promo, "open": opened, "maybe": maybe,
            "other": len(scored) - len(opened) - len(maybe), "missed_tagged": missed}


def report(result, src):
    out = [f"Domain: {result['domain'][0]} ({result['domain'][1]:.2f})"]
    if result["open"]:
        out.append("Open these topic pages first:")
        out += [f"  - {r['id']}  {r['score']:.2f}" for r in result["open"]]
    if result["maybe"]:
        out.append("Maybe, worth a look:")
        out += [f"  - {r['id']}  {r['score']:.2f}" for r in result["maybe"]]
    if not result["open"] and not result["maybe"]:
        out.append("No topic page matched. Create one only if the subject recurs across sources.")
    out.append(f"{result['other']} other topic pages did not match. Jev only suggests; open more if the source needs it.")
    if result["promo"] >= PROMO_FROM:
        out.append(f"Mostly promotional ({result['promo']:.2f}): check its numbers before repeating them.")
    if result["missed_tagged"]:
        out.append("Already tagged on the page but not matched by Jev: " + ", ".join(result["missed_tagged"]))
    return "\n".join(out)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: route_video.py <path to the source page>")
    page = sys.argv[1]
    src = read_source(page)
    topics = load_topics(vault_root(page))
    try:
        print(report(route(src, topics), src))
    except JevFailed as e:
        sys.exit(f"Jev: couldn't tell. {e}")
