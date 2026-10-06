#!/usr/bin/env python3
"""Generates the README and site charts (light and dark SVG) from the published results.

Sources: evals-v2/results-v6/VERDICT.md and ADDONS.md (v6 scores, both-graders-agree), evals-v2/results-v5/VERDICT.md
(v5 scores) and evals-v2/results-v5/kit-tokens.txt (kit context, upper bound). Run from the repo root:
python3 docs/assets/make-charts.py
"""
import os

OUT = os.path.dirname(os.path.abspath(__file__))
FONT = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif"
THEME = {
    "light": {"text": "#0b0b0b", "muted": "#52514e", "grid": "#e4e3df", "rule": "#b9b8b2",
              "kit": "#2a78d6", "nokit": "#eb6834", "link": "#b9b8b2", "bg": "#ffffff", "v60": "#85847f"},
    "dark": {"text": "#f0f0ee", "muted": "#c3c2b7", "grid": "#33332f", "rule": "#5c5b56",
             "kit": "#3987e5", "nokit": "#d95926", "link": "#5c5b56", "bg": "#0d1117", "v60": "#8c8b85"},
}

# held-out v5, both graders agree, % of 43 rubric items (VERDICT.md)
# (name, no kit %, kit %, published lift label)
LIFT = [("Gemini 3.8 Flash", 51.2, 76.7, "+25.6"), ("Sonnet 5.5", 55.8, 74.4, "+18.6"), ("Opus 5.5", 65.1, 74.4, "+9.3"),
        ("GPT-6-Sol", 72.1, 76.7, "+4.6"), ("GPT-6-Luna", 65.1, 67.4, "+2.3")]
# v6 test, both graders agree, % of 39 rubric items (results-v6/VERDICT.md, ADDONS.md)
# (name, no kit %, v6.0 %, v6.1 %, lift label, add-on?), sorted by lift
MODELS6 = [("Gemini 3.8 Flash", 56.4, 84.6, 87.2, "+30.8", False), ("GPT-6-Luna", 71.8, 89.7, 94.9, "+23.1", False),
           ("DeepSeek V4.1 Flash", 82.1, 89.7, 97.4, "+15.4", True), ("DeepSeek V4 Pro", 74.4, 76.9, 87.2, "+12.8", True),
           ("GPT-6-Sol", 76.9, 87.2, 87.2, "+10.3", False), ("Sonnet 5.5", 79.5, 89.7, 87.2, "+7.7", False),
           ("Muse Spark 1.3", 69.2, 69.2, 74.4, "+5.1", False)]
# v6 test, 5 panel models together, % of items (VERDICT.md "By task type")
# (task type, items note, no kit %, v6.0 %, v6.1 %)
TASKS6 = [("Conform", "2 tasks, 60 items", 73.3, 75.0, 80.0), ("Review", "2 tasks, 75 items", 78.7, 94.7, 94.7),
          ("New feature", "2 tasks, 60 items", 58.3, 80.0, 81.7)]
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


def models6_chart(mode):
    c = THEME[mode]; W, H = 760, 466; L, R, T = 190, 670, 92; row = 40
    lo, hi = 50, 100
    x = lambda v: L + (v - lo) / (hi - lo) * (R - L)
    vals = "; ".join(f"{n} {a}% / {b}% / {k}% ({lab})" for n, a, b, k, lab, _ in MODELS6)
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" '
         f'aria-label="v6 test: rubric score without the kit, with the v6.0 kit and with the v6.1 kit, for seven models, '
         f'as percent of 39 items (no kit / v6.0 / v6.1, lift of v6.1 over no kit): {vals}. The two DeepSeek models are '
         f'add-ons graded by Claude and GPT.">']
    p.append(text(24, 32, "With the v6.1 kit vs without: all models", c["text"], 17, weight="600"))
    p.append(text(24, 54, "% of 39 rubric items, both blind graders agree · 6 new tasks · 90 + 36 agentic runs",
                  c["muted"], 12))
    # legend
    lx = L
    p.append(f'<circle cx="{lx + 6}" cy="74" r="6" fill="{c["nokit"]}"/>' + text(lx + 18, 78, "No kit", c["muted"], 12))
    p.append(f'<circle cx="{lx + 94}" cy="74" r="4.25" fill="{c["bg"]}" stroke="{c["muted"]}" stroke-width="2"/>'
             + text(lx + 106, 78, "v6.0", c["muted"], 12))
    p.append(f'<circle cx="{lx + 170}" cy="74" r="6" fill="{c["kit"]}"/>' + text(lx + 182, 78, "v6.1", c["muted"], 12))
    p.append(text(R + 62, 78, "v6.1 lift", c["muted"], 12, "end"))
    base = T + 24 + len(MODELS6) * row - 18
    for v in range(lo, hi + 1, 10):
        p.append(f'<line x1="{x(v):.1f}" y1="{T + 8}" x2="{x(v):.1f}" y2="{base}" stroke="{c["grid"]}" stroke-width="1"/>')
        p.append(text(f"{x(v):.1f}", base + 18, f"{v}%", c["muted"], 11, "middle"))
    for i, (name, a, b, k, lab, addon) in enumerate(MODELS6):
        y = T + 24 + i * row
        p.append(text(L - 14, y + 4, name + (" *" if addon else ""), c["text"], 13, "end"))
        lo_v, hi_v = min(a, b, k), max(a, b, k)
        p.append(f'<line class="chart-connector" pathLength="1" x1="{x(lo_v):.1f}" y1="{y}" x2="{x(hi_v):.1f}" y2="{y}" '
                 f'stroke="{c["link"]}" stroke-width="2"/>')
        p.append(f'<circle cx="{x(a):.1f}" cy="{y}" r="6" fill="{c["nokit"]}"/>')
        p.append(f'<circle class="chart-kit-dot" cx="{x(k):.1f}" cy="{y}" r="6" fill="{c["kit"]}"/>')
        p.append(f'<circle cx="{x(b):.1f}" cy="{y}" r="4.25" fill="{c["bg"]}" stroke="{c["muted"]}" stroke-width="2"/>')
        p.append(text(R + 62, y + 4, lab, c["text"], 13, "end", "600").replace("<text ", '<text class="chart-lift" '))
    fy = base + 44
    p.append(text(24, fy, "* Add-on, graded by Claude + GPT; compare across groups with care", c["muted"], 11))
    p.append(text(24, fy + 18, "One generation per cell and 6 tasks: differences of about 3 items or fewer are noise.",
                  c["muted"], 11))
    p.append("</svg>")
    return "\n".join(p)


def tasks6_chart(mode):
    c = THEME[mode]; W, H = 760, 412; L, R, T = 150, 660, 100; bh, gap, grp = 16, 5, 34
    x = lambda v: L + v / 100 * (R - L)
    arms = [("No kit", c["nokit"]), ("v6.0", c["v60"]), ("v6.1", c["kit"])]
    vals = "; ".join(f"{n} {a}% / {b}% / {k}%" for n, _, a, b, k in TASKS6)
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" '
         f'aria-label="v6 test by task type, five panel models together, percent of rubric items passed (no kit / v6.0 / '
         f'v6.1): {vals}.">']
    p.append(text(24, 32, "Where the kit helps (v6 test, 5 panel models)", c["text"], 17, weight="600"))
    p.append(text(24, 54, "% of rubric items, both blind graders agree · 6 new tasks × 5 models × 3 arms · 90 runs",
                  c["muted"], 12))
    lx = L
    for j, (lab, col) in enumerate(arms):
        p.append(f'<rect x="{lx + j * 84}" y="68" width="12" height="12" rx="2" fill="{col}"/>'
                 + text(lx + j * 84 + 18, 78, lab, c["muted"], 12))
    group_h = 3 * bh + 2 * gap
    base = T + len(TASKS6) * (group_h + grp) - grp + 8
    for v in range(0, 101, 20):
        p.append(f'<line x1="{x(v):.1f}" y1="{T - 8}" x2="{x(v):.1f}" y2="{base}" stroke="{c["grid"]}" stroke-width="1"/>')
        p.append(text(f"{x(v):.1f}", base + 18, f"{v}%", c["muted"], 11, "middle"))
    for gi, (name, note, *vs) in enumerate(TASKS6):
        y0 = T + gi * (group_h + grp)
        p.append(text(L - 14, y0 + group_h / 2 - 2, name, c["text"], 13, "end", "600"))
        p.append(text(L - 14, y0 + group_h / 2 + 14, note, c["muted"], 11, "end"))
        for bi, ((lab, col), v) in enumerate(zip(arms, vs)):
            y = y0 + bi * (bh + gap)
            p.append(f'<path d="M{L},{y} H{x(v) - 3:.1f} a3,3 0 0 1 3,3 v{bh - 6} a3,3 0 0 1 -3,3 H{L} Z" fill="{col}"/>')
            p.append(text(f"{x(v) + 8:.1f}", y + 12, f"{v:.1f}%", c["text"], 12, halo=c["bg"],
                          weight="600" if bi == 2 else "400"))
    p.append(text(24, H - 14, "Conform: v6.0 added retry buttons and error screens; v6.1 mostly stopped (no-new-UI item 2 of 10 to 8 of 10).",
                  c["muted"], 11))
    p.append("</svg>")
    return "\n".join(p)


for mode in ("light", "dark"):
    open(os.path.join(OUT, f"v5-kit-lift-{mode}.svg"), "w").write(lift_chart(mode) + "\n")
    open(os.path.join(OUT, f"v5-kit-context-{mode}.svg"), "w").write(token_chart(mode) + "\n")
    open(os.path.join(OUT, f"v6-models-{mode}.svg"), "w").write(models6_chart(mode) + "\n")
    open(os.path.join(OUT, f"v6-task-types-{mode}.svg"), "w").write(tasks6_chart(mode) + "\n")
print("wrote 8 SVGs to", OUT)
