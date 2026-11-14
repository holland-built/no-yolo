---
name: write-doc
description: Write a document a person will read - a how-to guide, quick start, report, status update, email, intranet or SharePoint post, leadership summary, customer one-pager, a README turned into a PDF for readers outside GitHub, or handoff notes for whoever maintains a tool next. Use when the user says write a guide, draft an email, one-pager, report, send to leadership, post for the hub, make this doc shorter, or hands over notes to turn into a doc, including a guide about an app or project in this folder; load it before reading the project, because the document type decides what to look for. Not for GitHub READMEs (github-readme), interface copy (better-writing), files an AI reads (writing), or picking up an unfinished session (handoff).
---

# write-doc

If `private.md` sits beside this file, read it first. It holds this machine's house examples,
brand colours and extra keep-out rules, and wins over the general defaults below.

## Who reads it

The readers are colleagues, leadership, customers, and whoever maintains a tool next. They open
the document once, in a hurry, often on a phone or printed, and decide from the first screen
whether it is worth their time. Everything below follows from that reader.

## The first three lines

The title says what the thing is and who it is for ("Pipeline agent: quick start"). The next
line says what it does, links to it, and says how long it takes ("Setup takes about 2 minutes.
There is nothing to install."). A report or update opens with its conclusion instead ("Keep
Thinking and cut the slow writing steps."). A reader who stops after three lines should still
know what to do or what was found.

## Shape by type

Each type has its own shape, so pick the type first. A guide's numbered steps in an email, or a
report's caveats in a post summary, make the document harder to use.

| Type | Opens with | Body | Length | Ends with |
|---|---|---|---|---|
| Guide or quick start | What + who, link, time | "Set up once (5 minutes)", then everyday steps, then a picture section | About one printed page plus pictures | "Stuck?" and who to ask |
| Report or update | The conclusion | What was found; a table of what was tested and numbered suggestions when the source has them | 300 to 600 words | Any estimate, with its caveat |
| Email | Subject line that names the ask | Two short paragraphs of context, then numbered questions or asks | As short as it can be | Any reference ID, then "Thanks" |
| Intranet post | One-line lead | Three facts (what it shows, who it is for, how long), then Details | Short | Attachments table |
| Intranet list item | One-sentence summary | An access note when the link is private | One sentence each | n/a |
| Leadership doc | The recommendation in one line | Evidence, Barriers, Recommendation as bullets | One page | The ask |
| Customer one-pager | "Prepared for [customer]" | Formal, branded, the customer's situation and the proposal | One page | Next step and contact |
| Maintainer handoff | What it is and where it lives | Short bullets, column tables, how to run and change it | As needed | Known limitations |

## Keep it short enough to use

Published documents (posts, guides, a README turned into a PDF) follow the same style as a good
GitHub README (see the `github-readme` skill), because the readers are the same hurried people.

- **A table wherever things are compared or listed**: commands (Command | What it does), keys or
  files (Key | Saved in | Used for), choices (Status | Means | Do this), troubleshooting
  (Symptom | Cause | Fix). Three or four columns at most, so it reads on a phone and in print.
  Prose comparisons hide the one row the reader came for.
- **A numbered quick start of five steps or fewer**, such as "Set up once (5 minutes)". Longer
  than five means some steps are reference material or belong to a later section.
- **Reference material folded or moved out of the way**: every setting, what each count means,
  notes for whoever changes the scripts. Fold it into a collapsible section where the format has
  one (a README, an HTML page); in a post or PDF, move it to an appendix at the end or into an
  attached file. The first screen stays for the reader doing the job today.
- **Warnings stay visible at the step they apply to**, never inside a folded section or appendix.
  A reader who never opens the reference still has to see them.
- **Each fact said once.** A command list, a key location or an explanation lives in one place,
  and anything else that needs it points there. The typical cut: separate "Before you start" and
  "Run it" sections, plus steps repeated further down, become one "Set up once" list and a short
  command table.

## Before editing an existing document, measure it

Show the user a table before changing anything, then wait for a go:

| Section | Lines now | Lines after | What gets cut or moved |
|---|---|---|---|

Include a total row. A cut to a published page is easier to judge as a plan than as a finished
diff, and the user may want to keep a section the numbers say to drop. Count lines in the source
the user edits (the HTML or markdown); for a page with no local source, count paragraphs and say
so.

## Steps, tables and pictures

A step is one action, with the button or menu name in bold and the click path written out
("click your name at the bottom left, then **Settings**"). Each step says what the reader should
see after it ("Every line should say **working**"), because a reader who cannot check a step
does not know whether to keep going. A command sits in its own copy block with a one-line
comment above it saying what it does, because the reader copies the line and the comment
travels with it.

A warning is one sentence with its reason ("Attach only the .json file, never the report's
.html: the report holds passwords."). A warning at the top gets skimmed past before the reader
reaches the risky step.

Pictures go in their own section, cropped, with alt text that says what is on screen, and every
name in them is invented ("Example Account Inc"). Label invented examples as examples, and never
invent a finding, number or quote: a made-up result in a report is a false statement with the
user's name on it.

## Look

Internal documents use one plain sans-serif font, one dark accent colour for headings and a
white background. Customer-facing documents use the company's brand. A company template's own
fonts and colours win over both.

The banned styles in `~/.claude/shared/AGENTS.md` §7 apply to every document, because they are
what make generated pages look generated. "01 / 02 / 03" section labels are allowed only when a
company template already uses them.

## Keep out

- Customer names, domains, deal sizes and call details in examples, samples or anything shared
  beyond that customer, because a document travels further than its first reader.
- Secrets, keys, passwords and anything a security report says about a customer's credentials.
- Talk about how the document or tool was made with AI, sales language, filler intros, emoji and
  exclamation marks, because the reader came for the facts.
- A customer one-pager names its own customer and nobody else's.

## Hand-offs

Run `humanizer` over the prose last, if it is installed. The `docx` and `pptx` skills produce
Word and PowerPoint files, and `github-readme` owns READMEs that live in a repo. A deck keeps its
company template, and gets a dated backup before any edit (see `~/.claude/shared/AGENTS.md` §7).

## Done

- The title names what it is and who it is for, and the first three lines work on their own.
- The shape and length match the type in the table.
- Lists and comparisons are tables, the quick start has five steps or fewer, reference material
  is folded or in an appendix, warnings sit visible at their step, and no fact appears twice.
- For an existing document, the user saw the section-by-section lines table and said go before
  any edit.
- Every step has one action and says what the reader should see.
- Pictures are in their own section with invented names, and no finding or number is invented.
- Nothing from the keep-out list (or `private.md`'s) is present.
- The look matches internal, customer-facing or the company template, with no banned style.
- `humanizer` ran on the prose, and the user has seen the draft before it is sent or published.
