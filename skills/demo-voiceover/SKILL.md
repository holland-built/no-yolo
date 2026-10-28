---
name: demo-voiceover
description: Add a spoken voiceover to a ui-demo screen recording, so the demo video talks as well as showing captions. Use with the ui-demo skill whenever the user wants a demo, walkthrough or tutorial video that is narrated, voiced, talks, has audio, or has a voiceover, and to add a voiceover to a demo recorded earlier.
---

# demo-voiceover

This skill adds speech to the ui-demo skill. ui-demo still does discovery, rehearsal, the cursor and the
subtitle bar. This skill adds a voice that reads each subtitle aloud, then saves the result as an MP4,
which plays anywhere. The WebM that ui-demo makes plays without sound in most email clients and in
PowerPoint.

It lives apart from ui-demo, which is a third-party skill, so that `npx skills update` cannot
overwrite it. Leave ui-demo's own files unchanged.

Everything runs locally on macOS. The `say` command makes the speech and `afinfo` measures it. Both
come with macOS. ffmpeg merges the audio and video; install it with `brew install ffmpeg` if it is
missing.

## Files

- [narrate.cjs](narrate.cjs): `createNarrator(outDir)` returns `start()`, `prepare(lines)`,
  `say(page, text, showSubtitle, {caption, pad})` and `finish()`.
- [mux.cjs](mux.cjs): `node mux.cjs <video.webm> <cues.json> [out.mp4]` lays each spoken line over
  the video at its start time and writes the MP4.

## Wiring it into a ui-demo script

```javascript
const { createNarrator } = require(require('path').join(process.env.HOME, '.claude/skills/demo-voiceover/narrate.cjs'));
const narrator = createNarrator(VIDEO_DIR);
const LINES = ['Here is the dashboard.', 'Now we create a request.'];

// rehearsal branch: make the audio ahead of time, so recording never pauses to make it
narrator.prepare(LINES);

// recording branch
const page = await context.newPage();
narrator.start();                       // straight after newPage(), when the video starts
await narrator.say(page, LINES[0], showSubtitle);   // speaks, captions, waits until done
// ...after context.close() and saving the video:
narrator.finish();                      // writes cues.json
```

Then run `node ~/.claude/skills/demo-voiceover/mux.cjs <video.webm> <VIDEO_DIR>/cues.json`.

`narrator.say` takes the place of `showSubtitle` wherever a line should be heard, and it waits until
the line has been spoken. A second fixed pause after it only adds dead air. Keep the cursor still
while a line plays and do the action afterwards. When a click and a sentence happen together, the
viewer misses one of them. Pass a shorter `caption` when the spoken line is too long for the
subtitle bar. ui-demo wants captions under 60 characters.

## Writing the narration

The narration is written for the person watching, not as a list of what the robot clicks. One or
two short sentences for each step, in plain words, saying what the viewer gets out of each screen.
Read aloud, the whole script runs at about 175 words a minute, so a 60-second demo has room for
about 150 words.

The default voice is Samantha. Set `DEMO_VOICE` to use another voice, for example `Daniel` (British)
or `Reed (English (US))`; `say -v '?'` lists them all. Set `DEMO_RATE` to change the speed in words
per minute. A changed voice or speed makes new audio files, because the cache is keyed on both.

## Done

The MP4 has a video stream and an audio stream (`ffprobe -v error -show_entries
stream=codec_type -of csv <file>`). A frame grabbed partway through a spoken line shows that line's
caption. Before you call it finished, watch or listen to the start of the file yourself. Give the
user the full path of the MP4.
