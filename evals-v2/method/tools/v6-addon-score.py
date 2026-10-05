#!/usr/bin/env python3
"""v6 add-on scoring (DeepSeek V4.1 Flash, DeepSeek V4 Pro; preregistration-v6.md, add-on scope 2026-10-05).

Reads only frozen grades in evals-v2/results-v6/grades/ (the *-deepseek-by-* packets). Graders: Claude + GPT; an item
passes only when both pass it. Reported separately from the 5-model panel; never changes the v6.1 release decision.
Kit tokens and the hidden-test sensitivity check are in ADDONS.md.
Usage: v6-addon-score.py [repo]
"""
import glob, json, os, re, sys

REPO = sys.argv[1] if len(sys.argv) > 1 else os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
F = os.path.join(REPO, "evals-v2", "results-v6", "grades")
ARMS = ["nokit", "kit60", "kit61"]
MODELS = {"opencode-go_deepseek-v4.1-flash": "DeepSeek V4.1 Flash", "opencode-go_deepseek-v4-pro": "DeepSeek V4 Pro"}
GRADERS = ["claude", "gpt"]
CONFORM = {"T1": ["1", "2", "3", "4"], "T2": ["1", "2", "3", "4"]}
FINE = {"T3": ["3", "4"], "T4": ["4", "5"]}

t = open(os.path.join(REPO, "evals-v2", "heldout-v6", "tasks.md")).read()
TAG = {}
for m in re.finditer(r"^## (T\d)\b(.*?)(?=^## T\d|\Z)", t, re.S | re.M):
    rub = m.group(2).split("Rubric:", 1)[1]
    TAG[m.group(1)] = {n: ("kit" if "[kit]" in x else "eng") for n, x in re.findall(r"^\s*(\d+)\.\s+(.*?)\s*$", rub, re.M)}

votes = {}
for d in glob.glob(os.path.join(F, "T*-deepseek-by-*")):
    tid, rest = os.path.basename(d).split("-", 1); _, grader = rest.split("-by-")
    g, key = json.load(open(os.path.join(d, "grades.json"))), json.load(open(os.path.join(d, "key.json")))
    for L, who in key.items():
        for n in TAG[tid]:
            votes.setdefault((tid, who["model"], who["arm"], n), {})[grader] = bool(((g.get(L) or {}).get(n) or {}).get("pass"))

def ok(tid, m, a, n, g=None):
    v = votes.get((tid, m, a, n), {})
    return v.get(g, False) if g else (len(v) == 2 and all(v.values()))

def complete(tid, m):
    return all(len(votes.get((tid, m, a, n), {})) == 2 for a in ARMS for n in TAG[tid])

N = sum(len(v) for v in TAG.values())
print("v6 add-ons (DeepSeek), both graders (Claude + GPT) agree; items passed of", N, "\n")
print(f"{'model':20s} {'nokit':>7s} {'kit60':>7s} {'kit61':>7s}  kit61-kit60  kit61-nokit  tasks")
tot = {}
for m, name in MODELS.items():
    tasks = [x for x in sorted(TAG) if complete(x, m)]
    tot[m] = {a: sum(ok(x, m, a, i) for x in tasks for i in TAG[x]) for a in ARMS}
    print(f"{name:20s} " + " ".join(f"{tot[m][a]:3d} ({100 * tot[m][a] / N:4.1f}%)"[:7] for a in ARMS)
          + f"  {tot[m]['kit61'] - tot[m]['kit60']:+11d}  {tot[m]['kit61'] - tot[m]['nokit']:+11d}  {','.join(tasks)}")
print("\npercent:", {MODELS[m]: {a: round(100 * tot[m][a] / N, 1) for a in ARMS} for m in MODELS})
c = {a: sum(ok(x, m, a, i) for m in MODELS for x in CONFORM for i in CONFORM[x]) for a in ARMS}
f = {a: sum(not ok(x, m, a, i) for m in MODELS for x in FINE for i in FINE[x]) for a in ARMS}
print(f"Conform [eng] passed (both models, max 16): nokit {c['nokit']}  kit60 {c['kit60']}  kit61 {c['kit61']}")
print(f"Review 'fine' items called blocking (max 8): nokit {f['nokit']}  kit60 {f['kit60']}  kit61 {f['kit61']}")
print("\nPer task (nokit / kit60 / kit61):")
for m, name in MODELS.items():
    print(f"  {name:20s} " + "   ".join(f"{x} " + "/".join(str(sum(ok(x, m, a, i) for i in TAG[x])) for a in ARMS)
                                     + f" of {len(TAG[x])}" for x in sorted(TAG) if complete(x, m)))
print("\n[eng] / [kit] (nokit / kit60 / kit61):")
for m, name in MODELS.items():
    s = {k: "/".join(str(sum(ok(x, m, a, i) for x in TAG for i in TAG[x] if TAG[x][i] == k)) for a in ARMS) for k in ("eng", "kit")}
    print(f"  {name:20s} eng {s['eng']:12s} kit {s['kit']}")
print("\nPer grader (nokit / kit60 / kit61) and agreement:")
for m, name in MODELS.items():
    keys = [(x, m, a, i) for x in TAG for a in ARMS for i in TAG[x]]
    agree = sum(len(set(votes[k].values())) == 1 for k in keys if len(votes.get(k, {})) == 2)
    print(f"  {name:20s} " + "   ".join(f"{g} " + "/".join(str(sum(ok(x, m, a, i, g) for x in TAG for i in TAG[x])) for a in ARMS) for g in GRADERS)
          + f"   agree {agree}/{len(keys)}")

