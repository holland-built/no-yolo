---
name: ship
description: Use when the user types /ship, or says "push this", "ship it", "push to github", "commit and push". Confers with Codex, updates the docs, refreshes the app screenshot if the UI changed, then commits and pushes.
user-invocable: true
disable-model-invocation: true
argument-hint: "[what changed, in a few words]"
allowed-tools: Bash,Read,Write,Edit,Glob,Grep
---

# ship

Five steps, in order. Never skip 1. Never reorder 4 and 5.

## 1. Look at what you are shipping

```bash
git status --short && git diff HEAD --stat && git diff HEAD
```

Nothing staged and nothing modified → say so and stop. No empty commits.

**Scan the diff for secrets before anything else.** API keys, tokens, `.env` contents,
private hostnames. Found one → stop, name the file and line, do not commit. Do not print
the value.

## 2. Confer with Codex

```bash
command -v codex >/dev/null || echo "NO_CODEX"
```

`NO_CODEX` → report `Codex: not installed — shipping unreviewed` and go to step 3.
A missing second opinion is a flag, not a blocker.

Otherwise, from the repo root:

```bash
{ cat "${CLAUDE_SKILL_DIR}/prompt.md"; git diff HEAD; } \
| codex exec -s read-only -C "$PWD" \
    --output-schema "${CLAUDE_SKILL_DIR}/verdict.schema.json" \
    -o /tmp/ship-verdict.json - >/dev/null 2>&1
```

Empty output, non-zero exit, or a hang → `Codex: did not run — <reason>` and continue.
Never let the reviewer failing become the reason nothing ships.

**Read every finding's `where` before you accept it.** Open the file at that line. Run
the `test` if it is a command. A finding you cannot see in the code is not a finding.

- Accepted → fix it now, then re-run step 1.
- Rejected → say which and why, in one line each.
- `severity: block` that you reject → **stop and ask the user.** That row only.

## 3. Update the docs

Only the docs this change actually invalidates. Find them:

```bash
git diff HEAD --name-only
ls README* docs/ 2>/dev/null
```

Write the way the user reads: **the answer first, a table over paragraphs, no preamble
and no closing summary.** A changelog line is one line. If the change does not alter
anything a reader was told, change no docs and say so.

Never write "improved", "enhanced" or "various fixes". Say what changed and what it now does.

## 4. Screenshot, if the UI changed

Only if the diff touches html, css, tsx, jsx, svelte, vue or astro **and** the repo already
keeps screenshots. Check first:

```bash
git diff HEAD --name-only | grep -qE '\.(html|css|tsx|jsx|svelte|vue|astro)$' && echo UI
ls docs/*.png docs/**/*.png *.png screenshots/ 2>/dev/null | head
```

No existing screenshots → skip. Do not invent a screenshots folder.

Otherwise run the app, open it in Chrome, capture the same view the old shot showed, at
the same width, and overwrite that file. **Read the screenshot you just took.** If it
looks wrong, fix the page — do not ship the picture as proof of something you did not look at.

## 5. Commit and push

```bash
git rev-parse --abbrev-ref HEAD
```

On the default branch → create a branch first. Then commit with a message that says what
changed and why, not what files moved. Push with `-u` on a new branch.

Never `--force`. Never `git add -A` without reading `git status --short` first.

## Report back

Six lines, this shape:

```
Shipped: <one line on what changed>
Codex:   ok / N findings, M accepted / did not run — <reason>
Docs:    <files touched, or "none needed">
Shot:    <file updated, or "n/a">
Branch:  <branch> → pushed
Next:    <the one thing left, or "nothing">
```

## Don't

- Don't push work Codex blocked and you overrode without asking.
- Don't update a doc to describe an intention. Only what the code now does.
- Don't claim a screenshot is current unless you took it this run.
