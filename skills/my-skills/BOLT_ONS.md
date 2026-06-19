# Bolt-on Dependencies — external CLIs and tools skills depend on

| Tool | Version | Used by | What it does | When to use | How to use | Why to use |
|---|---|---|---|---|---|---|
| **fallow** | 2.98.0 | code-health | Static analysis: dead exports, duplicate code, security issues, unused deps. Free, no LLM, runs instantly. | Before any cleanup run | `npm install -g fallow` | Free, no LLM, instant. Runs before ponytail so LLM only sees real issues |
| **graphify** | 0.8.38 | forge, graphify | Builds an AST knowledge graph. Lets you ask "what calls X?" or "what depends on Y?" without reading every file. | Unfamiliar codebase | `uv tool install graphify` | Answers dependency questions without reading every file |
| **gh** (GitHub CLI) | 2.92.0 | code-review | Fetches PR diffs and metadata from GitHub for diff review. | Reviewing a PR | `brew install gh && gh auth login` | Pulls the real diff automatically — no copy-paste |
| **Chrome** (headless) | 147.x | quick-design, forge | Screenshots HTML mockups so you can see them inline without opening a browser. | Any mockup generation | Pre-installed on most systems | See the mockup without opening a browser tab |
| **Playwright** | 1.61.0 | forge | Browser automation for phase 0 DOM measurement and phase 6 prove (layout assertions, smoke tests). Via MCP plugin. | forge phase 0 + phase 6 | Add playwright MCP to `settings.json` | Numeric proof of layout correctness — not visual assertion |
| **Graphviz** (`dot`) | 15.0.0 | drawio-skill | Graph layout engine — used by draw.io scripts to auto-arrange diagram nodes. | drawio-skill runs it | `brew install graphviz` | Auto-arranges nodes — no manual positioning |
| **draw.io** CLI | homebrew | drawio-skill | Generates diagrams from XML. Exports PNG/SVG/PDF. | drawio-skill runs it | `brew install --cask drawio` | Batch diagram generation from structured input |
| **Groq Whisper** | groq_quota.py | video-to-kb, graphify | Transcribes audio/video to text cheaply via Groq API. Requires `GROQ_API_KEY`. | video-to-kb runs it | Set `GROQ_API_KEY` in shell | Cheap and fast — far cheaper than OpenAI Whisper at scale |
| **shadcn MCP** | plugin | ui-ux | Design system component library for the design intelligence scripts. Requires shadcn MCP plugin. | ui-ux runs it | Add shadcn MCP to `settings.json` | Grounds design suggestions in real component constraints |
| **impeccable** | symlinked skill | forge, ui-wild | Editorial-poster design theme — warm cream + burnt orange aesthetic. Now in ~/.claude/skills/ (symlinked from ~/.agents/skills/). | forge/ui-wild UI phases | `/impeccable` directly or invoked by forge | Default Claude UI looks like defaults. This gives it a distinctive editorial identity |
