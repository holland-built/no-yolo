# Which skills fit which ask

A starting point for /better's first check, not the final word: always pick from the skill list
the session shows, because skills get added, parked and renamed. Pick every row that fits, and
leave out a skill that would not change the work.

| The user says something like | Skills to name | What each does there |
|---|---|---|
| build me X, add a toggle, write a script | `build` | settles what it does, builds it, shows it working |
| it's broken, this error, it crashed, it's slow | `fix` | reproduces, finds the cause, fixes, proves it |
| make this page better, it looks off, polish it | `improve`, `impeccable` | `improve` tests and fixes; `impeccable polish` is the final design pass |
| redesign, rewrite the interface, new look, what should it look like | `site-design`, `impeccable`, `better-interface` | `site-design` makes numbered mockups; `impeccable` sets the direction and critiques the pick; `better-interface` reviews the built screens |
| review the whole app, what's wrong with it | `better-interface`, `impeccable` | one ranked list of problems; `impeccable audit` for design quality |
| it looks generic, like every AI site | `frontend-design`, `impeccable` | a distinctive direction, then a critique |
| dashboard, KPI page, NOC screen | `dashboard-design` | data-heavy screens in the owner's chosen style |
| colours, fonts, spacing, animation, icons | `better-colors`, `better-typography`, `better-layout`, `better-motion`, `better-ui` | exact values for that one area |
| accessibility, keyboard, screen reader | `better-accessibility` | checks against WCAG |
| interface wording, error messages, labels | `better-writing` | copy that tells people what to do next |
| diagram, flowchart, architecture, chart for a slide | `diagram-design` | branded static diagrams |
| deck, slides, customer meeting | `slide-builder` | customer decks from the master decks |
| guide, report, email, summary for people | `write-doc`, `humanizer` | writes it, then strips AI tells |
| README, get the repo ready for GitHub | `github-readme` | short README and a clean repo |
| a YouTube link | `claude-video` | watches and summarises it |
| put this on the hub | `hub-add` | adds it to the Cloud Team Hub |
| think this through, grill me | `grill-lite` | rounds of questions, then a decision note |
| what's on my list | `tasks` | the saved task list |
| the chat is long, pick this up later | `handoff` | writes the session down for a fresh chat |
| work across several helpers or copies | `orchestration` | Orca helpers that build in parallel |
| instructions, a skill, CLAUDE.md, a memory note | `writing` | instruction files that work |
| research what people say about X lately | `last30days` | recent posts and discussion |
| install a new skill from outside | `find-skills` | finds and installs it |

Parked skills are not in the skill list. List `~/.claude/skills-parked` when it exists, and when one
there fits the ask, read its `SKILL.md`, follow it, and name it in the rewrite like any other skill.

Typed-only commands never appear in the skill list, so /better cannot pick them: `/retro`, `/ship`,
`/steward`. Mention one only when the user would type it themselves.
