---
name: github-readme
description: |
  Write or tidy a GitHub repo the way the user likes: a short README with badges, tables and
  a numbered quick start, everything else folded into collapsible sections, a comment above
  every copy-paste command, nothing personal anywhere, a .gitignore that works, and a clean
  root folder. Use when the user says "make the github docs simpler", "clean up the repo", "write a
  README", "tidy the repo", "get this ready for GitHub", "make it public", or asks for a
  README, docs pass, or repo cleanup on anything that lives in git.
---

# github-readme

Make a repo that a stranger can use in five minutes and that gives away nothing about where it
was built. The model is [proxblox](https://github.com/holland-built/proxblox). Match its shape
before inventing a new one, because the user has already approved that shape and every departure
costs a review round.

Many readers are not programmers. Everyday words, short sentences, one idea each. Say who does
what.

## README shape

The whole page is built so a reader opens only what they need.

- **Title** is the repo name. Right under it, a row of shields.io badges for the main tools,
  the platforms it runs on, and how to run the tests. The user calls this the flair.
- **Two or three plain sentences** next: what it does, how long it takes, what you end up with.
- **Tables** wherever things are compared or listed: commands (Command | What it does), what you
  need (Where | Needs), repo layout (Path | Holds), options (Flag | Meaning | Default),
  troubleshooting (Symptom | Cause | Fix). Three or four columns at most, so it reads on a phone.
- **A numbered quick start** of five steps or fewer. Each step is one action.
- **Everything past the quick start** goes in `<details>` blocks with a bold `<summary>` title:
  `<summary><b>Teardown</b></summary>`. This is what keeps the page short.
- **Warnings stay visible.** Anything about deleting, overwriting or publishing data goes in a
  `> [!WARNING]` block that is never inside a folded section. A reader who never opens the
  details still has to see it.

## Copy-paste commands

Every command a reader might copy gets a comment on its own line directly above it, saying in
plain words what it does. One comment per command, never at the end of the line, because the
reader copies the line and the comment travels with it as a reminder.

```bash
# make your own copy of the settings file, then open it to edit
cp config.env.example config.env && nano config.env
```

Commands, paths, flags and error text are copied exactly. A reader pastes them, so a typo
becomes their bug.

Never tell people to use root or a shared account. Show a personal login with `sudo`, and say
what access it needs (which commands, which folders) rather than locking it down. proxblox has
a worked example under "Proxmox login: use your own user, not root".

After writing, read every code block again and fix any command that has no comment directly
above it. This is the check that most often fails on the first pass.

## Nothing personal, anywhere in the repo

The repo must carry no trace of where or by whom it was built. That means no local folder paths
(`/Users/...`, `/home/...`), usernames, real hostnames, domain names, IP addresses, MAC
addresses, customer or company names, emails, tokens or keys. It applies to the README, docs,
code comments, example output, tests and commit messages, because GitHub shows all of them.

Use obvious placeholders instead:

| Instead of | Write |
|---|---|
| A username or owner | `<you>` or `jsmith` |
| A Proxmox or other host | `pve1` or `<proxmox-host>` |
| An IP address | `10.0.0.x` |
| A MAC address | `aa:bb:cc:dd:ee:ff` |
| A domain | `example.com` |

Before every commit, search the tracked files, the staged diff and the commit message for
these and fix any hit. Show the user the search and its result, so they can see the check ran
rather than take it on trust. A real IP slipped into proxblox's sample output once and needed
its own commit to take out.

```bash
# search every tracked file plus what is staged for anything that identifies a person, host, network or secret
{ git ls-files -z | xargs -0 cat; git diff --cached; } | grep -niE '/Users/|/home/|C:\\Users|<your-username>|<your-surname>|[0-9]{1,3}(\.[0-9]{1,3}){3}|([0-9a-f]{2}:){5}[0-9a-f]{2}|[a-z0-9._-]+@[a-z0-9-]+\.[a-z]{2,}|\.(local|lan|corp|internal)([^a-z]|$)|token|api[_-]?key|secret|password|BEGIN (RSA |OPENSSH )?PRIVATE KEY'
```

Add to the pattern the real names of customers, companies, tenants, hosts and people that
came up in the project, because a generic search cannot know them. Placeholders such as
`10.0.0.x` and the word `token` in prose will match, so read the hits rather than count them.

The search covers what is being committed now. Older commits are not rewritten: if history
already holds something identifying, say so and let the user decide, because rewriting history
changes every clone and a leaked secret needs rotating either way.

## Secrets: run gitleaks as well

The grep above finds the words `token` and `password`, but a real key rarely carries either.
`gitleaks` matches the shapes themselves — `AKIA…`, `ghp_…`, `xoxb-…`, several hundred more —
and it reads every commit, which the grep cannot. The two find different things, so run both.

```bash
# every commit in this repo, not just what is about to be committed
gitleaks git --redact --no-banner .
# and the files on disk, including anything not yet staged
gitleaks dir --redact --no-banner .
```

A hit in the working tree is fixed before the repo goes public. A hit in history is the user's
call: say which commit and which file, and say plainly that the key must be replaced whether or
not the history is rewritten, because a published key is already gone.

If `gitleaks` is not installed, say so in one line and carry on with the grep. A scan that did
not run is "couldn't tell", never a clean result. It is `brew install gitleaks`.

This does not replace the identity search above: gitleaks looks for keys and knows nothing
about the user's name, home path, customers or hosts.

## .gitignore

Every repo has one. It covers real config files (a `.example` copy is committed instead),
secrets and tokens, local state, logs, OS junk such as `.DS_Store`, editor and agent folders
(`.claude/settings.local.json`, `.orca/`), and build or cache output.

Check with `git status --ignored` that the real config and secrets are ignored, and that nothing
of that kind is already tracked. If something like that is tracked, tell the user before removing
it, because removing it now does not take it out of git history and they may want to rewrite or
rotate it.

## Clean root folder

The root holds only the README, the main entry command, a config example, LICENSE if there is
one, and dotfiles, so the first thing a visitor sees on GitHub is the command to run. Everything else goes in a folder: `scripts/` for scripts, `docs/` for notes,
`tests/` for tests, and a folder per tool such as `terraform/`.

When files move, update every path that points at them: scripts, tests, other READMEs, CI
files. Then run the test suite and show it passing. Stage every related change together, so git
never holds half a refactor.

## Naming

Do not name a repo after someone else's product. If a rename is needed, offer about ten options
in a table with the idea behind each, recommend one, and let the user choose. The name is theirs to make,
and hard to change once it is public.

## Before finishing

Run `/humanizer` on all the prose, because a README that reads like a chatbot loses the
non-programmer reader in the first paragraph. Em dashes are the tell the user notices first, so
none survive.

Ask Codex to review the README and the diff before the final push, using the command in
`~/.claude/CLAUDE.md`. A model is a poor judge of its own work, and a public repo is expensive
to fix after the fact. If `codex` is not installed, skip it and say so once.

GitHub shows only what is pushed. When the user is reviewing on GitHub, or asked for the repo to
be published, commit, push, and give them the link to the repo or the README. Otherwise leave
the commit local and say so.

## Done

- The README has badges, two or three sentences, tables, a quick start of five steps or fewer,
  and everything after the quick start folded into `<details>` blocks, with warnings left
  visible.
- Every copy-paste command has a plain-words comment on the line above it.
- The identifying-detail search over tracked files, staged diff and commit message was shown
  to the user and returns nothing real.
- `git status --ignored` shows real config and secrets ignored and none of them tracked.
- `gitleaks` ran over both the history and the working tree, its output was shown, and any hit
  in history was named to the user with the advice to replace the key.
- The root folder holds only README, entry command, config example, LICENSE and dotfiles, and
  the tests pass after any move.
- The prose has been through `/humanizer` and has no em dashes.
- Codex reviewed the README and diff, or the skip was stated once.
- If the user is reviewing on GitHub, the work is pushed and they have the link.
