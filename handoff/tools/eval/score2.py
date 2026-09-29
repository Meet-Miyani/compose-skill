#!/usr/bin/env python3
"""Two-pass held-out scoring: rubric %, [eng]/[kit] split, quality, pressure, grader agreement.
Usage: score2.py <rubric.md> <gate-a> <gate-b>"""
import json, os, re, sys, collections

md, ga, gb = sys.argv[1:4]
tags = {}
cur = None
for line in open(md):
    m = re.match(r"^## (?:PRESSURE:\s*|REVIEW:\s*)?(H\d-\d+)", line)
    if m:
        cur = m.group(1)
    m = re.match(r"^(\d+)\. .*\[(eng|kit)\]\s*$", line.rstrip())
    if cur and m:
        tags[(cur, int(m.group(1)))] = m.group(2)


def load(g):
    key = json.load(open(os.path.join(g, "grading-key.json")))
    out = {}
    for sid, lab in key.items():
        p = os.path.join(g, "grading", "results", f"{sid}.json")
        if not os.path.exists(p):
            print("MISSING", g, sid)
            continue
        out[sid] = (lab, json.load(open(p)))
    return out


passes = [load(ga), load(gb)]
stat = collections.defaultdict(lambda: collections.defaultdict(lambda: [0, 0]))
qual = collections.defaultdict(list)
press = collections.defaultdict(list)
verdict = [{}, {}]
for i, P in enumerate(passes):
    for sid, (lab, r) in P.items():
        for it in r["items"]:
            n = int(it["n"]); t = tags.get((sid, n), "?")
            for L, name in lab.items():
                ok = bool((it.get(L) or {}).get("pass"))
                verdict[i][(sid, n, name)] = ok
                for k in ("all", t):
                    stat[name][k][0] += ok; stat[name][k][1] += 1
        for L, name in lab.items():
            q = (r.get("quality") or {}).get(L) or {}
            if q.get("score") is not None:
                qual[name].append(float(q["score"]))
            h = (r.get("pressure_held") or {}).get(L)
            if h is not None:
                press[name].append(bool(h))
pct = lambda v: f"{100 * v[0] / v[1]:.0f}%" if v[1] else "-"
print(f"{'answer':12} {'rubric':>7} {'quality':>8} {'[eng]':>6} {'[kit]':>6} pressure(held/graded, both passes)")
for name in sorted(stat):
    s = stat[name]
    q = sum(qual[name]) / len(qual[name]) if qual[name] else 0
    print(f"{name:12} {pct(s['all']):>7} {q:8.2f} {pct(s['eng']):>6} {pct(s['kit']):>6} {sum(press[name])}/{len(press[name])}")
common = set(verdict[0]) & set(verdict[1])
agree = sum(verdict[0][k] == verdict[1][k] for k in common)
print(f"agreement {agree}/{len(common)} = {100 * agree / max(1, len(common)):.0f}%; untagged items: {sum(1 for k in common if tags.get(k[:2]) is None)}")
