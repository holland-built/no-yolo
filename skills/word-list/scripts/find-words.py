#!/usr/bin/env python3
"""Find the words I use on you that you never use back.

Reads your saved sessions. Counts what I write and what you write, separately.
A word I lean on that you never reach for is a word you may not own.

Code blocks and anything in backticks are dropped first. Naming a command is
not the same as using a word.
"""
import json, re, sys, glob, os, collections

HOME = os.path.expanduser("~")
ROOT = os.path.join(HOME, ".claude", "projects")
MIN_MINE = int(os.environ.get("MIN_MINE", "4"))     # I used it at least this often
MAX_YOURS = int(os.environ.get("MAX_YOURS", "0"))   # you used it at most this often

# Ordinary English. A word here is never a candidate, however often I use it.
COMMON = set("""the a an and or but if then than that this these those of to in on at by for
with from as is are was were be been being do does did done have has had will would can could
should may might must not no nor only just very more most much many few less least same other
another such own so too also here there when where which who whom whose what why how all any
both each every some none one two three first last next now new old good bad big small long
short high low right wrong left up down out off over under again once still yet ever never
always often sometimes about after before during while until since because though although
you your yours i me my mine we us our ours it its they them their he she him her his hers
say says said tell tells told ask asks asked go goes went get gets got make makes made take
takes took give gives gave come comes came see sees saw look looks looked find finds found
know knows knew think thinks thought want wants wanted need needs needed use uses used
work works worked run runs ran put puts read reads write writes wrote keep keeps kept
let lets leave leaves left turn turns turned start starts started stop stops stopped
open opens opened close closes closed add adds added set sets cut cuts drop drops dropped
name names named call calls called show shows showed line lines word words file files
thing things way ways time times day days part parts place places point points case cases
fact facts number numbers list lists page pages back done here now yes ok okay
one two three four five six seven eight nine ten
""".split())

def texts(path, role):
    for line in open(path, errors="ignore"):
        try:
            d = json.loads(line)
        except Exception:
            continue
        if d.get("type") != role:
            continue
        c = d.get("message", {}).get("content")
        if isinstance(c, str):
            yield c
        elif isinstance(c, list):
            for b in c:
                if isinstance(b, dict) and b.get("type") == "text":
                    yield b["text"]

def words_in(text):
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    text = re.sub(r"`[^`]*`", " ", text)
    text = re.sub(r"https?://\S+", " ", text)
    return re.findall(r"\b[a-zA-Z][a-zA-Z'\-]{2,}\b", text.lower())

def main():
    files = glob.glob(os.path.join(ROOT, "**", "*.jsonl"), recursive=True)
    if not files:
        print("No saved sessions found under ~/.claude/projects.", file=sys.stderr)
        return 1
    mine, yours = collections.Counter(), collections.Counter()
    for f in files:
        for t in texts(f, "assistant"):
            mine.update(words_in(t))
        for t in texts(f, "user"):
            yours.update(words_in(t))

    rows = [(w, c, yours.get(w, 0)) for w, c in mine.items()
            if c >= MIN_MINE and yours.get(w, 0) <= MAX_YOURS and w not in COMMON]
    rows.sort(key=lambda r: -r[1])

    print(f"# sessions read: {len(files)}")
    print(f"# my distinct words: {len(mine)}   yours: {len(yours)}")
    print(f"# candidates: words I used {MIN_MINE}+ times that you used {MAX_YOURS} times or fewer")
    print()
    print(f"{'word':22} {'I used':>7} {'you used':>9}")
    for w, c, y in rows[:120]:
        print(f"{w:22} {c:7} {y:9}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
