"""Convert a WebVTT file to a deduped, 30-second-chunked timestamped transcript on stdout.
The dedupe exists because YouTube auto-captions repeat each cue's trailing line in the next cue.
"""

import re, sys

src = sys.argv[1]
raw = open(src, encoding="utf-8").read()

lines = []  # (secs, text)
for m in re.finditer(r"(\d\d):(\d\d):(\d\d)\.\d\d\d --> .*?\n(.*?)(?=\n\n|\n\d\d:\d\d:\d\d\.|\Z)", raw, re.S):
    h, mi, s, body = m.group(1), m.group(2), m.group(3), m.group(4)
    t = int(h) * 3600 + int(mi) * 60 + int(s)
    body = re.sub(r"<[^>]+>", "", body)
    for ln in body.split("\n"):
        ln = re.sub(r"\s+", " ", ln).strip()
        if ln:
            lines.append((t, ln))

# YouTube rolling captions: each cue repeats the prior cue's trailing line
uniq = []
for t, ln in lines:
    if uniq and ln == uniq[-1][1]:
        continue
    if any(ln == prev for _, prev in uniq[-4:]):
        continue
    uniq.append((t, ln))

chunks = []
cur_start, cur = None, []
for t, ln in uniq:
    if cur_start is None:
        cur_start = t
    cur.append(ln)
    if t - cur_start >= 30:
        chunks.append((cur_start, " ".join(cur)))
        cur_start, cur = None, []
if cur:
    chunks.append((cur_start, " ".join(cur)))

for t, txt in chunks:
    print(f"**[{t//60:02d}:{t%60:02d}]** {txt}\n")
