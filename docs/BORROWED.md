# Borrowed code — the registration manifest

Every piece of code in this setup that somebody else wrote. If it is not in the table below,
`/checkup` reports it as **UNREGISTERED** and you either register it or delete it. That is the
whole point of the file: the failure this replaces was a drift check that looked at four
directories, found one it could not read, and printed nothing at all.

The borrowed code itself is gitignored and never published (`plugins/`,
`skills/design/vendor/`, `.agents/`). This manifest is tracked, so the record of what was
borrowed survives even though the copies do not.

`skills/checkup/scripts/borrowed_check.py` parses the table below and is strict about it: a
missing column, a duplicate name, an unknown check method, or an empty table is a hard error,
not a warning. A manifest that half-parses would drop the rows it could not read, which is the
original bug wearing a different hat.

## Manifest

| Name | Kind | Path | Upstream | Pinned | Content hash | How checked | Licence |
|---|---|---|---|---|---|---|---|
| design-plugins | marketplace | plugins/marketplaces/design-plugins | https://github.com/0xdesign/design-plugin | tracked branch | n/a | git | unknown — no LICENSE file |
| impeccable | marketplace | plugins/marketplaces/impeccable | https://github.com/pbakaus/impeccable | tracked branch | n/a | git | see LICENSE in tree |
| openai-codex | marketplace | plugins/marketplaces/openai-codex | https://github.com/openai/codex-plugin-cc | tracked branch | n/a | git | see LICENSE in tree |
| claude-plugins-official | marketplace | plugins/marketplaces/claude-plugins-official | https://github.com/anthropics/claude-plugins-official | .gcs-sha | machine-managed | hash | see LICENSE in tree |
| taste-skill | vendored | skills/design/vendor/taste-skill | https://github.com/Leonxlnx/taste-skill | e988add20dab0fa97d7a76781c48961c8184288e | a9e222741a8cd9e73e70cc3d9c36aff2885ed43eb1916a9543f5b9b882eb5e38 | hash | MIT |
| paper-shaders | reference | — | https://github.com/paper-design/shaders | 7002061d8389781a45e479584deeca0cf538474e | n/a | url-only | Apache-2.0 |
| shape-of-ai | reference | — | https://www.shapeof.ai/ | read 2026-08-18 | n/a | url-only | unknown — site, no licence stated |
| npx-skills-installer | installer | — | https://github.com/obra/skills | n/a | n/a | installer | per package |

## What each check method actually proves

| Method | Proves | Does not prove |
|---|---|---|
| `git` | Whether the checkout is clean, and how many commits it is behind and ahead of its tracking branch | Nothing, if no tracking branch is configured — it says so in words rather than printing a blank |
| `hash` | Whether the local files still match the recorded content hash (did *I* edit it), and separately whether the pinned revision still matches upstream's default branch (did *they* move) | Anything about a non-GitHub upstream; those are labelled `documentation-only, unchecked` |
| `installer` | How many packages the installer's lock file claims, and whether the symlink count in `skills/` disagrees with it | Per-skill health — that belongs to the ghost check in `/checkup` Step 5, and two answers to one question is worse than one |
| `url-only` | For a GitHub URL, whether the pinned revision still matches upstream | Anything at all for a non-GitHub URL. Those print `documentation-only, unchecked` and that is the honest answer, not a gap |

## The honesty rules this file exists to enforce

- **Never a blank where a number belongs.** A count that could not be computed prints the
  literal word `unknown` with the reason beside it. The check this replaced printed
  `<sha>  behind` with nothing between them, which reads as zero.
- **Never a silent skip.** A source that cannot be checked prints `CANNOT CHECK — <reason>`.
  Every reason is distinct: no upstream recorded, no tracking branch configured, not a git
  checkout, gh not installed, gh not authenticated, rate limited, repo not found, network
  error. Collapsing them into one message would rebuild the same false-health problem under
  a louder label.
- **Reconciliation runs both ways.** In the manifest but not on disk is `MISSING`. On disk
  under a declared root but not in the manifest is `UNREGISTERED`. The second is the one that
  matters — unwatched borrowed code is exactly what this file prevents.

## The content hash

`shasum` over a `find` listing breaks on filenames with spaces or newlines, so the hash is
computed in Python instead: files sorted by relative path, each contributing its path bytes
and its content bytes, so a rename counts as drift. `.git/` is skipped. `SOURCE.md` is skipped
because it is where the hash gets written and would otherwise change its own answer. Symlinks
hash their target string rather than being followed.

The hash lives **here**, in a tracked file, not only in the vendored directory's own
`SOURCE.md`. Both that directory and its `SOURCE.md` are gitignored, so a baseline stored only
there could be edited alongside the files it describes and leave no trace. `SOURCE.md` mirrors
the value for local provenance; this table is the authority.

## Re-pinning after a deliberate update

There is no command for it, and that is deliberate — pulling borrowed code is always a
decision, never a side effect of a health check. Update the directory by hand, then:

```bash
python3 -c "import sys; sys.path.insert(0,'skills/checkup/scripts'); from borrowed_check import dir_hash; print(dir_hash('<path>'))"
```

and paste the result into the `Content hash` cell above.

## Two special cells, and why they exist

`claude-plugins-official` broke both of the obvious assumptions, and the fixes generalise.

**`Pinned` may name a file instead of holding a revision.** A cell starting with `.` is read as
a path inside the directory — here `.gcs-sha`, which Claude Code writes. Claude Code refreshes
that marketplace on its own schedule, so a revision typed into this table is stale the moment
it updates. Pointing at the file it maintains means the check keeps working without anybody
re-editing the manifest.

**`Content hash` may be the literal `machine-managed`.** Same cause: hashing a directory a tool
rewrites compares a person's baseline against a machine's output, and it was wrong within
minutes of being recorded — observed 2026-08-18, the directory refreshed between two runs of
this check twelve minutes apart. A row that fails forever teaches the reader to ignore it,
which is worse than not checking. So local-edit detection is switched off for that entry and
says so out loud, while the upstream check still means something.

Use `machine-managed` only for a directory something else owns. For a directory a person is
responsible for, an unexplained hash change is the finding.

Its origin URL, incidentally, is not recorded anywhere inside the directory — it was recovered
from `settings.json`'s `extraKnownMarketplaces`, which is where Claude Code records a
marketplace's source. That is the place to look when a borrowed directory has no `.git`.
