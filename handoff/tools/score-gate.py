#!/usr/bin/env python3
"""Score a skill-phase eval gate (see make-gate-packets.py) against the PLAN.md gate conditions.

Usage: handoff/tools/score-gate.py <gate-dir> [--weak deepseek,muse] [--ref opus] [--report out.md]
Gate (PLAN.md "Eval gate"): each weak model ≥ 90% rubric items; every pressure scenario held;
no invented-API critical defect; mean quality ≥ the reference's mean quality.
(The "every M2 no-model-passed item passes" condition is listed per item for the moderator to check.)
"""
import argparse, collections, json, os, re

ap = argparse.ArgumentParser()
ap.add_argument("gate")
ap.add_argument("--weak", default="deepseek,muse")
ap.add_argument("--ref", default="opus")
ap.add_argument("--report", default="")
a = ap.parse_args()
key = json.load(open(os.path.join(a.gate, "grading-key.json")))
rub = collections.defaultdict(lambda: [0, 0]); qual = collections.defaultdict(list)
press = collections.defaultdict(dict); defects = collections.defaultdict(list); fails = collections.defaultdict(list)
missing = []
for sid, lab in key.items():
    p = os.path.join(a.gate, "grading", "results", f"{sid}.json")
    if not os.path.exists(p):
        missing.append(sid); continue
    r = json.load(open(p))
    for it in r["items"]:
        for L, m in lab.items():
            ok = bool(it.get(L, {}).get("pass"))
            rub[m][0] += ok; rub[m][1] += 1
            if not ok:
                fails[m].append(f"{sid}#{it.get('n')} {it.get('text','')[:70]} — {it.get(L,{}).get('ev','')[:90]}")
    for L, m in lab.items():
        q = (r.get("quality") or {}).get(L, {})
        if isinstance(q, dict) and q.get("score") is not None:
            qual[m].append(float(q["score"]))
        held = (r.get("pressure_held") or {}).get(L)
        if held is not None:
            press[m][sid] = held
        for d in (r.get("critical_defects") or {}).get(L, []) or []:
            defects[m].append(f"{sid}: {d}")
weak = a.weak.split(","); ref = a.ref
refq = sum(qual[ref]) / len(qual[ref]) if qual[ref] else 0
lines = [f"# Eval gate — {os.path.basename(os.path.abspath(a.gate))}", ""]
if missing:
    lines.append(f"**Missing results:** {', '.join(missing)}\n")
lines += ["| Model | Rubric | Pressure held | Mean quality | Invented-API defects | Gate |", "|---|---|---|---|---|---|"]
allpass = True
for m in weak + [ref]:
    p, n = rub[m]; pct = 100 * p / n if n else 0
    ph = press[m]; held = sum(ph.values()); tot = len(ph)
    mq = sum(qual[m]) / len(qual[m]) if qual[m] else 0
    inv = [d for d in defects[m] if re.search(r"invent|hallucinat|does not exist|non-?existent|wrong api|fabricat", d, re.I)]
    if m in weak:
        ok = pct >= 90 and held == tot and not inv and mq >= refq
        allpass &= ok
        g = "PASS" if ok else "FAIL"
    else:
        g = "reference"
    lines.append(f"| {m} | {p}/{n} ({pct:.0f}%) | {held}/{tot} | {mq:.1f} | {len(inv)} | {g} |")
lines += ["", f"**Gate verdict:** {'PASS' if allpass and not missing else 'FAIL'} "
          f"(conditions: ≥90% rubric, all pressure held, no invented API, quality ≥ {ref} {refq:.1f})", ""]
for m in weak:
    lines += [f"## Failed rubric items — {m}", ""] + [f"- {x}" for x in fails[m]] + [""]
    lines += [f"## Critical defects — {m}", ""] + [f"- {x}" for x in defects[m]] + [""]
out = "\n".join(lines) + "\n"
if a.report:
    open(a.report, "w").write(out)
print(out[:4000])
