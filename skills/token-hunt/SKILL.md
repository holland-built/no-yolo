---
name: token-hunt
description: Use this skill when the user types /token-hunt, says 'steal tokens from a site', 'find sites like mine', 'match the style of', or 'find me design inspiration'. Finds 5 reference sites matching a site's design intent, extracts their CSS tokens, lets user pick one, outputs a token bag ready for design-full.
user-invocable: true
argument-hint: "[your-site-url] [--into-design-full]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Agent
---

# token-hunt

Target URL: $ARGUMENTS

Finds 5 reference sites matching your site's design intent. Extracts CSS tokens from each. You pick one. The stolen token set becomes the palette seed — feed it into `/design-full` or apply directly.

---

## Step 0 — Get source URL

Parse `$ARGUMENTS` for a URL (starts with `http`).

- URL found → use it
- No URL → ask: **"What's your site URL? (or describe the vibe — e.g. 'clean SaaS dashboard', 'minimal portfolio', 'bold e-commerce')"**

Detect `--into-design-full` flag in `$ARGUMENTS`. If present, chain to `/design-full` after the pick gate using the stolen tokens as palette seed.

---

## Step 1 — Analyze source site intent

```bash
# Fetch the page
curl -s -L --max-time 10 "$SOURCE_URL" -o /tmp/th-source.html 2>/dev/null || echo "fetch-failed"
```

If fetch fails → infer intent from URL domain/path alone.

If fetch succeeds, extract:
- Title + meta description
- Primary visible text (first 500 chars of body text)
- Any existing CSS custom property names (signal the design vocabulary)

```bash
python3 - <<'EOF'
import re, sys
html = open('/tmp/th-source.html').read()
# Extract CSS link hrefs
css_links = re.findall(r'href=["\']([^"\']*\.css[^"\']*)["\']', html)
# Extract :root vars inline
root_vars = re.findall(r'--[a-z][a-zA-Z0-9-]*\s*:\s*[^;}\n]+', html)
# Extract title
title = re.search(r'<title[^>]*>([^<]+)</title>', html, re.I)
# Meta description
desc = re.search(r'<meta[^>]+name=["\']description["\'][^>]+content=["\']([^"\']+)["\']', html, re.I)
print("TITLE:", title.group(1).strip() if title else "?")
print("DESC:", desc.group(1).strip()[:200] if desc else "?")
print("CSS_FILES:", len(css_links))
print("INLINE_VARS:", len(root_vars))
for v in root_vars[:10]:
    print(" ", v.strip())
EOF
```

From this, write a 1-sentence intent summary:
```
INTENT: [industry/category] — [visual tone: minimal/bold/editorial/playful/corporate/technical] — [key traits: e.g. "dark + dense", "white space heavy", "type-forward"]
```

---

## Step 2 — Find 5 reference sites

Spawn one Agent with WebSearch access. Give it the INTENT string and ask it to find 5 real, live websites that:
- Match the same industry/category
- Match or exceed the visual tone
- Are well-regarded for their design (not generic templates)
- Are publicly accessible without login

Agent returns: 5 entries, each with:
- Site name
- URL
- One-line aesthetic description (e.g. "dark editorial, strong type hierarchy, minimal color")

If any URL is inaccessible → replace with next candidate. Must return exactly 5 working URLs.

---

## Step 3 — Extract CSS tokens from each site

For each of the 5 URLs, run this extraction in parallel (5 agents or sequential bash):

```bash
python3 - <<'PYEOF'
import re, urllib.request, urllib.parse, sys

url = sys.argv[1]
base = urllib.parse.urlparse(url)
base_url = f"{base.scheme}://{base.netloc}"

headers = {'User-Agent': 'Mozilla/5.0 (compatible; token-hunter/1.0)'}

def fetch(u, timeout=8):
    try:
        req = urllib.request.Request(u, headers=headers)
        return urllib.request.urlopen(req, timeout=timeout).read().decode('utf-8', errors='ignore')
    except:
        return ""

# Fetch page
html = fetch(url)

# Find CSS URLs
css_hrefs = re.findall(r'href=["\']([^"\']*\.css(?:\?[^"\']*)?)["\']', html)
css_urls = []
for h in css_hrefs[:6]:  # cap at 6 CSS files
    if h.startswith('http'):
        css_urls.append(h)
    elif h.startswith('//'):
        css_urls.append(f"{base.scheme}:{h}")
    elif h.startswith('/'):
        css_urls.append(f"{base_url}{h}")
    else:
        css_urls.append(f"{base_url}/{h}")

# Also check for inline :root in HTML
all_css = html
for cu in css_urls:
    all_css += "\n" + fetch(cu)

# Extract CSS custom properties from :root
root_blocks = re.findall(r':root\s*\{([^}]+)\}', all_css)
vars_found = {}
for block in root_blocks:
    pairs = re.findall(r'(--[a-zA-Z][a-zA-Z0-9-]*)\s*:\s*([^;}\n]+)', block)
    for k, v in pairs:
        vars_found[k.strip()] = v.strip()

# Categorize
colors = {k: v for k, v in vars_found.items() if any(x in k.lower() for x in ['color','bg','background','text','foreground','primary','secondary','accent','border','muted','surface','brand']) or re.search(r'#[0-9a-fA-F]{3,8}|rgb|hsl', v)}
fonts = {k: v for k, v in vars_found.items() if any(x in k.lower() for x in ['font','family','typeface'])}
spacing = {k: v for k, v in vars_found.items() if any(x in k.lower() for x in ['spacing','space','gap','padding','margin','size','radius'])}
other = {k: v for k, v in vars_found.items() if k not in colors and k not in fonts and k not in spacing}

print(f"=== {url} ===")
print(f"COLORS ({len(colors)}):")
for k, v in list(colors.items())[:20]:
    print(f"  {k}: {v}")
print(f"FONTS ({len(fonts)}):")
for k, v in fonts.items():
    print(f"  {k}: {v}")
print(f"SPACING ({len(spacing)}):")
for k, v in list(spacing.items())[:10]:
    print(f"  {k}: {v}")
print(f"OTHER ({len(other)}) vars also found.")
PYEOF
```

Run for each of the 5 URLs. Capture output per site.

**Fallback:** if a site has < 3 CSS vars (no custom property system), extract hard-coded color hex values from the CSS using:
```bash
grep -oP '#[0-9a-fA-F]{3,8}' /tmp/th-site-N.css | sort | uniq -c | sort -rn | head -10
```
And note: `[site name] uses hard-coded values — tokens inferred from most-used colors.`

---

## Step 4 — Present token table

Print:

```
## 5 Reference Token Sets

| # | Site | Aesthetic | Colors (sample) | Fonts | Radius feel |
|---|------|-----------|-----------------|-------|-------------|
| 1 | ...  | ...       | ■ #hex ■ #hex   | ...   | sharp/soft/round |
| 2 | ...  | ...       | ...             | ...   | ... |
...
```

Show 2-3 color swatches inline using the hex values. State var count found per site.

For sites with few vars: label `(inferred — no design system detected)`.

---

## PICK GATE — Hard stop

Ask: **"Which site's tokens? (1–5 / mix 1+3 / redirect / skip — I'll describe my own)"**

- Single number → use that site's tokens
- Mix → take colors from first, fonts from second
- Skip / describe own → user describes a palette in plain English → synthesize token set from description
- Redirect → re-run Step 2 with adjusted search terms

**STOP. Do not proceed until answered.**

---

## Step 5 — Write token output

From chosen site(s), write:

```bash
mkdir -p .mockups/token-hunt
```

Write `.mockups/token-hunt/stolen-tokens.md`:

```markdown
# Stolen Tokens
Source: [site name] ([url])
Extracted: [date]

## CSS Custom Properties
\`\`\`css
:root {
  /* Colors */
  --color-background: [value];
  --color-surface: [value];
  --color-text: [value];
  --color-accent: [value];
  --color-muted: [value];
  --color-border: [value];

  /* Typography */
  --font-sans: [value];
  --font-serif: [value or "none"];

  /* Spacing */
  --radius: [value];
  --spacing-base: [value];
}
\`\`\`

## Palette Seed (for design-full)
background: [hex]
surface:    [hex]
accent:     [hex]
text:       [hex]
muted:      [hex]

## Font Stack
primary: [font name]
secondary: [font name or "none"]
```

Print: `Token set written to .mockups/token-hunt/stolen-tokens.md`

---

## Step 6 — Chain (if --into-design-full)

If `--into-design-full` was in `$ARGUMENTS`:

Print: `Handing off to /design-full with stolen palette seed. Gate 1 (audit) is next.`

Invoke `/design-full` — passing the stolen palette seed as the Step 0d override. In the design-full run, Step 0d reads `.mockups/token-hunt/stolen-tokens.md` instead of generating a palette from Radix/Open Color.

Otherwise: print the stolen-tokens.md content and stop. User can pass it to `/design-full` manually or apply directly.
