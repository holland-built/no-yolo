---
name: claude-video
description: Watch a YouTube video and ingest it into the Knowledge Base vault - pulls the transcript, writes an immutable raw transcript, a wiki source page, updates topic pages, index.md and log.md. Use when given a YouTube URL to watch, ingest, summarise, or add to the vault. Also handles "just watch" (summarise in chat and stop).
---

# claude-video

Ingest a YouTube video into `~/AI/Knowledge Base`.

## Modes

- **watch** (default) — full ingest: raw transcript + wiki source page + topic updates + index + log.
- **just watch** — read the transcript and summarise in chat. The vault ends the run exactly
  as it started. Use when the user says "just watch" or "don't save".

Ask which only if genuinely unclear. A bare URL means full ingest.

## Steps

### 1. Read the vault rules

`~/AI/Knowledge Base/CLAUDE.md` owns the page schemas, the topic prefixes, the slug format,
and the ingest workflow. Read it before writing anything.

Everything below is the video-specific part, including the one naming rule that file does
not cover: video source pages are slugged `vid-<kebab-case>`, max 5 words.

### 2. Get metadata and transcript

Prefer real captions. Only fall back to Whisper if there are none — it is slow and the
log records which was used.

```bash
cd /tmp
yt-dlp --skip-download --print "%(title)s\n%(channel)s\n%(upload_date)s\n%(duration)s\n%(id)s" "<URL>"
yt-dlp --skip-download --write-auto-subs --write-subs --sub-lang "en.*" --sub-format vtt -o "%(id)s" "<URL>"
```

If a `.vtt` appeared, `transcript_source: captions`. Strip the VTT timing/markup to plain
text with timestamps at paragraph starts.

If no captions exist:
```bash
yt-dlp -f bestaudio -x --audio-format mp3 -o "%(id)s.%(ext)s" "<URL>"
whisper "<id>.mp3" --model small --output_format txt
```
Then `transcript_source: whisper`.

### 3. Write the raw transcript — `raw/videos/vid-<slug>.md`

Write this file once. It is immutable.

```markdown
---
title: <video title>
source_type: video
url: <URL>
channel: <channel>
date_ingested: <today>
upload_date: <YYYY-MM-DD>
duration_seconds: <n>
transcript_source: captions | whisper
---

## Transcript

[00:05] ...
```

### 4. Write the source page — `wiki/sources/vid-<slug>.md`

Follow the source-summary format in the vault's `CLAUDE.md`: frontmatter with
`type: source`, `raw_path`, `topics`, then `## Summary`, `## Key Claims`,
`## Connections`, `## Quotes`. Link only pages that exist; name everything else as plain
text.

Two additions that make these pages worth rereading:

- **`## Evidence`** — verbatim screen content, tables, file listings, commands. This is what
  makes a page useful six months later; a summary alone is not.
- **`## Worth Trying`** — only when the video contains something actionable for this user.
  Say plainly what to skip, too.

Quality bar: be a critical reader, not a transcriber. Promotional sources get their numbers
checked. Note where a claim contradicts something already in the vault, and say which source
you find more credible and why.

### 5. Update topics

Revise the relevant `wiki/topics/{ai,ha}/*.md` pages — overview, key ideas, and any new
tension in **Debates / Open Questions**. Add the source to that page's `## Sources` list and
bump `source_count` / `last_updated`. Create a topic page only if the subject genuinely
recurs across sources.

### 6. Update `index.md`, then append to `log.md`

```
## [YYYY-MM-DD] video | <Title>
- wiki/sources/vid-<slug>.md
- <one line: the single most transferable idea, or why it was thin>
```

### 7. Report

Three lines in chat: what it was, the best idea in it, whether it changed a topic page.

## Cleanup

Delete the `/tmp` vtt/mp3/txt working files when done.
