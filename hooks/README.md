# hooks

## pre-commit: block a commit that contains a secret

Runs [gitleaks](https://github.com/gitleaks/gitleaks) over what is staged. A hit
refuses the commit, so the secret never enters history. Without gitleaks the
hook cannot scan, so it prints a warning on every commit and lets the commit through.

`./install.sh` installs gitleaks and points git at this folder for every repo on
the machine. If git already has a hooks folder, the installer leaves it alone and
tells you the guard is off.

Check it works: stage a file holding a fake key such as `AKIA` followed by 16
capitals, and the commit is refused. Real emergencies skip it with
`git commit --no-verify`.

Note that gitleaks ignores documentation samples on purpose, so the published
`AKIAIOSFODNN7EXAMPLE` key will not trigger it.

## Claude Code hooks

| File | What it does |
|---|---|
| `require-pr.py` | Blocks a push straight to `main` or `master`, and blocks a PR on risky code until it is reviewed |
| `ssh-delete-guard.py` | Asks first when an ssh command could delete or wipe something |
| `orca-waiting.py` | Marks a chat in Orca's sidebar while it needs you. Does nothing outside Orca |

To add your own risky paths, create `~/.claude/risky-extra.txt`:

```text
# a path that needs review
risky: billing
# a path that never needs review
skip: generated/
# a machine-built path the review tool should ignore
built: vendor/**
```
