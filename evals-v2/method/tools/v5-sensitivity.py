import glob, json, os, re, sys
"""v5 erratum sensitivity: both-graders-agree scores with flawed rubric items left out (see VERDICT.md, Erratum).

Reads only the frozen grades in results-v5/grades/ and heldout-v5/tasks.md, with the same agreement rule as
v5-grade.py score. Usage: python3 evals-v2/method/tools/v5-sensitivity.py
"""
E = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
t = open(f"{E}/heldout-v5/tasks.md").read()
tag = {}
for m in re.finditer(r"^## (T\d)\b(.*?)(?=^## T\d|\Z)", t, re.S | re.M):
    rub = re.search(r"^Rubric:\s*(.*)", m.group(2), re.S | re.M)
    tag[m.group(1)] = {n: ("kit" if "[kit]" in x else "eng") for n, x in re.findall(r"^\s*(\d+)\.\s+(.*?)\s*$", rub.group(1), re.M)}
agree = {}
for d in sorted(glob.glob(f"{E}/results-v5/grades/T*-by-*")):
    tid, rest = os.path.basename(d).split("-", 1); vendor, grader = rest.split("-by-")
    g, key = json.load(open(f"{d}/grades.json")), json.load(open(f"{d}/key.json"))
    for L, who in key.items():
        for n in tag[tid]:
            ok = bool(((g.get(L) or {}).get(n) or {}).get("pass"))
            agree.setdefault((tid, n, who["model"], who["arm"]), []).append(ok)
PANEL = ["sonnet", "opus", "gpt-6-luna", "gpt-6-sol", "gemini-3.8-flash-medium", "opencode_muse-spark-1.3-contributor-free"]
def run(name, excl):
    print(f"\n== {name}")
    print(f"{'model':12s} {'nokit':>6s} {'kit':>6s} {'lift':>6s} {'eng nk':>7s} {'eng kit':>7s} {'eng d':>6s}  rule1 rule2 claim8")
    for m in PANEL:
        r = {}
        for a in ["nokit", "kit"]:
            for ty in ["all", "eng"]:
                xs = [len(v) == 2 and all(v) for (tid, n, mm, aa), v in agree.items()
                      if mm == m and aa == a and (tid, n) not in excl and tid not in excl and (ty == "all" or tag[tid][n] == "eng")]
                r[a, ty] = 100 * sum(xs) / len(xs)
        lift = r["kit", "all"] - r["nokit", "all"]; de = r["kit", "eng"] - r["nokit", "eng"]
        print(f"{m[:12]:12s} {r['nokit','all']:6.1f} {r['kit','all']:6.1f} {lift:+6.1f} {r['nokit','eng']:7.1f} {r['kit','eng']:7.1f} {de:+6.1f}  {'ok' if lift > 0 else 'FAIL':5s} {'ok' if de >= -5 else 'FAIL':5s} {'yes' if lift >= 8 else 'no'}")
run("as published", set())
run("without T6 item 3", {("T6", "3")})
run("without T6 and T7 (labelled review tasks)", {"T6", "T7"})
run("without T6, T7 and T8", {"T6", "T7", "T8"})
# items passed per arm on the review tasks (panel models, both graders agree)
print()
for tid in ["T6", "T7"]:
    for n in tag[tid]:
        row = {a: sum(len(v) == 2 and all(v) for (t2, n2, mm, aa), v in agree.items() if t2 == tid and n2 == n and aa == a and mm in PANEL[:5]) for a in ["nokit", "generic", "kit"]}
        print(tid, n, tag[tid][n], row)
