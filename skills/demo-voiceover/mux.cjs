'use strict';
// Lay the narration from cues.json over a ui-demo video and save an MP4.
// Usage: node mux.cjs <video.webm> <cues.json> [out.mp4]

const { execFileSync } = require('child_process');
const fs = require('fs');

const [video, cuesFile, outArg] = process.argv.slice(2);
if (!video || !cuesFile) {
  console.error('Usage: node mux.cjs <video.webm> <cues.json> [out.mp4]');
  process.exit(1);
}
const out = outArg || video.replace(/\.webm$/i, '') + '-voiced.mp4';
const cues = JSON.parse(fs.readFileSync(cuesFile, 'utf8'));
if (!cues.length) {
  console.error('cues.json is empty: no narrate() calls were recorded.');
  process.exit(1);
}

const args = ['-y', '-loglevel', 'error', '-i', video];
for (const c of cues) args.push('-i', c.file);

// Delay each line to its start time, then mix them into one track.
const delays = cues.map((c, i) => `[${i + 1}:a]adelay=${c.t}:all=1[a${i}]`);
const mixInputs = cues.map((_, i) => `[a${i}]`).join('');
const filter = `${delays.join(';')};${mixInputs}amix=inputs=${cues.length}:normalize=0[voice]`;

args.push(
  '-filter_complex', filter,
  '-map', '0:v', '-map', '[voice]',
  '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20',
  '-c:a', 'aac', '-b:a', '160k',
  '-movflags', '+faststart',
  out,
);

execFileSync('ffmpeg', args, { stdio: ['ignore', 'ignore', 'inherit'] });
console.log('Voiced video saved:', out);
