#!/usr/bin/env python3
"""Render a pick-one page from brand specifications in refs/brands/.

    python3 render-picker.py apple stripe linear  [--out PATH]  [--for "a booking site"]

WHY THIS EXISTS. The owner is not a designer and cannot judge a design from its name. A list
of 74 brand slugs is unreadable to them; three rendered cards are not. So the door never
prints names, it prints this page, and the owner points at one.

WHAT A CARD IS. Each brand's own primary colour, its own canvas and ink, its own first
typeface, drawn as a heading, a line of body text, a filled button and an outlined one. The
values come from that brand's DESIGN.md and nowhere else, so what the owner sees is what the
brand actually uses.

FAILS LOUD. A brand that does not exist, or whose specification cannot be parsed, is an
error with the name in it. A picker that silently drops one of three choices would let the
owner choose from two while believing they chose from three.
"""
import argparse
import html
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[3]
BRANDS = REPO / "refs" / "brands"


def find_spec(slug):
    d = BRANDS / slug
    if not d.is_dir():
        raise SystemExit(f"error: no brand named {slug!r} in {BRANDS}")
    direct = d / "DESIGN.md"
    if direct.exists():
        return direct
    nested = list(d.rglob("DESIGN.md"))
    if not nested:
        raise SystemExit(f"error: {slug!r} has no DESIGN.md")
    return nested[0]


def spec_key(txt, *names, default=""):
    """First matching `name: value` in the YAML-ish front matter."""
    for n in names:
        m = re.search(rf'^\s*{re.escape(n)}:\s*"?\'?([^"\'\n]+)', txt, re.M)
        if m:
            return m.group(1).strip().rstrip(",")
    return default


def parse(slug):
    txt = find_spec(slug).read_text(encoding="utf-8", errors="replace")
    desc = spec_key(txt, "description")
    colours = {
        "primary": spec_key(txt, "primary", "accent", default="#444444"),
        "canvas": spec_key(txt, "canvas", "background", "surface", default="#ffffff"),
        "ink": spec_key(txt, "ink", "body", "text", default="#111111"),
        "muted": spec_key(txt, "body-muted", "ink-muted-48", "muted", default="#767676"),
        "line": spec_key(txt, "hairline", "divider-soft", "border", default="#e3e3e3"),
    }
    for k, v in colours.items():
        if not v.startswith("#"):
            colours[k] = {"primary": "#444444", "canvas": "#ffffff", "ink": "#111111",
                          "muted": "#767676", "line": "#e3e3e3"}[k]
    m = re.search(r'fontFamily:\s*"?\'?([^"\'\n]+)', txt)
    stack = m.group(1).strip() if m else "system-ui, sans-serif"
    return {
        "slug": slug,
        "desc": desc.split(".")[0] if desc else "",
        "stack": stack,
        "face": stack.split(",")[0].strip().strip("'\""),
        **colours,
    }


CARD = """  <section class="card" style="--primary:{primary};--canvas:{canvas};--ink:{ink};--muted:{muted};--line:{line};--stack:{stack_css}">
    <div class="slug">{n}</div>
    <div class="face">{face}</div>
    <div class="sample">
      <h2>{headline}</h2>
      <p>{body}</p>
      <div class="row">
        <span class="btn solid">Continue</span>
        <span class="btn ghost">Not now</span>
      </div>
      <div class="swatches">{swatches}</div>
    </div>
    <p class="why">{desc}</p>
  </section>
"""

PAGE = """<!doctype html>
<meta charset="utf-8">
<title>Pick one</title>
<style>
  :root {{ color-scheme: light dark; }}
  body {{ font: 16px/1.5 system-ui, -apple-system, sans-serif; margin: 0; padding: 32px;
         background: #f6f6f7; color: #1a1a1a; }}
  h1 {{ font-size: 22px; margin: 0 0 4px; }}
  .lede {{ color: #666; margin: 0 0 28px; }}
  .grid {{ display: grid; gap: 24px; grid-template-columns: repeat(auto-fit, minmax(310px, 1fr));
           max-width: 1180px; }}
  .card {{ border: 1px solid #dcdcdc; border-radius: 12px; overflow: hidden; background: #fff; }}
  .slug {{ font: 600 13px/1 ui-monospace, monospace; padding: 12px 16px 4px; letter-spacing: .04em;
           text-transform: uppercase; }}
  .face {{ font: 12px/1 ui-monospace, monospace; color: #767676; padding: 0 16px 12px; }}
  .sample {{ background: var(--canvas); color: var(--ink); font-family: var(--stack);
             padding: 26px 22px; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }}
  .sample h2 {{ font-size: 27px; margin: 0 0 10px; letter-spacing: -.02em; line-height: 1.12; }}
  .sample p {{ margin: 0 0 18px; color: var(--muted); font-size: 15px; }}
  .row {{ display: flex; gap: 10px; margin-bottom: 18px; }}
  .btn {{ font-size: 14px; padding: 9px 17px; border-radius: 7px; }}
  .solid {{ background: var(--primary); color: var(--canvas); }}
  .ghost {{ border: 1px solid var(--primary); color: var(--primary); }}
  .swatches {{ display: flex; gap: 6px; }}
  .sw {{ width: 34px; height: 22px; border-radius: 4px; border: 1px solid rgba(128,128,128,.32); }}
  .why {{ font-size: 13px; color: #565656; margin: 0; padding: 14px 16px; }}
  @media (prefers-color-scheme: dark) {{
    body {{ background: #131314; color: #eee; }}
    .card {{ background: #1c1c1e; border-color: #333; }}
    .why {{ color: #a5a5a5; }}
  }}
</style>
<h1>Pick one</h1>
<p class="lede">{lede}</p>
<div class="grid">
{cards}</div>
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("brands", nargs="+", help="brand slugs from refs/brands/")
    ap.add_argument("--out", default=".design/pick.html")
    ap.add_argument("--for", dest="what", default="", help="what is being built")
    ap.add_argument("--headline", default="Book a table")
    ap.add_argument("--body", default="Two minutes, no account needed.")
    a = ap.parse_args()

    if len(a.brands) > 4:
        raise SystemExit("error: at most four cards. The owner's rule is three options.")

    cards = ""
    for slug in a.brands:
        b = parse(slug)
        sw = "".join(
            f'<span class="sw" style="background:{b[k]}"></span>'
            for k in ("primary", "canvas", "ink", "muted")
        )
        cards += CARD.format(
            n=html.escape(b["slug"]),
            face=html.escape(b["face"]),
            desc=html.escape(b["desc"]),
            headline=html.escape(a.headline),
            body=html.escape(a.body),
            stack_css=html.escape(b["stack"]),
            swatches=sw,
            **{k: b[k] for k in ("primary", "canvas", "ink", "muted", "line")},
        )

    lede = f"Three directions for {a.what}." if a.what else "Three directions."
    lede += " Point at the one you want. Nothing is chosen until you say so."

    out = pathlib.Path(a.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(PAGE.format(cards=cards, lede=html.escape(lede)), encoding="utf-8")
    print(out)


if __name__ == "__main__":
    sys.exit(main())
