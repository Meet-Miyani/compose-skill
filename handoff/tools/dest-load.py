#!/usr/bin/env python3
"""Kept-row load per destination file across HARVEST_LEDGER.md + EXTERNAL_LEDGER.md.
Flags destinations over the cap (default 20; mvi-contract.md 25; SKILL.md/examples.md/templates exempt).
Usage: handoff/tools/dest-load.py [--cap 20]   Exit 1 if any destination is over its cap."""
import re, sys, collections, os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
cap = int(sys.argv[sys.argv.index("--cap") + 1]) if "--cap" in sys.argv else 20
special = {"compose-architecture/references/mvi-contract.md": 25}
load = collections.defaultdict(lambda: [0, 0]); bad = []
for i, name in enumerate(["HARVEST_LEDGER.md", "EXTERNAL_LEDGER.md"]):
    p = os.path.join(ROOT, "handoff", "work", name)
    if not os.path.exists(p): continue
    for line in open(p):
        if line.startswith("## Findings"): break
        if not re.match(r"^\|\s*[A-Z]+-\d+\s*\|", line): continue
        c = [x.strip() for x in line.strip().strip("|").split("|")]
        if len(c) < 5: bad.append(line[:80]); continue
        cls, dest = c[3], c[4]
        if not dest: bad.append(f"{c[0]}: empty destination"); continue
        if dest.startswith("DROP"): continue
        if not re.fullmatch(r"[A-Z]+", cls): bad.append(f"{c[0]}: malformed class '{cls[:40]}'")
        load[dest.split("#")[0]][i] += 1
over = 0
print(f"{'harvest':>7} {'extern':>6} {'total':>5}  destination")
for d, (h, e) in sorted(load.items(), key=lambda kv: -sum(kv[1])):
    exempt = d.endswith("SKILL.md") or d.endswith("examples.md") or "/templates/" in d
    lim = special.get(d, cap)
    flag = "" if exempt or h + e <= lim else f"  OVER (cap {lim})"
    over += bool(flag)
    print(f"{h:7d} {e:6d} {h+e:5d}  {d}{flag}")
print(f"\nmalformed/empty rows: {len(bad)}"); [print("  " + b) for b in bad[:30]]
print(f"destinations over cap: {over}")
sys.exit(1 if over or bad else 0)
