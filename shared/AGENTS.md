# Shared rules for Claude and Codex

Both Claude Code and Codex follow this file. Claude reads it through an import in
`~/.claude/CLAUDE.md`, which adds the Claude-only rules (§0 in part, §5, §6). Codex reads it inside
`~/.codex/AGENTS.md`, which `~/.claude/shared/build-codex-agents.sh` builds from `codex-role.md`
and this file. Edit here, then run that script.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.


## 0. This machine

**Read the setup before describing it.** Before answering anything about the user's config,
installed tools, or files, open them. Describing `~/.claude` from assumption has been wrong
every time it was tried.

**Act on your own recommendation.** Once you have stated a recommendation and the direction is
clear, execute it. Do not stop to confirm each step. Reserve a blocking question for a choice
that is irreversible, or where being wrong would waste real work.


**Logos come from Brandfetch, and the key is already on this machine.** The Brandfetch API key
is in the macOS Keychain (service `brandfetch`, account `api-key`), so it is there in every
session and every folder. The user stored it after reconnecting Brandfetch by hand almost every
week, so do not ask them to connect, sign in or paste a key again. Read the key into a shell
variable and use it in the same command, so it never shows in output, a file, a commit or a
memory note:

```bash
K=$(security find-generic-password -s brandfetch -a api-key -w)
curl -s -H "Authorization: Bearer $K" "https://api.brandfetch.io/v2/brands/<domain>"
```

The reply lists each logo with its type, theme and download links. Download the one that suits
the background and look at the file before using it. If the key reads back empty or the API
answers 401, say so in one line and ask the user to store it again from the Terminal app with
`security add-generic-password -U -s brandfetch -a api-key -w`; the `!` prefix cannot take typed
input and stores an empty value. Done is a logo that came from Brandfetch and a key that was
never shown.

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

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When a bug sits in code that other places share, search for its callers and the paths beside
it before fixing. Then fix it at the narrowest level that matches the real rule being broken.
The defect is not always in the shared function, and a text search can miss dynamic calls,
aliases and generated code.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Say how you will both know the work is finished, before starting, in terms that can be
checked: a test that fails now and passes after, a command whose output changes, the thing
running. "Make it work" is not one of those.

For multi-step work, say the steps and how each one gets checked, then run the check after
each rather than only at the end.

The definition of done is also the scope limit: finish it, and stop there. Cleaning up what
your own change left unused is part of finishing, not scope creep — that is §3.

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

The list grows. After each build, name the style you used in place of these, and ask whether to
ban that one too.

**PowerPoint.** Keep the existing template's fonts and colours. Never swap them for new ones,
because the deck has to match the company's other slides. Before editing any `.pptx`, save a
dated copy, such as `Deck - backup YYYY-MM-DD <reason>.pptx`, in a `backup/` folder inside the
deck's own folder (for a customer deck, that customer's folder), so a bad edit can be undone.
Keep the 5 newest per deck and move older ones to the Trash, never `rm`.

Done: no listed style was newly added, the brand or template is intact, any `.pptx` edit has
its backup, and the user has been asked about the style used instead.

## 8. Getting Web Pages

Pick the tool by what the page needs, because each one fails where another works:

- A normal public page, or a whole site to crawl: Firecrawl, the self-hosted server on the home
  network. It is a plain browser with no proxy, so sites behind Cloudflare often block it.
- Firecrawl comes back blocked or empty ("Just a moment", a 403, a blank page): retry with
  Scrapling. On 2026-10-18 Scrapling got through 4 of 4 Cloudflare test pages where Firecrawl got
  through 1.
- Anything that needs the user logged in, such as shopping or work sites: the user's own browser,
  with the user typing any password. Claude drives it through Claude in Chrome; Codex uses its own
  Chrome control when it has one, and otherwise hands the task back to Claude. That browser is already the real person on the home
  connection, which is what the anti-detection tools try to fake.

Never use a service that holds the user's logins or watches their logged-in session for them
(Browserbase, "Agent Web" and the like), because a third party then has their accounts.
