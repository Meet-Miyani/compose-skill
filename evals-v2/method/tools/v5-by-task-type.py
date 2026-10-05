#!/usr/bin/env python3
"""v5 results by task type (README table): both-graders-agree, the five panel models together.

Reads only the frozen grades in results-v5/grades/ and heldout-v5/tasks.md, with the same agreement rule as
v5-grade.py score. Usage: python3 evals-v2/method/tools/v5-by-task-type.py
"""
import glob, json, os, re

E = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
t = open(f"{E}/heldout-v5/tasks.md").read()
tag = {}
for m in re.finditer(r"^## (T\d)\b(.*?)(?=^## T\d|\Z)", t, re.S | re.M):
    rub = re.search(r"^Rubric:\s*(.*)", m.group(2), re.S | re.M).group(1)
    tag[m.group(1)] = {n: ("kit" if "[kit]" in x else "eng") for n, x in re.findall(r"^\s*(\d+)\.\s+(.*?)\s*$", rub, re.M)}
agree = {}
for d in glob.glob(f"{E}/results-v5/grades/T*-by-*"):
    tid = os.path.basename(d).split("-", 1)[0]
    g, key = json.load(open(f"{d}/grades.json")), json.load(open(f"{d}/key.json"))
    for L, w in key.items():
        for n in tag[tid]:
            agree.setdefault((tid, n, w["model"], w["arm"]), []).append(bool(((g.get(L) or {}).get(n) or {}).get("pass")))
PANEL = ["sonnet", "opus", "gpt-6-luna", "gpt-6-sol", "gemini-3.8-flash-medium"]
TYPES = {"New features (T1-T3)": ["T1", "T2", "T3"], "Bug fixes (T4-T5)": ["T4", "T5"],
         "Reviews (T6-T7)": ["T6", "T7"], "Conform (T8)": ["T8"]}
print(f"{'task type':22s} {'no kit':>14s} {'generic':>14s} {'kit':>14s}")
for ty, ts in TYPES.items():
    cells = []
    for arm in ["nokit", "generic", "kit"]:
        xs = [len(v) == 2 and all(v) for (tid, n, m, a), v in agree.items() if tid in ts and m in PANEL and a == arm]
        cells.append(f"{100 * sum(xs) / len(xs):5.1f}% ({sum(xs)}/{len(xs)})")
    print(f"{ty:22s} " + " ".join(f"{c:>14s}" for c in cells))
