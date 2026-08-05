---
name: checkup
description: Use this skill when the user types /checkup, says 'checkup', 'is my setup healthy', 'check my skills', 'list my skills', 'what hooks do I have', 'am I out of date', 'check for updates', or 'clean up my docs'. One read-only wellness pass over ~/.claude — inventory of what you actually have, doc duplication and orphans, skill trigger quality, drift against GitHub and against borrowed third-party code, prose slop, memory lint. Reports in plain English and stops; you pick what to fix.
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
- A doc referenced by `CLAUDE.md` or a skill that doesn't exist on disk → **dangling**
- A doc on disk that nothing reads → **unreferenced**

```bash
for f in docs/*.md; do b=$(basename "$f")
  n=$(grep -rl "$b" CLAUDE.md skills/ hooks/ docs/ 2>/dev/null | grep -v "^$f$" | wc -l | tr -d ' ')
  [ "$n" = "0" ] && echo "  unreferenced: $b"
done
grep -ohE 'docs/[A-Z_]+\.md' CLAUDE.md skills/*/SKILL.md 2>/dev/null | sort -u | while read p; do
  [ -f "$p" ] || echo "  dangling: $p"
done
```

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
  grep -ohE '~/\.claude/[a-zA-Z0-9/_.-]+\.(md|sh|js|py|mjs)' "$f" | sort -u | while read p; do
    ep="${p/#\~/$HOME}"; [ -e "$ep" ] || echo "  $(basename $(dirname $f)): dead path $p"
  done
done
```

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
