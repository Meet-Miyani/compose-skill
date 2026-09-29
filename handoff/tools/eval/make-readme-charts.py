#!/usr/bin/env python3
"""Generate the README result charts (static SVG, light + dark via prefers-color-scheme).

Data: held-out v4 final test, Fable-adjudicated rubric scores (handoff/reviews/m9.md).
Usage: make-readme-charts.py <out-dir>
"""
import os, sys

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

STYLE = """
<style>
  .surface { fill: #fcfcfb; }
  .t1 { fill: #0b0b0b; } .t2 { fill: #52514e; } .t3 { fill: #898781; }
  .grid { stroke: #e1e0d9; } .base { stroke: #c3c2b7; }
  .before { fill: #86b6ef; } .after { fill: #1c5cab; } .link { stroke: #b7d3f6; }
  .ref { stroke: #898781; }
  .s-none { fill: #b4b2a9; } .s-generic { fill: #eb6834; } .s-kit { fill: #2a78d6; }
  text { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
  @media (prefers-color-scheme: dark) {
    .surface { fill: #1a1a19; }
    .t1 { fill: #ffffff; } .t2 { fill: #c3c2b7; } .t3 { fill: #898781; }
    .grid { stroke: #2c2c2a; } .base { stroke: #383835; }
    .before { fill: #1c5cab; } .after { fill: #6da7ec; } .link { stroke: #184f95; }
    .s-none { fill: #6b6a64; } .s-generic { fill: #d95926; } .s-kit { fill: #3987e5; }
  }
</style>"""


def dumbbell():
    rows = [  # model, no kit, with kit (rubric %, adjudicated)
        ("Opus 5.5", 87, 94),
        ("Muse Spark 1.3", 65, 87),
        ("DeepSeek V4.1 Flash", 68, 76),
        ("Gemini 3.8 Flash", 57, 75),
        ("DeepSeek V4 Pro", 56, 75),
        ("MiniMax M3", 54, 59),
        ("GPT-6-Luna", 49, 48),
    ]
    W, top, rowh = 760, 96, 40
    H = top + rowh * len(rows) + 56
    x0, x1, lo, hi = 200, 720, 40, 100
    X = lambda v: x0 + (v - lo) / (hi - lo) * (x1 - x0)
    s = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" '
         f'aria-labelledby="t d">', STYLE,
         '<title id="t">Final test: rubric score without and with the kit</title>',
         '<desc id="d">' + "; ".join(f"{m}: {a}% without the kit, {b}% with it" for m, a, b in rows) + '</desc>',
         f'<rect class="surface" width="{W}" height="{H}" rx="12"/>',
         '<text class="t1" x="24" y="36" font-size="18" font-weight="600">Final test: 12 unseen tasks, blind-graded</text>',
         '<text class="t2" x="24" y="58" font-size="13">Rubric pass rate per model, without the kit and with it (two graders, tie-breaks by a third)</text>']
    # legend
    s += [f'<circle class="before" cx="{x0}" cy="80" r="6"/>',
          f'<text class="t2" x="{x0 + 12}" y="84" font-size="12">Without kit</text>',
          f'<circle class="after" cx="{x0 + 110}" cy="80" r="7"/>',
          f'<text class="t2" x="{x0 + 122}" y="84" font-size="12">With kit</text>',
          f'<line class="ref" x1="{x0 + 200}" y1="80" x2="{x0 + 222}" y2="80" stroke-width="2" stroke-dasharray="4 3"/>',
          f'<text class="t2" x="{x0 + 230}" y="84" font-size="12">Opus 5.5 without the kit (≈86%)</text>']
    gy0, gy1 = top - 8, top + rowh * len(rows) - 8
    for v in range(40, 101, 10):
        s.append(f'<line class="grid" x1="{X(v):.1f}" y1="{gy0}" x2="{X(v):.1f}" y2="{gy1}" stroke-width="1"/>')
        s.append(f'<text class="t3" x="{X(v):.1f}" y="{gy1 + 18}" font-size="11" text-anchor="middle">{v}%</text>')
    s.append(f'<line class="ref" x1="{X(86):.1f}" y1="{gy0}" x2="{X(86):.1f}" y2="{gy1}" stroke-width="2" stroke-dasharray="4 3"/>')
    for i, (m, a, b) in enumerate(rows):
        y = top + i * rowh + 12
        s.append(f'<text class="t1" x="{x0 - 16}" y="{y + 4}" font-size="13" text-anchor="end">{m}</text>')
        s.append(f'<line class="link" x1="{X(a):.1f}" y1="{y}" x2="{X(b):.1f}" y2="{y}" stroke-width="4" stroke-linecap="round"/>')
        s.append(f'<circle class="before surface-ring" cx="{X(a):.1f}" cy="{y}" r="6"/>')
        s.append(f'<circle class="after" cx="{X(b):.1f}" cy="{y}" r="7"/>')
        # the with-kit value is always the bold label; each label sits on its own dot's outer side
        kit_right = b >= a
        s.append(f'<text class="t3" x="{X(a) + (-12 if kit_right else 12):.1f}" y="{y + 4}" font-size="11" '
                 f'text-anchor="{"end" if kit_right else "start"}">{a}</text>')
        s.append(f'<text class="t1" x="{X(b) + (12 if kit_right else -12):.1f}" y="{y + 4}" font-size="12" font-weight="600" '
                 f'text-anchor="{"start" if kit_right else "end"}">{b}</text>')
    s.append(f'<text class="t3" x="24" y="{H - 14}" font-size="11">Held-out v4 · 63 rubric items per answer · Claude-graded, Fable tie-breaks; a GPT-6-Sol cross-check is stricter on kit answers (see Honest limits)</text>')
    s.append('</svg>')
    return "\n".join(s)


def control():
    groups = [("Engineering items", "[eng]", [61, 77, 72]), ("House-style items", "[kit]", [43, 57, 86])]
    series = [("No prompt", "s-none"), ("Generic senior prompt", "s-generic"), ("The kit", "s-kit")]
    W, H = 760, 300
    s = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" role="img" aria-labelledby="t d">',
         STYLE, '<title id="t">Control test on Gemini 3.8 Flash</title>',
         '<desc id="d">Engineering items: no prompt 61%, generic prompt 77%, kit 72%. House-style items: no prompt 43%, generic prompt 57%, kit 86%.</desc>',
         f'<rect class="surface" width="{W}" height="{H}" rx="12"/>',
         '<text class="t1" x="24" y="36" font-size="18" font-weight="600">Control test: the kit vs a one-page senior-engineer prompt</text>',
         '<text class="t2" x="24" y="58" font-size="13">Gemini 3.8 Flash, same 12 tasks, blind-graded twice</text>']
    lx = 24
    for name, cls in series:
        s.append(f'<rect class="{cls}" x="{lx}" y="74" width="12" height="12" rx="2"/>')
        s.append(f'<text class="t2" x="{lx + 18}" y="84" font-size="12">{name}</text>')
        lx += 34 + int(len(name) * 6.4)
    panel_w, px0 = 340, [24, 396]
    bar_h, gap = 22, 2
    for gi, (title, tag, vals) in enumerate(groups):
        ox = px0[gi]
        s.append(f'<text class="t1" x="{ox}" y="122" font-size="14" font-weight="600">{title} <tspan class="t3" font-weight="400">{tag}</tspan></text>')
        bx0, bx1 = ox + 150, ox + panel_w - 20
        X = lambda v: bx0 + v / 100 * (bx1 - bx0)
        for i, ((name, cls), v) in enumerate(zip(series, vals)):
            y = 140 + i * (bar_h + 18)
            s.append(f'<text class="t2" x="{bx0 - 10}" y="{y + 15}" font-size="12" text-anchor="end">{name}</text>')
            s.append(f'<rect class="{cls}" x="{bx0}" y="{y}" width="{X(v) - bx0:.1f}" height="{bar_h}" rx="4"/>')
            s.append(f'<text class="t1" x="{X(v) + 8:.1f}" y="{y + 15}" font-size="12" font-weight="600">{v}%</text>')
        s.append(f'<line class="base" x1="{bx0}" y1="136" x2="{bx0}" y2="{140 + 3 * (bar_h + 18) - 14}" stroke-width="1"/>')
    s.append(f'<text class="t3" x="24" y="{H - 16}" font-size="11">Most of the engineering lift comes from a careful stance; the kit\'s distinct win is one consistent house style.</text>')
    s.append('</svg>')
    return "\n".join(s)


open(os.path.join(OUT, "results-final-test.svg"), "w").write(dumbbell())
open(os.path.join(OUT, "results-control-test.svg"), "w").write(control())
print("written:", OUT)
