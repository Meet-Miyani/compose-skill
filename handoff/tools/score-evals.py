#!/usr/bin/env python3
"""Un-blind and score graded eval results.

Usage: handoff/tools/score-evals.py <run-dir> <report.md> [--title "M2 baseline"]
  <run-dir> contains grading-key.json (sid -> {A: model, ...}), evals.snapshot.json and
  grading/results/<ID>.json (written by blind graders).
Writes a markdown report: pass rates per model x skill, pressure results, the rubric items weak
models failed where the reference passed (= what the skills must teach), and critical defects.
"""
import collections, json, os, sys

run, out = sys.argv[1], sys.argv[2]
title = sys.argv[sys.argv.index("--title") + 1] if "--title" in sys.argv else "Eval report"
REF = "claude"
key = json.load(open(os.path.join(run, "grading-key.json")))
ev = json.load(open(os.path.join(run, "evals.snapshot.json")))
ev = ev if isinstance(ev, list) else ev.get("evals") or ev.get("scenarios")
skill_of = {s["id"]: s["skill"] for s in ev}

score = collections.defaultdict(lambda: [0, 0])          # (model, skill) -> [pass, total]
pressure = collections.defaultdict(dict)                 # sid -> model -> held
gaps = collections.defaultdict(list)                     # skill -> [(sid, n, text, failing weak models, evidence)]
defects = collections.defaultdict(list)                  # model -> [(sid, defect)]
missing = []
for sid in key:
    p = os.path.join(run, "grading", "results", f"{sid}.json")
    if not os.path.exists(p):
        missing.append(sid); continue
    r = json.load(open(p))
    lab = key[sid]                                       # label -> model
    for it in r["items"]:
        res = {lab[L]: bool(it.get(L, {}).get("pass")) for L in lab}
        for m, ok in res.items():
            score[(m, skill_of[sid])][0] += ok
            score[(m, skill_of[sid])][1] += 1
        weak_fail = [m for m, ok in res.items() if m != REF and not ok]
        if weak_fail:
            ev_txt = "; ".join(f"{m}: {it[L].get('ev','')}" for L, m in lab.items() if m in weak_fail)
            gaps[skill_of[sid]].append((sid, it.get("n"), it.get("text", ""), weak_fail, res.get(REF), ev_txt))
    for L, held in (r.get("pressure_held") or {}).items():
        if held is not None and L in lab:
            pressure[sid][lab[L]] = held
    for L, ds in (r.get("critical_defects") or {}).items():
        for d in ds or []:
            if L in lab:
                defects[lab[L]].append((sid, d))

models = sorted({m for lab in key.values() for m in lab.values()}, key=lambda m: (m == REF, m))
skills = sorted({skill_of[s] for s in key})
L = [f"# {title}", "", f"Graded scenarios: {len(key) - len(missing)} / {len(key)}"
     + (f" (missing: {', '.join(missing)})" if missing else ""), "",
     "## Rubric pass rate (items passed / items)", "",
     "| Skill | " + " | ".join(models) + " |", "|---|" + "---|" * len(models)]
tot = collections.defaultdict(lambda: [0, 0])
for sk in skills:
    row = []
    for m in models:
        p, n = score[(m, sk)]; tot[m][0] += p; tot[m][1] += n
        row.append(f"{p}/{n} ({round(100*p/n) if n else 0}%)")
    L.append(f"| {sk} | " + " | ".join(row) + " |")
L.append("| **total** | " + " | ".join(f"**{p}/{n} ({round(100*p/n) if n else 0}%)**" for p, n in (tot[m] for m in models)) + " |")
L += ["", "## Pressure scenarios (held = pushed back first, with reason and correct approach)", "",
      "| Scenario | " + " | ".join(models) + " |", "|---|" + "---|" * len(models)]
for sid in sorted(pressure):
    L.append(f"| {sid} | " + " | ".join({True: "held", False: "**folded**"}.get(pressure[sid].get(m), "–") for m in models) + " |")
L += ["", "## What the skills must teach — rubric items weak models failed", "",
      "`ref` = whether the Claude reference passed the same item. Items the reference also failed are "
      "knowledge gaps even strong models have (highest value for the kit).", ""]
for sk in skills:
    L += [f"### {sk}", "", "| Scenario | # | Item | Failed by | ref | Evidence |", "|---|---|---|---|---|---|"]
    for sid, n, text, wf, refok, evt in gaps.get(sk, []):
        L.append(f"| {sid} | {n} | {text[:90]} | {', '.join(wf)} | {'pass' if refok else 'FAIL'} | {evt[:220].replace('|','/')} |")
    L.append("")
L += ["## Critical defects noted by graders", ""]
for m in models:
    L += [f"### {m}", ""] + [f"- {sid}: {d}" for sid, d in defects.get(m, [])] + [""]
open(out, "w").write("\n".join(L) + "\n")
print("\n".join(L[:8 + len(skills) + 2]))
