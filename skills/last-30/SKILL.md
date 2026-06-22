---
name: last-30
description: Pull what's trending NOW (last 30 days only) on any topic — GitHub, Hacker News, YouTube, X/Twitter. Returns gaining-traction signal, not all-time rankings. Activate on "/last-30", "what's trending in", "last 30 days", "what's hot right now".
user-invocable: true
argument-hint: "[topic / library / tool / pattern to research]"
allowed-tools:
  - WebSearch
  - WebFetch
  - Agent
  - mcp__plugin_ecc_exa__web_search_exa
  - mcp__plugin_ecc_exa__web_fetch_exa
---

Topic: $ARGUMENTS

If $ARGUMENTS is blank: ask "What do you want to research?" — wait for answer before continuing.

**Rule: skip and do not list anything older than 30 days. Recency is mandatory.**

---

## Step 1 — Compute Window

Calculate the 30-day start date: today − 30 days → `YYYY-MM-DD`. State it in one line before proceeding:
`Searching: <topic> | Window: <start> → <today>`

---

## Step 2 — 4 Parallel Source Agents

Fan out in ONE parallel call. Each agent searches one source, returns max 5 results dated within the window. If a source is unavailable, return one row: `SOURCE_UNAVAILABLE: <reason>`.

**Every agent outputs rows in this exact schema (pipe-separated):**
`title | url | signal (metric name + number) | date (YYYY-MM-DD) | one-line summary`

---

### GITHUB AGENT
Search: GitHub trending repos + recent repos for `<topic>`.
- Try: `https://github.com/trending/<language>?since=monthly` filtered to topic
- Try: `https://github.com/search?q=<topic>&s=stars&o=desc&type=repositories&created:><start-date>`
- Keep only repos with activity or creation within the window
- Signal metric: stars gained this month OR total stars if new repo
- Prefer repos with recent commits over old repos with high all-time stars

### HACKER NEWS AGENT
Search: HN discussions from last 30 days.
- Use: `https://hn.algolia.com/?query=<topic>&dateRange=pastMonth&sortBy=byPopularity`
- Include Show HN posts
- Signal metric: points (upvotes)
- Skip link posts older than 30 days even if they appear in results

### YOUTUBE AGENT
Search: recent tutorials and talks on `<topic>`.
- Try WebSearch: `<topic> tutorial 2026 site:youtube.com`
- Try: `https://www.youtube.com/results?search_query=<topic>&sp=CAISBAgEEAE%3D` (this month, by date)
- Signal metric: view count
- Skip anything published before the window start

### X/TWITTER AGENT
Search: high-engagement posts from credible accounts.
- Try WebSearch: `<topic> since:<start-date> min_faves:100`
- Use exa (`mcp__plugin_ecc_exa__web_search_exa`) as fallback if WebSearch returns thin results
- Signal metric: likes/retweets
- Credible accounts: engineers, authors, project maintainers — not news aggregators

---

## Step 3 — Synthesis

After all 4 source agents return, run ONE synthesis pass (inline, not a subagent):

Read all result rows. Produce:
- **Strongest resource:** the single result with highest signal × recency (one line + URL)
- **Cross-source momentum:** anything appearing in ≥2 sources (confirms genuine traction)
- **Emerging shift:** one pattern — "people are moving from X → Y" or "X is gaining fast"
- **Ignore list:** stale or all-time items that kept surfacing despite the window filter

---

## Step 4 — Output

```
## Last 30 Days: <topic>
Window: <start-date> → <today>

| Source | Title | Signal | Date | Why it matters |
|--------|-------|--------|------|----------------|
(GitHub rows — best 1-2)
(HN rows — best 1-2)
(YouTube rows — best 1-2)
(X rows — best 1-2)
(SOURCE_UNAVAILABLE rows if any)

**Synthesis**
- Gaining most traction now: …
- Strongest single resource: <url>
- Emerging shift: …
- Ignore: …

_Starting point for research, not a final answer. Verify before acting._
```

Total output: under 300 words. No files written.
