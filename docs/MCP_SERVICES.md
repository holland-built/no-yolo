# MCP Services & External Dependencies

How skills in this repo depend on MCP servers, and how they must behave when one
is unreachable. If a skill silently degrades and you don't know why, check here.

This doc is generic on purpose — it describes the *contract*, not one person's
setup. Your actual server addresses, keys, and network details live in your own
(gitignored) `settings.json` / `settings.local.json`, never in a published doc.

## Web data provider (Firecrawl)

Some skills prefer an MCP web-data provider (Firecrawl) over the built-in
`WebSearch`/`WebFetch` because it returns full page content and defeats crawl/
login walls. This is configured per-environment:

- **Hosted:** point the MCP at firecrawl.dev with an `fc-...` API key.
- **Self-hosted:** set `FIRECRAWL_API_URL` to your instance. A self-hosted
  instance typically runs keyless — no `FIRECRAWL_API_KEY` needed.

**If you don't have Firecrawl configured, nothing breaks.** The skills fall back
to built-in `WebSearch`/`WebFetch` — snippet-depth with soft date filters
instead of full content with a hard recency gate. Degraded, not broken. Firecrawl
is an optional upgrade, not a requirement to install this repo.

### Installing it (optional)

**1. Get a Firecrawl endpoint** — pick one:
- **Hosted:** sign up at firecrawl.dev, get an `fc-...` API key. Simplest.
- **Self-hosted:** run the open-source server (Docker). It exposes an HTTP API
  on a port you choose and typically runs keyless. Good if you want no per-call
  cost or you're crawling internal/large volume. Making it reachable from
  wherever you run sessions is your own networking concern.

**2. Register the MCP server** (one command):
```
claude mcp add firecrawl -- npx -y firecrawl-mcp
```

**3. Tell it where your endpoint is** — set ONE of these in your `settings.json`
`env` block (or the server's env), matching step 1:
```
# hosted:
FIRECRAWL_API_KEY=fc-...
# self-hosted:
FIRECRAWL_API_URL=http://<your-firecrawl-host>:<port>
```

Restart the session; `claude mcp list` should show `firecrawl … ✔ Connected`.
From then on, skills that prefer Firecrawl use it automatically and fall back to
`WebSearch` if it ever stops responding.

### The fallback pattern (reference: `skills/last-30/SKILL.md`)

Any skill that reaches for an optional MCP provider must degrade gracefully —
the server may be unconfigured, or self-hosted and offline. The pattern:

1. **One preflight probe** — a single cheap call up front to decide if the
   provider is live. Do NOT discover it's down once per source; each dead call
   can stall several seconds.
2. **Pick the mode once** — probe succeeds → provider mode; probe fails →
   built-in mode for the whole run, announced in one line.
3. **Every source lists both forms** — the MCP call and the built-in
   equivalent — so the fallback mode is fully usable and never worse than not
   having the provider at all.

Copy this shape into any new skill that depends on an optional MCP server.

Keep the specific server addresses and keys in your own gitignored config
(`settings.json` / `settings.local.json`), never in a published doc.
