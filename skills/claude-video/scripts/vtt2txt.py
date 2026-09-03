#!/usr/bin/env python3
"""Turn a WebVTT caption file into timestamped plain text.

YouTube auto-captions repeat each line as a rolling window, so the same words
arrive two or three times in a row. Dedupe on the text, keep the first
timestamp it appeared at, and print one line per minute of video.

Usage: vtt2txt.py captions.vtt > transcript.md
"""
import re
import sys

TIMING = re.compile(r"(\d{2}):(\d{2}):(\d{2})\.\d{3}\s+-->")
TAG = re.compile(r"<[^>]+>")


def main(path):
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    out = []          # (seconds, text)
    seen = set()
    stamp = None

    for line in lines:
        m = TIMING.match(line.strip())
        if m:
            h, mm, s = (int(x) for x in m.groups())
            stamp = h * 3600 + mm * 60 + s
            continue
        text = TAG.sub("", line).strip()
        if not text or text.startswith(("WEBVTT", "Kind:", "Language:", "NOTE")):
            continue
        if text in seen:
            continue
        seen.add(text)
        out.append((stamp or 0, text))

    # Group into ~30s blocks so the transcript stays readable and citable.
    block, block_start = [], None
    for sec, text in out:
        if block_start is None:
            block_start = sec
        if sec - block_start >= 30 and block:
            print(f"[{block_start // 60:02d}:{block_start % 60:02d}] " + " ".join(block))
            block, block_start = [], sec
        block.append(text)
    if block:
        print(f"[{block_start // 60:02d}:{block_start % 60:02d}] " + " ".join(block))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: vtt2txt.py <file.vtt>")
    main(sys.argv[1])
