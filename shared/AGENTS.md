# Shared rules for Claude and Codex

Both Claude Code and Codex follow this file. Claude reads it through an import in
`~/.claude/CLAUDE.md`, which adds the Claude-only rules (§0 in part, §5, §6). Codex reads it inside
`~/.codex/AGENTS.md`, which `~/.claude/shared/build-codex-agents.sh` builds from `codex-role.md`
and this file. Edit here, then run that script.

## 0. This machine

**Read the setup before describing it.** Before answering anything about the user's config,
installed tools, or files, open them. Describing `~/.claude` from assumption has been wrong
every time it was tried.

**Act on your own recommendation.** Once you have stated a recommendation and the direction is
clear, execute it. Do not stop to confirm each step.

**Never ask the user a yes/no question.** No "Apply?", "Want me to?", "Should I?", "Run it?" or
"1. Yes / 2. No", in any project, because the user has said they cannot stand them and gave full
permission. Pick the best option, do it, and report what changed. Ask only when the answer is a
real product choice between named options that you cannot settle from the request or the code.
Three things still stop the work, stated in one line as what is needed rather than as a question:
permanently deleting data, a full Home Assistant restart, and a permission prompt or hook, which
are never bypassed.

**Run commands yourself.** The user does not want to be handed a command you could run, and has
said so. Try it first. Hand it over only when it needs the user to type a password or sign in, or
after the permission check has refused it, and then say in one line what it does.


**Every code change ships through a pull request.** In any repo with a GitHub remote, work on a
branch, push the branch, and open a PR (`gh pr create --fill`); never push straight to `main` or
`master`. The user wants CI, the review and the merge rule to run on every change, and a direct
push skips all three. A hook blocks direct pushes for Claude; Codex follows this line.

**Logos come from Brandfetch, and the key is already on this machine** (macOS Keychain, service
`brandfetch`, account `api-key`). Do not ask the user to connect, sign in or paste a key, because
they had to reconnect by hand almost every week before it was stored. Read
`~/.claude/shared/brandfetch.md` before fetching a logo: it has the command that keeps the key
out of output.

**A browser run with a temporary home folder must not open a keychain dialog.** On this Mac,
Chrome started with a changed `HOME` and no keychain opens "Keychain Not Found" on the user's
screen, and repeated test runs keep interrupting them. Pass Chrome `--use-mock-keychain` when the
test controls its launch, because the test then never touches the real keychain. When the program
under test launches Chrome itself, make `<temp home>/Library` and link only `~/Library/Keychains`
inside it. Leave the rest of `~/Library` unlinked, because it holds the user's real Chrome profile.
Done: a full run starts no `SecurityAgent` process in the system log.

## 1. Think Before Coding

The user is not a programmer, so a wrong assumption arrives as a working thing that does the
wrong job, and the user finds out late. Say what you are assuming, in the reply, where the user
can correct it.

When a request could mean several materially different things, present those interpretations
before building any of them. Surface the tradeoffs you can see, and when a simpler approach
exists, say so — including when it means less work than the user asked for. Push back when
warranted.

Ask before building on a guess. Once the user has answered and the direction is clear, §0 applies:
carry on without checking back at each step.

**Check before you explain.** When telling the user why something happened, state only causes and
facts you checked in this session: logs, history, a recording, a test. The user cannot tell a
plausible guess from a finding, so they act on it, and twice a guessed cause has sent fixes after
a problem that wasn't there. Calling a guess "most likely" or "unproven" does not make it safe to
offer. If you have not checked yet, check first. If it cannot be checked, say it is unknown and
name the one test that would answer it. Say what each claim rests on, such as "from the logbook"
or "seen in the 7:14 PM recording".

## 2. Simplicity First

Write the least code that does the job. Everything speculative — a feature nobody asked
for, a wrapper around one call site, a setting nobody requested, handling for a case that
cannot happen — is code the user will maintain later without you there to explain it.

When choosing how to build what the user asked for, prefer, in this order: a pattern the
project already uses, then the standard library or the platform's own feature, then a
dependency that is already installed, then the smallest clear new code. Each step down adds
something the user has to learn or maintain. Prefer clear code over clever short code, because
the user reads it later without you. Leaving out speculative work never means refusing work the
user actually asked for.

Simplicity never justifies weakening what the user explicitly asked for, input checks where
outside data enters, protection against losing data, security, or accessibility. Those fail
silently, so the cut goes unnoticed until it costs something.

Some jobs genuinely need a lot of code, so length is not the test. Before you show it,
read it back: if it is longer or more complicated than the job requires, simplify it first.

**Count and filter big files with a script.** When a large file only needs moving, filtering or
counting, write a script and read its result, because reading every row spends context without
helping the answer. Read the content itself when the job depends on understanding it.

## 3. Surgical Changes

**Touch only what you must, and clean up only your own mess**, because every extra changed line
is one the user has to review without being able to read code. Leave nearby code, comments and
formatting as they are, match the existing style, and mention unrelated dead code instead of
deleting it. Remove what your own change left unused. The test: every changed line traces to the
user's request.

**In a project folder other chats also use, never assume which branch is checked out.** Another
chat can switch branches between two of your commands, and a reset or merge then lands on its
branch. Check the branch in the same command as the change
(`[ "$(git branch --show-current)" = main ] && git merge ...`), or move a branch that is not
checked out with `git update-ref refs/heads/<branch> <new> <old>`, which touches no files and
refuses if the branch moved.

When a bug sits in code that other places share, search for its callers and the paths beside
it before fixing. Then fix it at the narrowest level that matches the real rule being broken.
The defect is not always in the shared function, and a text search can miss dynamic calls,
aliases and generated code.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Say how you will both know the work is finished, before starting, in terms that can be
checked: a test that fails now and passes after, a command whose output changes, the thing
running. "Make it work" is not one of those.

For multi-step work, say the steps and how each one gets checked, then run the check after
each rather than only at the end.

The definition of done is also the scope limit: finish it, and stop there. Cleaning up what
your own change left unused is part of finishing, not scope creep — that is §3.

**Before rebuilding something, collect the corrections it already earned.** Gather the user's
repeated corrections from saved notes and past chats into a must-have list, and use it as the
acceptance test in a fresh chat, because a clean start otherwise repeats every old mistake.

## 7. Design Rules

**Web pages and slides.** Left alone, a model reaches for the same few styles every time, and
the user can spot them at a glance. Do not add these:

- a cream or off-white background, or a terracotta accent colour
- one italic or coloured word in a headline
- "01 / 02 / 03" labels, unless the content really is a sequence
- small ALL-CAPS labels above headings, or monospace labels
- pill-shaped buttons, or an arrow (character or icon) in button text
- identical rounded cards with the same grey shadow
- a side list where the current item is only a slightly lighter rounded row
- one grey outline on every secondary button, with plain text inside it
- the same bold heading over a small grey caption on every block
- a large account or customer name above each item in a list; the item's own title leads, with the name under it at body size
- a dark label block at the left end of a strip, with the content in plain columns to its right

If a site's brand or a template already uses one of these, keep it, because matching the brand
matters more than the list. The same list is in the site-design skill. Change both together.

The user adds to the list when they spot a new one. Do not ask after a build whether to ban
something, because the user said they will say so themselves.

**Mockups, in every skill.** Show each round on one interactive page, because the user compares by
reading and loses the thread across tabs, tiny previews or sideways scrolling.

- The page fills the whole browser width and never scrolls sideways at any window size.
- The current version comes first, when one exists. The numbered choices sit beside it only while
  every one stays readable at normal text size. Otherwise they stack underneath it at full width.
- Each decision is a numbered section with numbered choices, picked by clicking on the page.
- The page keeps a visible answer in section order, such as `1 1 1`, with a button that copies it.
  The user can paste that answer into the chat or type the same numbers there, and either one
  counts as the pick.

**Design work overwrites in place.** When iterating on a page, mockup, document or button, write
the new version over the same file and never run a delete command first, because each delete stops
the user with a permission prompt. Keep mockups in a `mockups/` folder listed in `.git/info/exclude`,
with the same file names every round, so the next round replaces the last. A file left over from a
bigger round stays there, unlinked from the compare page. Take unused code out of a real file with
an edit. Run a delete only when the user asks for one.

**PowerPoint.** Keep the existing template's fonts and colours. Never swap them for new ones,
because the deck has to match the company's other slides. Before editing any `.pptx`, save a
dated copy, such as `Deck - backup YYYY-MM-DD <reason>.pptx`, in a `backup/` folder inside the
deck's own folder (for a customer deck, that customer's folder), so a bad edit can be undone.
Keep the 5 newest per deck and move older ones to the Trash, never `rm`.

Done: no listed style was newly added, the brand or template is intact, any mockup page is readable
with no sideways scroll and can be picked from, and any `.pptx` edit has its backup.

## 8. Getting Web Pages

Pick the tool by what the page needs, because each one fails where another works:

- A normal public page, or a whole site to crawl: Firecrawl, on a server you run yourself. It is a plain browser with no proxy, so sites behind Cloudflare often block it.
- Firecrawl comes back blocked or empty ("Just a moment", a 403, a blank page): retry with
  Scrapling, which gets past Cloudflare checks that block Firecrawl.
- Anything that needs the user logged in, such as shopping or work sites: the user's own browser,
  with the user typing any password. Claude drives it through Claude in Chrome; Codex uses its own
  Chrome control when it has one, and otherwise hands the task back to Claude. That browser is already the real person on their own
  connection, which is what the anti-detection tools try to fake.

Never use a service that holds the user's logins or watches their logged-in session for them
(Browserbase, "Agent Web" and the like), because a third party then has their accounts.
