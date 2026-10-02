#!/usr/bin/env python3
"""prune-stale: removes the raw transcripts of old tool-news videos from the notes vault, the way the
vault's own pruning rule allows. Dry run unless given --apply.

  python3 prune_stale.py <vault> [--apply] [--days 30] [--max 5]

A video qualifies when its source page (wiki/sources/vid-*.md, type source, source_type video) was
ingested more than --days ago, is tagged only to tool-* topics (tool news dates quickly; pattern and
concept ideas do not), and still has a raw transcript at exactly raw/videos/<page name>.md that is a
real file, not a link. Nothing is pruned if another page, the index or the log mentions that raw file.
A video whose raw_path is anything else, or that resolves outside raw/videos, is skipped and reported.

More than --max (default 5) candidates in one run are listed but not pruned: that many at once is a
reason for a person to look first.

When applying, in this order, so a failure leaves things as they were:
  1. copy every transcript to <vault's parent>/backups/vault-prune-<date>/ and compare each copy byte
     for byte with the original, before anything is changed,
  2. for each one, set the page's raw_path to null with a dated comment (the page stays, so every link
     still resolves), then delete the raw file; if the delete fails, the page is put back,
  3. append one entry to log.md under a "prune |" heading. The log is only ever appended to.
The vault's own git history also holds the deleted files.
"""
import datetime, filecmp, glob, os, re, shutil, sys

DAYS = 30
MAX_PER_RUN = 5


def field(front, name):
    m = re.search(rf"^{name}:\s*(.*)$", front, re.M)
    return m.group(1).strip().strip('"') if m else ""


def frontmatter(text):
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    return m.group(1) if m else ""


def mentions(vault, needle, page):
    """Pages, the index or the log (other than `page`) that name the raw file, with or without .md."""
    paths = glob.glob(os.path.join(vault, "wiki", "**", "*.md"), recursive=True)
    paths += [os.path.join(vault, n) for n in ("index.md", "log.md") if os.path.exists(os.path.join(vault, n))]
    hits = []
    for path in paths:
        if os.path.abspath(path) == os.path.abspath(page):
            continue
        with open(path) as f:
            if needle in f.read():
                hits.append(os.path.basename(path))
    return hits


def candidates(vault, today, days=DAYS):
    for folder in ("raw", os.path.join("raw", "videos")):
        if os.path.islink(os.path.join(vault, folder)):
            return [], [{"slug": "(vault)", "why": f"{folder} is a symlink, so nothing under it is trusted"}]
    videos = os.path.realpath(os.path.join(vault, "raw", "videos"))
    found, skipped = [], []
    for page in sorted(glob.glob(os.path.join(vault, "wiki", "sources", "vid-*.md"))):
        with open(page) as f:
            front = frontmatter(f.read())
        if field(front, "type") != "source" or field(front, "source_type") != "video":
            continue
        raw = field(front, "raw_path")
        if not raw or raw.startswith("null"):
            continue
        try:
            ingested = datetime.date.fromisoformat(field(front, "date_ingested"))
        except ValueError:
            continue
        topics = re.findall(r"[\w-]+", field(front, "topics").strip("[]"))
        if (today - ingested).days <= days or not topics or not all(t.startswith("tool-") for t in topics):
            continue
        slug = os.path.basename(page)[:-3]
        if raw != f"raw/videos/{slug}.md":
            skipped.append({"slug": slug, "why": f"raw_path says {raw!r}, not raw/videos/{slug}.md"})
            continue
        raw_abs = os.path.join(vault, raw)
        if os.path.islink(raw_abs):
            skipped.append({"slug": slug, "why": "the raw file is a symlink"})
            continue
        if not os.path.isfile(raw_abs):
            continue
        if os.path.commonpath([os.path.realpath(raw_abs), videos]) != videos:
            skipped.append({"slug": slug, "why": "the raw file resolves outside raw/videos"})
            continue
        refs = mentions(vault, f"raw/videos/{slug}", page)
        if refs:
            skipped.append({"slug": slug, "why": "still mentioned in " + ", ".join(sorted(set(refs)))})
            continue
        found.append({"slug": slug, "page": page, "raw": raw, "raw_abs": raw_abs, "size": os.path.getsize(raw_abs)})
    return found, skipped


def write_atomic(path, text):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def prune(vault, found, today, days=DAYS):
    backup = os.path.join(os.path.dirname(os.path.abspath(vault)), "backups", f"vault-prune-{today.isoformat()}")
    os.makedirs(backup, exist_ok=True)
    if os.path.islink(backup):
        raise OSError(f"{backup} is a symlink; nothing was changed")
    for c in found:  # 1. every backup, checked byte for byte, before anything changes
        copy = os.path.join(backup, c["slug"] + ".md")
        if os.path.islink(copy):
            raise OSError(f"{copy} is a symlink, not a backup; nothing was changed")
        if os.path.exists(copy):
            if not filecmp.cmp(c["raw_abs"], copy, shallow=False):
                raise OSError(f"{copy} already exists with different content; nothing was changed")
        else:
            shutil.copy2(c["raw_abs"], copy)
        if not filecmp.cmp(c["raw_abs"], copy, shallow=False):
            raise OSError(f"the backup of {c['slug']} does not match the original; nothing was changed")
    done = []
    try:
        for c in found:  # 2. page first, then the file; put the page back if the delete fails
            with open(c["page"]) as f:
                original = f.read()
            write_atomic(c["page"], re.sub(
                r"^raw_path:.*$", f"raw_path: null  # transcript pruned {today.isoformat()} (tool news, over {days} days old)",
                original, count=1, flags=re.M))
            try:
                os.remove(c["raw_abs"])
            except OSError:
                write_atomic(c["page"], original)
                raise
            done.append(c)
    finally:  # 3. log whatever was deleted, even if a later one failed. Append only.
        if done:
            log = os.path.join(vault, "log.md")
            with open(log, "rb") as f:
                f.seek(0, os.SEEK_END)
                ends_with_newline = f.tell() == 0 or (f.seek(-1, os.SEEK_END) or f.read(1)) == b"\n"
            kb = round(sum(c["size"] for c in done) / 1024)
            entry = (f"\n## [{today.isoformat()}] prune | Removed {len(done)} stale video transcripts\n"
                     f"- Deleted raw/videos for: {', '.join(c['slug'] for c in done)}\n"
                     f"- Kept all wiki/sources pages so every [[wikilink]] still resolves; `raw_path` set to null on those {len(done)}. "
                     f"{kb} KB reclaimed. Backup: {backup}\n")
            with open(log, "a") as f:
                f.write(("" if ends_with_newline else "\n") + entry)
    return backup


def run(vault, today, apply=False, days=DAYS, limit=MAX_PER_RUN):
    found, skipped = candidates(vault, today, days)
    out = [f"Skipped {s['slug']}: {s['why']}." for s in skipped]
    if not found:
        out.append("Nothing to prune.")
        return "\n".join(out)
    listing = [f"  - {c['slug']}  ({round(c['size'] / 1024)} KB)" for c in found]
    if apply and len(found) > limit:
        out.append(f"{len(found)} candidates is more than the limit of {limit}, so none were pruned:")
        out += listing
        out.append(f"Look at the list, then run again with --apply --max {len(found)} if it is right.")
        return "\n".join(out)
    if apply:
        prune(vault, found, today, days)
    out.append(f"{'Pruned' if apply else 'Would prune'} {len(found)} raw transcript(s), kept their source pages:")
    out += listing
    if not apply:
        out.append("Dry run. Run again with --apply to do it.")
    return "\n".join(out)


def whole_number(args, name, default):
    if name not in args:
        return default
    try:
        n = int(args[args.index(name) + 1])
        if n < 1:
            raise ValueError
        return n
    except (ValueError, IndexError):
        sys.exit(f"{name} needs a whole number above zero")


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args or args[0].startswith("--"):
        sys.exit("usage: prune_stale.py <vault> [--apply] [--days N] [--max N]")
    print(run(args[0], datetime.date.today(), apply="--apply" in args,
              days=whole_number(args, "--days", DAYS), limit=whole_number(args, "--max", MAX_PER_RUN)))
