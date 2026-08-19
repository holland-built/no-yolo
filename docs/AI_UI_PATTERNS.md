# AI interface patterns: the names for things you already recognise

A naming vocabulary for AI product interfaces. Nothing here is a rule; it is words. The value
is that "we should show what it's about to do before it does it" has a name, **Action plan**,
and once it does, you can ask whether the product has one, compare yours to five others, and
say what is missing in two words instead of a paragraph.

**Source:** [The Shape of AI](https://www.shapeof.ai/), read 2026-08-18. Registered in
`docs/BORROWED.md`.

**An honest count.** 57 named patterns were extracted. The site's own section headers sum to
60, so three names were not captured, probably in Wayfinders, Tuners and Trust builders, where
the header count exceeds the rows below by one each. Treat this as most of the vocabulary, not
all of it, and go to the source when a pattern you need is not here.

## When to reach for this file

Designing, reviewing, or naming any surface where a model does the work: a chat, an assistant
panel, a generate button, an agent that acts on its own. Use it to name what you are building
before you build it, and to find the gap. The categories below are a checklist of the things
AI products usually forget.

---

## Wayfinders: getting someone past the empty box

The blank input is the hardest screen in AI. These are the ways out of it.

| Pattern | What it is |
|---|---|
| **Initial CTA** | The large open-ended input inviting a first interaction |
| **Suggestions** | Clues for how to prompt, the standard answer to the blank canvas |
| **Templates** | Structured forms the user fills or the AI pre-fills |
| **Gallery** | Sample generations shown with their prompts and parameters, to teach by example |
| **Nudges** | Pointing out an AI action the user could take, especially early on |
| **Randomize** | A low-effort fun result to break the ice |
| **Follow up** | Asking for more when the first prompt was not clear enough |
| **Prompt details** | Showing what is actually happening behind the scenes |

## Prompt actions: what the user can ask for

The verbs. Most AI features are one of these wearing a product name.

| Pattern | What it is |
|---|---|
| **Open input** | Free-text prompting, the default |
| **Inline action** | Asking the AI about something already on the page, in place |
| **Auto-fill** | One prompt extending across several fields at once |
| **Expand** | Lengthen or add depth to existing content |
| **Summary** | Distil a topic or resource to its essence |
| **Synthesis** | Reorganise complicated information into simple structure |
| **Transform** | Change the modality: text to image, doc to slides |
| **Restructure** | Use existing content as the starting point for the prompt |
| **Restyle** | Change style while keeping the underlying structure |
| **Inpainting** | Regenerate one targeted region of a result |
| **Regenerate** | Same prompt, new answer, no extra input |
| **Describe** | Break a result back down into the tokens and prompt that would make it |
| **Madlibs** | Repeat a generative task without losing format or accuracy |
| **Chained action** | One action feeding the next |

## Tuners: narrowing what the model does

| Pattern | What it is |
|---|---|
| **Parameters** | Constraints supplied alongside the prompt |
| **Filters** | Constrain inputs or outputs by source, type, modality |
| **Modes** | Swap the training, constraints and persona for a context |
| **Model management** | Let the user choose the model |
| **Attachments** | A specific reference to anchor the response |
| **Connectors** | Let the AI reach external data and context |
| **Preset styles** | Ready-made options for texture, aesthetic or tone |
| **Saved styles** | User-defined presets, reusable |
| **Voice and tone** | Keep output consistent with a defined voice |
| **Prompt enhancer** | Improve the prompt before it runs |

## Governors: oversight, and the brakes

The category most often missing, and the one that decides whether people trust an agent that
acts on its own.

| Pattern | What it is |
|---|---|
| **Action plan** | Show the steps before executing them |
| **Verification** | Confirm a decision or action before proceeding |
| **Sample response** | Confirm intent on a complicated prompt before doing the work |
| **Stream of thought** | Reveal reasoning, tool use and decisions, for oversight |
| **Controls** | Pause or steer a request mid-stream |
| **Citations** | Inline annotations giving sources |
| **References** | See and manage what extra sources were used |
| **Variations** | Several results to choose between |
| **Branches** | Iterate while keeping the path back to the original |
| **Draft mode** | Explore cheaply before committing to a final form |
| **Cost estimates** | Make compute cost visible before it is spent |
| **Memory** | Control what the AI knows about you |
| **Shared vision** | Live visibility into the AI's work in a shared space |

## Trust builders: being straight with people

| Pattern | What it is |
|---|---|
| **Disclosure** | Mark clearly what was AI-guided or AI-delivered |
| **Caveat** | State the model's shortcomings and risks |
| **Footprints** | Let a user trace prompt to result |
| **Consent** | Capture data about others only with their knowledge |
| **Data ownership** | Control how the model remembers and uses your data |
| **Incognito mode** | Interact outside the AI's memory |
| **Watermark** | Machine-readable identifiers on generated content |

## Identifiers: how the AI shows up

| Pattern | What it is |
|---|---|
| **Name** | What the AI is called across the product |
| **Avatar** | Its visual identifier |
| **Iconography** | Images marking AI-powered actions |
| **Color** | Visual cues distinguishing AI features or content |
| **Personality** | The characteristics that give it a vibe |

---

## How to actually use it

Name first, then judge. "The generate button needs better feedback" is a sentence nobody can
act on. "There is no **Action plan** and no **Draft mode**, so the first thing a user sees is
an irreversible result that cost them money" names two missing patterns and implies both fixes.

Two failure modes worth knowing:

- **Reaching for every pattern.** This is a vocabulary, not a checklist to complete. A product
  with all 57 would be unusable. The categories are for finding the one gap that matters.
- **Naming without building.** A **Caveat** that nobody reads, or a **Stream of thought** that
  shows fake reasoning, is worse than neither: it buys trust the product has not earned.

For visual craft on these surfaces, the rules live elsewhere: `docs/GUI_SLOP.md` for what not
to ship, and `/design` for building it.

---

## Does it actually change anything? Measured, 2026-08-18

The plan that commissioned this file required one representative task where the vocabulary
changes the output. Run as an A/B on a second model so the answer was not marked by its own
author. Identical spec both times: *"A Summarise button on each document in a notes app. User
clicks it, an AI summary replaces the document body in place. There is a spinner while it
runs."* Same reviewer, same limit of six bullets; the only difference was reading this file
first.

| Without this file | With it |
|---|---|
| Undo/restore original and confirm before overwrite | **Verification**: confirm before replacing the body |
| Save behaviour: automatic vs explicit; version history | **Draft mode**: preview before committing |
| Error, timeout, retry, cancellation, offline states | **Branches**: preserve and restore the original |
| Summary controls: length, format, language, regeneration | **Controls**: cancel while summarising |
| Eligibility: empty, short, large, read-only documents | **Disclosure**: mark the replacement as AI-generated |
| Privacy, data handling, permissions, rate limits, cost | **Footprints**: retain the prompt-to-result history |

Both are competent. The difference that matters is not the naming. It is that **Disclosure**
and **Footprints** have no counterpart on the left at all. The unaided review reached "privacy
and data handling" as a category and stopped; it never arrived at *mark the output as
AI-generated* or *let the user trace how this was produced*. Two real findings surfaced,
not six relabelled ones.

The honest limit: one task, one model, one run. It is enough to show the vocabulary adds rather
than renames, and not enough to claim a size for the effect.
