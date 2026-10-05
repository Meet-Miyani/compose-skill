#!/usr/bin/env python3
"""v6 A/B VERDICT scoring (pre-registered in evals-v2/method/preregistration-v6.md, Amendments 1-3).

Reads only the frozen grades in evals-v2/results-v6/grades/. An item passes only when BOTH of the model's graders
pass it (the two vendors other than the answering vendor; Muse: Claude + GPT). Applies:
  rule 1  every panel model: kit61 total >= kit60 total - 2 items
  rule 2  conform [eng] items (T1, T2 items 1-4) summed over models: kit61 > kit60; and no new build/test failure in
          kit61 on a task where kit60 had none
  rule 3  review "fine" items (T3 3-4, T4 4-5) failed, i.e. called blocking, summed: kit61 <= kit60
  rule 4  reported only: kit tokens per kit-arm run (upper bound; the table is published in kit-tokens.txt)
  Amendment 3: a model without every task graded by both graders is reported incomplete and left out of rules 1-3;
          stable = rules 1-3 hold and no model's kit61 total is below its nokit total.
Usage: v6-verdict.py [repo]
"""
import glob, json, os, re, sys

REPO = sys.argv[1] if len(sys.argv) > 1 else os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
F = os.path.join(REPO, "evals-v2", "results-v6", "grades")
META = os.path.join(REPO, "evals-v2", "results-v6", "run-meta.txt")  # post-run check status of every cell
ARMS = ["nokit", "kit60", "kit61"]
GRADERS = {"claude-sonnet-5-5": ["gpt", "gemini"], "gpt-6-luna": ["claude", "gemini"], "gpt-6-sol": ["claude", "gemini"],
           "gemini-3.8-flash-medium": ["claude", "gpt"], "opencode_muse-spark-1.3-contributor-free": ["claude", "gpt"]}
SHORT = {"claude-sonnet-5-5": "Sonnet 5.5", "gpt-6-luna": "GPT-6-Luna", "gpt-6-sol": "GPT-6-Sol",
         "gemini-3.8-flash-medium": "Gemini 3.8 Flash", "opencode_muse-spark-1.3-contributor-free": "Muse Spark 1.3"}
CONFORM = {"T1": ["1", "2", "3", "4"], "T2": ["1", "2", "3", "4"]}
FINE = {"T3": ["3", "4"], "T4": ["4", "5"]}
NEWFEAT = ["T5", "T6"]

t = open(os.path.join(REPO, "evals-v2", "heldout-v6", "tasks.md")).read()
TAG = {}
for m in re.finditer(r"^## (T\d)\b(.*?)(?=^## T\d|\Z)", t, re.S | re.M):
    rub = m.group(2).split("Rubric:", 1)[1]
    TAG[m.group(1)] = {n: ("kit" if "[kit]" in x else "eng") for n, x in re.findall(r"^\s*(\d+)\.\s+(.*?)\s*$", rub, re.M)}

votes = {}  # (task, model, arm, item) -> {grader: pass}
for d in glob.glob(os.path.join(F, "T*-by-*")):
    tid, rest = os.path.basename(d).split("-", 1); vendor, grader = rest.split("-by-")
    g, key = json.load(open(os.path.join(d, "grades.json"))), json.load(open(os.path.join(d, "key.json")))
    for L, who in key.items():
        m = who["model"]
        if grader not in GRADERS.get(m, []): continue
        for n in TAG[tid]:
            votes.setdefault((tid, m, who["arm"], n), {})[grader] = bool(((g.get(L) or {}).get(n) or {}).get("pass"))

def ok(tid, m, a, n, g=None):
    v = votes.get((tid, m, a, n), {})
    if g: return v.get(g, False)
    return len(v) == 2 and all(v.values())

def complete(tid, m):
    return all(len(votes.get((tid, m, a, n), {})) == 2 for a in ARMS for n in TAG[tid])

# run-meta.txt lines: "<model>/<task>-<arm>/<meta file>: <contents>"; a moderator re-check (meta-final.txt) wins
RM = {}
for line in open(META):
    name, _, body = line.rstrip("\n").partition(": ")
    if name.endswith("/meta.txt"): RM.setdefault(name[:-len("/meta.txt")], body)
    elif name.endswith("/meta-final.txt"): RM[name[:-len("/meta-final.txt")]] = body

def checks_ok(m, tid, a):
    s = RM.get(f"{m}/{tid}-{a}")
    if s is None: return None
    return "checks=none" in s or re.search(r"checks_exit=0\b", s) is not None

N = sum(len(v) for v in TAG.values())
full = [m for m in SHORT if all(complete(tid, m) for tid in TAG)]
incomplete = [m for m in SHORT if m not in full]
print("v6 A/B VERDICT scoring: an item passes only if both graders pass it\n")
print(f"{'model':18s} {'graders':13s} {'nokit':>7s} {'kit60':>7s} {'kit61':>7s}  rule1 (kit61 >= kit60-2)  kit61 vs nokit")
tot = {}
for m in SHORT:
    tasks = [tid for tid in sorted(TAG) if complete(tid, m)]
    n = sum(len(TAG[tid]) for tid in tasks)
    tot[m] = {a: sum(ok(tid, m, a, i) for tid in tasks for i in TAG[tid]) for a in ARMS}
    r1 = "ok" if tot[m]["kit61"] >= tot[m]["kit60"] - 2 else "FAIL"
    note = "" if m in full else f"  INCOMPLETE ({','.join(tasks)} only; Amendment 3: not in rules 1-3)"
    print(f"{SHORT[m]:18s} {'+'.join(GRADERS[m]):13s} " + " ".join(f"{tot[m][a]:3d}/{n:<3d}" for a in ARMS)
          + f"  {r1:4s} ({tot[m]['kit61'] - tot[m]['kit60']:+d})              {tot[m]['kit61'] - tot[m]['nokit']:+d}{note}")

rule1 = all(tot[m]["kit61"] >= tot[m]["kit60"] - 2 for m in full)
r2 = {a: sum(ok(tid, m, a, i) for m in full for tid in CONFORM for i in CONFORM[tid]) for a in ARMS}
newfail = [f"{SHORT[m]} {tid}" for m in full for tid in TAG if checks_ok(m, tid, "kit60") and checks_ok(m, tid, "kit61") is False]
rule2 = r2["kit61"] > r2["kit60"] and not newfail
r3 = {a: sum(not ok(tid, m, a, i) for m in full for tid in FINE for i in FINE[tid]) for a in ARMS}
rule3 = r3["kit61"] <= r3["kit60"]
below = [SHORT[m] for m in full if tot[m]["kit61"] < tot[m]["nokit"]]
print(f"\nRule 1 (every complete model kit61 >= kit60 - 2): {'HOLDS' if rule1 else 'FAILS'}")
print(f"Rule 2 (conform [eng] passed, {len(full)} models; max {8 * len(full)}): nokit {r2['nokit']}  kit60 {r2['kit60']}  "
      f"kit61 {r2['kit61']}; new kit61 build/test failures: {', '.join(newfail) or 'none'} -> {'HOLDS' if rule2 else 'FAILS'}")
print(f"Rule 3 ('fine' items called blocking; max {4 * len(full)}): nokit {r3['nokit']}  kit60 {r3['kit60']}  "
      f"kit61 {r3['kit61']} -> {'HOLDS' if rule3 else 'FAILS'}")
print(f"Amendment 3 stable criterion (no complete model's kit61 below its nokit): "
      + ("HOLDS" if not below else "FAILS: " + ", ".join(below)))
print("Incomplete models: " + (", ".join(SHORT[m] for m in incomplete) or "none"))
outcome = ("v6.1.0 STABLE (Latest)" if rule1 and rule2 and rule3 and not below else
           "v6.1.0-preview.2" if rule1 and rule2 and rule3 else "no release; v6.0 stays current")
print(f"OUTCOME: {outcome}")

print("\nPer task (both graders; items passed nokit / kit60 / kit61):")
for m in SHORT:
    print(f"  {SHORT[m]:18s} " + "   ".join(f"{tid} " + "/".join(str(sum(ok(tid, m, a, i) for i in TAG[tid])) for a in ARMS)
                                         + f" of {len(TAG[tid])}" for tid in sorted(TAG) if complete(tid, m)))
print("\n[eng] vs [kit] items (both graders; nokit / kit60 / kit61):")
for m in SHORT:
    tasks = [tid for tid in sorted(TAG) if complete(tid, m)]
    s = {k: "/".join(str(sum(ok(tid, m, a, i) for tid in tasks for i in TAG[tid] if TAG[tid][i] == k)) for a in ARMS) for k in ("eng", "kit")}
    print(f"  {SHORT[m]:18s} eng {s['eng']:12s} kit {s['kit']}")
print("\nPer grader, all items (nokit / kit60 / kit61), and grader agreement:")
for m in SHORT:
    tasks = [tid for tid in sorted(TAG) if complete(tid, m)]
    parts = []
    for g in GRADERS[m]:
        parts.append(f"{g} " + "/".join(str(sum(ok(tid, m, a, i, g) for tid in tasks for i in TAG[tid])) for a in ARMS))
    keys = [(tid, m, a, i) for tid in tasks for a in ARMS for i in TAG[tid]]
    agree = sum(len(set(votes[k].values())) == 1 for k in keys if len(votes.get(k, {})) == 2)
    print(f"  {SHORT[m]:18s} " + "   ".join(parts) + f"   agree {agree}/{len(keys)}")

print("\nRule 4 (reported, not scored): kit tokens per kit-arm run (upper bound; 20k design budget)")
print("  see evals-v2/results-v6/kit-tokens.txt (all kit-arm cells, T1-T6)")
