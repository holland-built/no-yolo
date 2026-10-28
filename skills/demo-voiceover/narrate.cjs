'use strict';
// Spoken narration for ui-demo recordings, using the macOS `say` command.
// narrate() speaks a line into an audio file, shows it as the subtitle, and
// holds the screen until the line has finished. Each line's start time goes
// into cues.json, which mux.cjs uses to lay the audio over the video.

const { execFileSync } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const VOICE = process.env.DEMO_VOICE || 'Samantha';
const RATE = process.env.DEMO_RATE || '175'; // words per minute

function createNarrator(outDir) {
  const audioDir = path.join(outDir, 'voice');
  fs.mkdirSync(audioDir, { recursive: true });
  const cues = [];
  let startedAt = null;

  // Make (or reuse) the audio for one line. Cached by text, so the rehearsal
  // run does the slow part and the recording run does not pause for it.
  function synth(text) {
    const id = crypto.createHash('sha1').update(`${VOICE}|${RATE}|${text}`).digest('hex').slice(0, 12);
    const file = path.join(audioDir, `${id}.aiff`);
    if (!fs.existsSync(file)) execFileSync('say', ['-v', VOICE, '-r', RATE, '-o', file, text]);
    const info = execFileSync('afinfo', [file]).toString();
    const m = info.match(/estimated duration:\s*([\d.]+)/);
    if (!m) throw new Error(`Could not read audio length of ${file}`);
    return { file, ms: Math.round(parseFloat(m[1]) * 1000) };
  }

  return {
    // Call right after context.newPage() in the recording run: the video starts then.
    start() {
      startedAt = Date.now();
    },

    // Rehearsal: make every line's audio ahead of time without a page.
    prepare(lines) {
      for (const line of lines) synth(line);
    },

    // Speak `text`, show it as the subtitle, and wait until it has been said.
    // `showSubtitle` is ui-demo's helper; pass it in so the bar stays in sync.
    async say(page, text, showSubtitle, { caption = text, pad = 400 } = {}) {
      const { file, ms } = synth(text);
      if (startedAt === null) throw new Error('narrator.start() was not called after newPage()');
      cues.push({ t: Date.now() - startedAt, file, text });
      if (showSubtitle) await showSubtitle(page, caption);
      await page.waitForTimeout(ms + pad);
    },

    // Write cues.json next to the video. Call after context.close().
    finish() {
      const out = path.join(outDir, 'cues.json');
      fs.writeFileSync(out, JSON.stringify(cues, null, 2));
      console.log('Narration cues saved:', out);
      return out;
    },
  };
}

module.exports = { createNarrator };
