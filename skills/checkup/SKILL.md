---
name: checkup
description: Use this skill when the user types /checkup, says 'checkup', 'is my setup healthy', 'check my skills', 'list my skills', 'what hooks do I have', 'am I out of date', 'check for updates', or 'clean up my docs'. One read-only wellness pass over ~/.claude — inventory of what you actually have, doc duplication and orphans, skill trigger quality, drift against GitHub and against borrowed third-party code, what an outside skill library does better than yours, prose slop, memory lint. Reports in plain English and stops; you pick what to fix.
user-invocable: true
argument-hint: "(no arguments — one full read-only pass)"
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - AskUserQuestion
---

## What this is

The one maintenance command for your own setup. It reads, it reports, it stops. The only
thing it ever writes is nothing — every fix goes through the gate at the end.

It replaced five separate skills (`md-check`, `skill-audit`, `update`, `my-skills`, `my-md`),
each of which was one of these steps. If you find yourself wanting a sixth, add a step here
rather than a new skill — that sprawl is what this exists to prevent.

## Step 0 — Preflight (before any check)

- **Repo guard.** Confirm you're inside the `~/.claude` repo via `git rev-parse
  --show-toplevel`. If not, output one line — "Not in the ~/.claude repo — /checkup only runs
  here" — and stop.
- **Dirty worktree.** Run `git status --porcelain` up front, capture the pre-existing dirty
  set, and report it in the summary. Never stage, commit or bury unrelated edits.
- **Graceful degrade.** A missing dependency or no network SKIPs that check with a noted
  reason. Never crash, never silently drop it.
- **Partial failure.** One check erroring is captured and reported; it does not abort the rest.
- **Read-only.** This skill writes nothing. A check that wants to write is a finding, not an
  action.

## Step 1 — Plumbing

```bash
bash verify.sh
```
Parse the PASS/FAIL rows. Every FAIL is a finding.

`verify.sh` sits at the repo root, which Step 0 has already confirmed is the working directory.
Read that path as `~/.claude/verify.sh`, not as a file beside this skill — on 2026-08-05 a pass
over this repo looked for it in `skills/checkup/`, found nothing, and reported the whole step
dead while all sixteen of its checks were passing. Confirm where a relative path resolves before
you call it missing.

## Step 1.5 — Prove the guards bite

A guard nobody has watched fail is not a guard, it is a belief. Step 1 proves a hook's file
is still on disk. This step proves the hook still refuses something.

Real suites already live in `hooks/tests/` — one per hook, each feeding it a deliberately bad
event on stdin and asserting it refuses. Run those. They are also what `verify.sh` checks 1
and 1b run, so this step reuses the repo's own proof rather than starting a second one.

```bash
for f in hooks/tests/*.test.js hooks/tests/*.test.sh; do
  n=$(basename "$f"); n=${n%.test.js}; n=${n%.test.sh}
  if [ "${f##*.}" = "js" ]; then out=$(node --test "$f" 2>&1); st=$?
    c=$(printf '%s\n' "$out" | sed -n 's/^. pass \([0-9]*\)$/\1/p' | tail -1)
  else out=$(bash "$f" 2>&1); st=$?; c=$(printf '%s\n' "$out" | grep -c '^PASS'); fi
  [ -z "$c" ] && c=0
  if [ "$st" = "0" ] && [ "$c" -gt 0 ]; then echo "| $n | PASS | $c checks |"
  elif [ "$st" = "0" ]; then echo "| $n | FAIL | ran but asserted nothing |"
  else echo "| $n | FAIL | suite exited $st |"; fi
done
for h in hooks/*.js hooks/*.sh hooks/pre-commit; do
  n=$(basename "$h"); b=${n%.js}; b=${b%.sh}
  if [ ! -e "hooks/tests/$b.test.js" ] && [ ! -e "hooks/tests/$b.test.sh" ]; then
    echo "| $n | NOT PROVEN | no suite — nothing has watched it refuse |"
  fi
done
```

Report every printed line as a row: `| Hook | Result | Evidence |`. Treat a hook that
produced no row as a FAIL and chase it down. **Count the assertions, and treat the exit code
as only half the answer** — a suite that runs and asserts nothing exits 0 and reads exactly
like a suite that proved something. `verify.sh` check 1b has that shape today: with zero
shell suites on disk it records PASS.

Two rows come from the route-map skill's driver (`route-check`, `route-check-units`), not
from a hook. Keep them — they run here because they share the folder — and label them as
such so the count is honest.

What each hook can be asked to prove, and what it cannot:

| Hook | Kind | What a row means |
|---|---|---|
| `lockstep-guard.js` | blocking | Exits 2 with a message on stderr. **It only blocks while lockstep is engaged** — with no `.lockstep-active` flag it exits 0, and that is correct behaviour rather than a miss. Its suite drives both states, so PASS covers both |
| `config-protection.js` | blocking | Exits 2 when an *existing* checker config is edited. Creating one for the first time passes by design |
| `slop-guard.js` | blocking | Refuses a different way: exit code 0 with `{"decision":"block"}` on **stdout**. Judging this one by exit code alone would score every block as a pass |
| `secret-scan.sh` | blocking | The scanner `pre-commit` calls for credentials and infra values |
| `node-shim.sh` | launcher | Not a guard, but it is what starts them, and it fails closed when node is missing |
| `format-typecheck.js` | SKIPPED as a guard | Warns and always exits 0 on purpose — it runs after the reply is already written. Its suite still runs above |
| `mockup-autoopen.js`, `eli5-activate.js`, `literal-mode-tracker.js` | SKIPPED | They open, activate and track. There is nothing here for them to refuse |
| `statusline.sh`, `literal-statusline.sh` | SKIPPED | They draw the status line |
| `pre-commit` | blocking | Exits 1 and prints `❌ BLOCKED:` naming the rule that fired. It judges a real staged index, so its suite builds a throwaway git repo in a mktemp sandbox and installs the tracked hook there — this repo's index is never touched. Proved in both directions: it refuses a staged credential value, a staged infra value, a blocked personal path and a scanner it cannot run, and it allows a clean file. Planted values come from the pinned probe fixture, never written inline |

## Step 2 — Inventory (what you actually have)

Derive it live from the filesystem. Never read a stored catalogue — a catalogue that has to
be kept in sync is the thing this setup deleted.

```bash
echo "=== skills (own vs borrowed) ==="
for d in skills/*/; do n=$(basename "$d")
  if [ -L "${d%/}" ]; then echo "  borrowed  $n -> $(readlink "${d%/}")"
  else echo "  own       $n"; fi
done
echo "=== agents ==="; ls -1 agents/*.md 2>/dev/null | xargs -n1 basename
echo "=== hooks wired in settings.json ==="
python3 -c "import json,re;d=json.load(open('settings.json'));[print(f'  {ev:18} {re.sub(r\".*/hooks/\",\"\",h.get(\"command\",\"\"))[:50]}') for ev,arr in d.get('hooks',{}).items() for m in arr for h in m.get('hooks',[])]"
echo "=== docs ==="; wc -l docs/*.md *.md 2>/dev/null | sort -rn | head -30
```

Report as one table: `| Kind | Name | Own or borrowed | Note |`. Borrowed items are managed by
the `skills` installer (`~/.agents/.skill-lock.json`) — deleting the shortcut does nothing,
so never recommend that. Recommend the installer instead.

## Step 3 — Doc hygiene

**Duplicate rules.** For every `.md` under `docs/` and the repo root, extract rule-shaped
lines (imperative sentences, bullet rules, table rows stating a constraint). Report any rule
appearing in two files:

`| Rule (truncated) | File A:line | File B:line |`

**Topic overlap.** Compare `## ` heading sets between every pair of docs. Report pairs sharing
more than half their headings: `| File A | File B | Shared headings |`

**Orphans, both directions:**
- Any tracked file naming a doc, skill, hook, agent or script that isn't on disk → **dangling**
- A doc on disk that nothing reads → **unreferenced**

```bash
for f in docs/*.md; do b=$(basename "$f")
  n=$(grep -rl "$b" CLAUDE.md README.md INSTALL.md SHIP.md skills/ hooks/ docs/ 2>/dev/null | grep -v "^$f$" | wc -l | tr -d ' ')
  [ "$n" = "0" ] && echo "  unreferenced: $b"
done
git ls-files -- '*.md' | while read -r src; do
  grep -v 'gone-on-purpose' "$src" \
    | grep -oE '`(docs|skills|hooks|agents|commands)/[A-Za-z0-9._/-]+\.(md|sh|js|py|mjs|json)`' \
    | tr -d '`' | while read -r p; do
        [ -e "$p" ] || [ -e "$(dirname "$src")/$p" ] || echo "  dangling: $p  (in $src)"
      done
done | sort -u
```

The dangling sweep is deliberately built this way; the earlier version missed a real outage.
It only looked at `CLAUDE.md` and `skills/*/SKILL.md`, and only for absent `docs/*.md` — so it
never read `SHIP.md`, and could not see references to deleted **skills, hooks or scripts**. On
2026-08-05 that blind spot had let `SHIP.md` accumulate five dead references, two inside HARD
BLOCK steps, which would have stopped every release. Three details carry their weight:

| Detail | Why |
|---|---|
| `git ls-files`, not a directory walk | only tracked files can break a release for someone else, and walking drags in gitignored vendor folders nobody edits here |
| backtick-quoted paths only | this repo cites real files in backticks; bare text floods on substrings — the tail of `ingest-docs/SKILL.md` looks like a docs path |
| marker filtered per line, before extraction | `grep -o` prints only the match and discards its line, so filtering afterwards can never see the marker |

Prose that names a deleted file on purpose carries `<!-- gone-on-purpose -->` on that line. That
marker is for history and rationale only — never to silence a reference something still follows.

**Drift.** A skill's `description` frontmatter is its contract. Report any skill whose
description names a mode, flag or file that its own body no longer contains.

## Step 4 — Skill structure

For each **own** skill (skip borrowed — you can't edit those):

| Dimension | The question | Flag when |
|---|---|---|
| One job | Does it do a single thing, or straddle two? | Its description names two unrelated jobs |
| Triggers | Would the description actually fire on how you'd phrase it? | Vague ("helps with code"), or no trigger phrases at all |
| Verifier | Does it check its own output before claiming done? | It produces something and asserts nothing |
| Dead reference | Does it point at a file, skill or agent that exists? | Any cited path, `Skill tool` name or `subagent_type` missing |

Dead references are the highest-value check here — a skill quietly pointing at something you
deleted keeps working right up until the moment it matters.

```bash
for f in skills/*/SKILL.md; do
  grep -v 'gone-on-purpose' "$f" \
    | grep -ohE '~/\.claude/[a-zA-Z0-9/_.-]+\.(md|sh|js|py|mjs|json)\b' | sort -u | while read p; do
        ep="${p/#\~/$HOME}"; [ -e "$ep" ] || echo "  $(basename $(dirname $f)): dead path $p"
      done
done
```

Two details keep this honest; without them it reported three dead paths on 2026-08-06 and all
three were wrong. `json` has to be in the alternation *and* followed by `\b` — with neither,
`~/.claude/settings.json` matches as a phantom `.js` path, and a genuinely missing
`.json` file can never be reported at all. And the `gone-on-purpose` marker is filtered per line
before extraction, for the reason Step 3 gives: `grep -o` discards the line it matched, so a
filter placed after it never sees the marker.

## Step 5 — Drift against the outside world

**Behind or ahead of GitHub:**
```bash
git fetch -q origin 2>/dev/null
git rev-list --left-right --count origin/main...HEAD 2>/dev/null   # behind<TAB>ahead
git status --short
```
Ahead or dirty → the finding is "unpublished work", and it points at `/release`, never at an
automatic push.

**Borrowed third-party code.** For each vendored directory and each cloned marketplace,
compare the pinned commit against upstream. Report drift; never pull it automatically.
```bash
for d in plugins/marketplaces/*/; do
  [ -d "$d/.git" ] && echo "  $(basename $d): $(git -C "$d" rev-parse --short HEAD 2>/dev/null) $(git -C "$d" fetch -q 2>/dev/null; git -C "$d" rev-list --count HEAD..@{u} 2>/dev/null) behind"
done
```

**Borrowed skills.** Read `~/.agents/.skill-lock.json` and report anything installed but no
longer read by any surviving skill — a candidate for `npx skills` removal, your call.

**Ghost entries — on the list, no files.** These are the dangerous ones.

```bash
python3 - <<'PY'
import json, os
skills = json.load(open(os.path.expanduser('~/.agents/.skill-lock.json'))).get('skills', {})
bases = [os.path.expanduser('~/.agents/skills'), os.path.expanduser('~/.claude/.agents/skills')]
ghosts = [(n, (m.get('source', '?') if isinstance(m, dict) else '?'))
          for n, m in sorted(skills.items())
          if not any(os.path.isdir(os.path.join(b, n.split(':')[-1])) for b in bases)]
print(f"| listed | {len(skills)} | | real | {len(skills) - len(ghosts)} | | ghosts | {len(ghosts)} |")
for n, s in ghosts:
    print(f"| {n} | GHOST | from {s} — delete from the list |")
PY
```

A ghost is an entry the installer still believes in, pointing at files that are not there. It
reads as harmless and is not: `npx skills update` treats "listed, files missing" as **out of
date**, so an update downloads the package and links it into `skills/`, where it loads. A
routine update is therefore an install.

Report every ghost as **rot to delete**, and recommend `npx skills remove <names>` — never an
update, and never an install. Say the count in the summary even when it is large; a number
this size is the finding.

Run `npx skills` from the **home directory**. Run from inside `~/.claude` it reads a different
scope, finds nothing, and reports "no matching skills" for entries that plainly exist.

The whole shape of this check comes from one afternoon: on 2026-08-06, `npx skills update`
was run here to refresh borrowed code. Nine ghost packages were downloaded and switched on
without being asked for, and four `obra/superpowers` ghosts — a library removed weeks earlier
— were one update away from returning. Nothing was corrupt. The list was simply believed.

## Step 5.5 — Learn from the outside

Step 5 asks whether borrowed code has moved. This asks a different question: **what does
someone else's skill library do better than mine?** The library is
[`mattpocock/skills`](https://github.com/mattpocock/skills) (public, MIT).

**It is deliberately not installed, and staying that way is the decision.** Read it, borrow
ideas from it, leave it uninstalled — this step recommends no installer command.

Already harvested from the full comparison run on 2026-08-06: `handoff`, prove-the-guards-bite
(Step 1.5 above), `docs/AGENT_WRITING.md`, and the plain-language rules now in `/eli5`. Treat
those four as settled and spend the pass on everything else.

**1. List his skills, and prove the list is real.**

```bash
list=$(gh api "repos/mattpocock/skills/git/trees/main?recursive=1" \
  --jq '.tree[] | select(.path|endswith("SKILL.md")) | .path' 2>/dev/null | grep '/SKILL\.md$')
n=$(printf '%s' "$list" | grep -c .)
if [ "$n" -gt 0 ]; then echo "| outside library | OK | $n skills found |"
else echo "| outside library | FAIL | could not reach the repo — 0 skills read |"; fi
```

Quote the URL — an unquoted `?` stops zsh before `gh` runs. Keep the `grep '/SKILL\.md$'`
filter and count the surviving lines: **on failure `gh api` prints its error JSON to stdout,
not stderr**, so a plain "is the variable empty" test reads a 404 body as a full result. When
the count is zero, print that FAIL row. Reaching the network and finding nothing is a finding,
never silence — Step 1.5 exists because a check that printed nothing was read as passing.

**2. Read each one's `name` and `description`, and nothing more.**

```bash
printf '%s\n' "$list" | while read -r p; do
  gh api "repos/mattpocock/skills/contents/$p" --jq .content | base64 -d \
    | awk '/^---$/{n++; next} n==1' | grep -E '^(name|description):' | tr '\n' ' '; echo
done
```

Frontmatter answers the question; whole bodies cost a lot and add little. A full pass reads
every skill on the list. If you ever do stop short, print the number you skipped in the output
— a silent cap reads as full coverage.

**3. Derive my own skills live.** Own skills only; a symlinked folder is borrowed, so skip it.
Derive this every time rather than reading a stored catalogue.

```bash
for d in skills/*/; do [ -L "${d%/}" ] && continue; [ -f "$d/SKILL.md" ] || continue
  awk '/^---$/{n++; next} n==1 && /^(name|description):/' "$d/SKILL.md" | head -2 \
    | cut -c1-90 | tr '\n' ' '; echo
done
```

**4. One table.**

`| His skill | Closest one of mine | What his does that mine doesn't | Worth a look? |`

| Rule | What it means |
|---|---|
| Name the mechanism | "He has X and you don't" teaches nothing. Say what his skill actually *does* differently — the step it takes, the gate it holds, the file it writes |
| Mark the gaps | Where nothing of mine is close, put `no equivalent` in column two. Those rows are the point of the step |
| Drop the empties | Where his adds nothing, leave the row out and say how many rows you dropped |

**5. Close with this.** This step installs nothing and changes nothing. The owner picks what
is worth acting on at Step 10.

## Step 6 — Prose slop

Read `~/.claude/docs/ANTISLOP.md`, then check the repo's own prose against the writing tells —
`README.md`, `INSTALL.md`, and every file in `docs/`. Diagnosis only.

This matters more here than in code: creative user-facing prose is where slop actually ships.

## Step 7 — Memory lint

```bash
python3 memory/bin/memory_compile.py 2>&1 | tail -20
```
Read the lint output; record findings. Flag any fact file with no `type:`, a duplicate of
another fact, or a `[[link]]` pointing at a fact that doesn't exist.

## Step 8 — Learnings staleness

Check whether `learnings.md` has a section for the current model ID. Stale → surface a finding
recommending `/better-prompt --refresh`. **Never auto-run it** — it fetches the web and
rewrites the file. Opt-in only.

## Step 9 — One plain summary, then STOP

Plain English, table-shaped, no jargon. Disclose:
- Any check that was skipped, and why
- The pre-existing dirty set from Step 0
- Nothing was written — this pass is read-only

`| Area | Finding | Severity | Fixable |`

Then stop. Do not start fixing.

## Step 10 — Staged gate (never a blanket OK)

The user first **selects** which findings to act on. Then `/build --plan-only` on those; the
resulting plan gets its own approval before any edit; then build; then `/release`, which keeps
its own publish gate. `/checkup` never pushes, and never fixes something you didn't pick.
