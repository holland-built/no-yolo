# Caveman prompt / caveman mode output style for LLMs
Window: 2026-08-05 → 2026-09-04

| Signal | Takeaway | Source |
|--------|----------|--------|
| 102,800+ stars, up from ~54K | The biggest Claude Code skill there is, and still climbing | [JuliusBrussee/caveman ↗](https://github.com/juliusbrussee/caveman) |
| v2.5.0 shipped 2 Sep 2026 | Weekly releases, plus a real CLI on npm — it is maintained, not a gag | [Releases ↗](https://github.com/JuliusBrussee/caveman/releases) |
| Claimed 65%, measured 8.5% | JetBrains ran it on real agent tasks and the headline number collapsed | [JetBrains test ↗](https://blog.jetbrains.com/ai/2026/07/speak-to-ai-agents-like-cavemen-tosave-tokens/) |
| 89 points on Hacker News | "Be brief" matched the whole skill in a head-to-head benchmark | [Benchmarked against two words ↗](https://www.maxtaylor.me/articles/i-benchmarked-caveman-against-two-words) |
| 14–21% real saving | Counting input tokens too, the saving is a fifth of what is claimed | [Six-line version beat it ↗](https://medium.com/@KubaGuzik/i-benchmarked-the-viral-caveman-prompt-to-save-llm-tokens-then-my-6-line-version-beat-it-d8e565f95e15) |
| +26 points accuracy | Two papers found forced brevity made big models more accurate, not just cheaper | [Caveman review ↗](https://andrew.ooo/posts/caveman-claude-code-skill-token-savings-review/) |

**Bottom line:** Caveman cuts cost, not confusion. It drops articles, filler and pleasantries,
and it protects code, commands and error strings from compression. Every independent test puts
the real saving between 8% and 21% against a claimed 65%, and one benchmark showed the two
words "be brief" did the same job. The one finding worth keeping is the accuracy result: forcing
a big model to be brief made it more correct, so brevity is a quality lever and not only a
billing lever.

Hacker News had no story inside the window. The viral thread was April, the JetBrains test July.

_Starting point for research. Verify before acting._
