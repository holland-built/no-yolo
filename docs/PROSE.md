# Prose a person will read

Read before writing a README, a pitch, release notes, a commit body, or any passage meant to
read as writing rather than as output.

The list below is the standing bar and stands on its own.

For a deeper pass over a finished draft, the `avoid-ai-writing` skill carries 49 pattern
families and rewrites rather than flags. It is one of the optional installs in `INSTALL.md`;
when it is absent, this file is the whole standard.

## Punctuation

Sentences end with a full stop, a comma, a colon, parentheses, or a rewrite. Ranges use a
plain hyphen: `2018-2026`, `40-80k`.

A `—` inside backticks or a code block is a specimen, quoting the character so a rule can
name it. Those stay. This paragraph is the only place the character appears as itself.

## Say the fact, not the adjective

| Instead of | Write |
|---|---|
| "blazingly fast", "powerful", "best-in-class" | What it does, how fast, compared to what |
| "~40% faster" | The measurement and the command that produced it |
| "should work now" | The command you ran and what it returned |
| "production-ready" | Which checks pass, and which have not been run |

## Sentence shapes that carry weight

- **Open with the answer.** The first sentence of a reply is the finding, not praise for the
  question and not a restatement of it.
- **Make a contrast only when the reader proposed the first half.** "It's not X, it's Y"
  earns its place when someone actually said X.
- **Give three examples when the third is genuinely different.** Two is a complete list.
- **Raise a caveat you intend to act on**, and act on it in the same passage.
- **Close on the next action**, named and specific, or close on nothing.
- **Reverse a position when new evidence arrives**, and name the evidence. Hold the position
  when only the tone changed.

## Vocabulary that reads as machine-written

Treated as density, not as a ban: one is nothing, three on a page is the signal. *elevate,
seamless, unleash, tapestry, testament, holistic, meticulous, nuanced, myriad, embark,
unlock, underscore, showcasing.*

These are ordinary engineering words and stay: *implement, robust, leverage, delve, utilize.*

## Shape

- **Prose documents carry their argument in sentences.** Bullets suit a genuine list of
  peers. A chain of reasoning, where each step depends on the one before, belongs in
  paragraphs.
- **A glossary is allowed to look like a glossary.** A few `- **Term** — explanation` rows are
  a reference block. A whole answer in that shape weights everything equally and argues
  nothing.
- **Chat replies, status output, and checklists follow the always-loaded output rule
  instead.** The bullet guidance above does not reach them.

## Code comments

A comment says why the line exists. The line itself already says what it does. A docstring
earns its place by carrying what the signature cannot: the constraint, the unit, the caller
it assumes.

Write the parameter, flag, or abstraction the current requirement asks for. The next
requirement gets the next one.

## Where the reasoning goes

The root cause, the option you rejected, and the before-and-after numbers go in the commit
message, attached to the diff where `git blame` finds them.
