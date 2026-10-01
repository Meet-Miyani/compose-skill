#!/usr/bin/env python3
"""Generates the README charts (light and dark SVG) from the published v5 results.

Sources: evals-v2/results-v5/VERDICT.md (scores, both-graders-agree) and evals-v2/results-v5/kit-tokens.txt (kit
context, upper bound). Run from the repo root: python3 docs/assets/make-charts.py
"""
import os

OUT = os.path.dirname(os.path.abspath(__file__))
FONT = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif"
THEME = {
    "light": {"text": "#0b0b0b", "muted": "#52514e", "grid": "#e4e3df", "rule": "#b9b8b2",
              "kit": "#2a78d6", "nokit": "#eb6834", "link": "#b9b8b2", "bg": "#ffffff"},
    "dark": {"text": "#f0f0ee", "muted": "#c3c2b7", "grid": "#33332f", "rule": "#5c5b56",
             "kit": "#3987e5", "nokit": "#d95926", "link": "#5c5b56", "bg": "#0d1117"},
}

# held-out v5, both graders agree, % of 43 rubric items (VERDICT.md)
# (name, no kit %, kit %, published lift label)
LIFT = [("Gemini 3.8 Flash", 51.2, 76.7, "+25.6"), ("Sonnet 5.5", 55.8, 74.4, "+18.6"), ("Opus 5.5", 65.1, 74.4, "+9.3"),
        ("GPT-6-Sol", 72.1, 76.7, "+4.6"), ("GPT-6-Luna", 65.1, 67.4, "+2.3")]
# held-out v5, max kit tokens per task (kit-tokens.txt, panel models)
TOKENS = [("Opus 5.5", 9853), ("Sonnet 5.5", 13989), ("GPT-6-Luna", 18259), ("GPT-6-Sol", 26404),
          ("Gemini 3.8 Flash", 26534)]


def text(x, y, s, fill, size=13, anchor="start", weight="400", halo=None):
    h = f'stroke="{halo}" stroke-width="4" paint-order="stroke" ' if halo else ""
    return (f'<text x="{x}" y="{y}" fill="{fill}" font-size="{size}" font-weight="{weight}" {h}'
            f'text-anchor="{anchor}" font-family="{FONT}">{s}</text>')


def lift_chart(mode):
    c = THEME[mode]; W, H = 760, 352; L, R, T = 150, 690, 92; row = 40
    lo, hi = 40, 80
    x = lambda v: L + (v - lo) / (hi - lo) * (R - L)
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" '
         f'aria-label="Held-out v5: rubric score with and without the kit for five models">']
    p.append(text(24, 32, "With the kit vs without: held-out v5", c["text"], 17, weight="600"))
    p.append(text(24, 54, "% of 43 rubric items passed, both blind graders agree · 120 agentic runs · 8 new tasks",
                  c["muted"], 12))
    # legend
    p.append(f'<circle cx="{L + 6}" cy="74" r="6" fill="{c["nokit"]}"/>' + text(L + 18, 78, "No kit", c["muted"], 12))
    p.append(f'<circle cx="{L + 96}" cy="74" r="6" fill="{c["kit"]}"/>' + text(L + 108, 78, "With the kit", c["muted"], 12))
    p.append(text(R + 42, 78, "lift", c["muted"], 12, "end"))
    base = T + 24 + len(LIFT) * row - 18
    for v in range(lo, hi + 1, 10):
        p.append(f'<line x1="{x(v):.1f}" y1="{T + 8}" x2="{x(v):.1f}" y2="{base}" stroke="{c["grid"]}" stroke-width="1"/>')
        p.append(text(f"{x(v):.1f}", base + 18, f"{v}%", c["muted"], 11, "middle"))
    for i, (name, a, b, lab) in enumerate(LIFT):
        y = T + 24 + i * row
        p.append(text(L - 14, y + 4, name, c["text"], 13, "end"))
        p.append(f'<line x1="{x(a):.1f}" y1="{y}" x2="{x(b):.1f}" y2="{y}" stroke="{c["link"]}" stroke-width="2"/>')
        p.append(f'<circle cx="{x(a):.1f}" cy="{y}" r="6" fill="{c["nokit"]}"/>')
        p.append(f'<circle cx="{x(b):.1f}" cy="{y}" r="6" fill="{c["kit"]}"/>')
        p.append(text(R + 42, y + 4, lab, c["text"], 13, "end", "600" if b - a >= 8 else "400"))
    p.append(text(24, H - 14, "Lifts of 8+ points are claimable under the pre-registered rules; smaller ones are within noise.",
                  c["muted"], 11))
    p.append("</svg>")
    return "\n".join(p)


def token_chart(mode):
    c = THEME[mode]; W, H = 760, 320; L, R, T = 150, 660, 100; row = 34; top = 30000
    x = lambda v: L + v / top * (R - L)
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" '
         f'aria-label="Most kit context loaded on any one task, per model, against the 20k design budget">']
    p.append(text(24, 32, "Kit context per task: progressive loading", c["text"], 17, weight="600"))
    p.append(text(24, 54, "Most kit tokens any single task loaded (upper bound) · full kit ≈ 127k tokens · held-out v5",
                  c["muted"], 12))
    base = T + len(TOKENS) * row
    for v in range(0, top + 1, 10000):
        p.append(f'<line x1="{x(v):.1f}" y1="{T - 6}" x2="{x(v):.1f}" y2="{base}" stroke="{c["grid"]}" stroke-width="1"/>')
        p.append(text(f"{x(v):.1f}", base + 18, f"{v // 1000}k", c["muted"], 11, "middle"))
    bx = x(20000)
    p.append(f'<line x1="{bx:.1f}" y1="{T - 14}" x2="{bx:.1f}" y2="{base}" stroke="{c["rule"]}" stroke-width="2" '
             f'stroke-dasharray="5 4"/>')
    p.append(text(f"{bx + 6:.1f}", T - 16, "20k design budget", c["muted"], 11))
    for i, (name, v) in enumerate(TOKENS):
        y = T + i * row
        p.append(text(L - 14, y + 16, name, c["text"], 13, "end"))
        p.append(f'<path d="M{L},{y + 4} H{x(v) - 4:.1f} a4,4 0 0 1 4,4 v10 a4,4 0 0 1 -4,4 H{L} Z" fill="{c["kit"]}"/>')
        p.append(text(f"{x(v) + 8:.1f}", y + 17, f"{v / 1000:.1f}k", c["text"], 12, halo=c["bg"]))
    p.append(text(24, H - 14, "Reviews and bug fixes stayed at 1–13k; only new features read past 20k (Sol, Flash).",
                  c["muted"], 11))
    p.append("</svg>")
    return "\n".join(p)


for mode in ("light", "dark"):
    open(os.path.join(OUT, f"v5-kit-lift-{mode}.svg"), "w").write(lift_chart(mode) + "\n")
    open(os.path.join(OUT, f"v5-kit-context-{mode}.svg"), "w").write(token_chart(mode) + "\n")
print("wrote 4 SVGs to", OUT)
