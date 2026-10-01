#!/usr/bin/env python3
"""v5 grading (pre-registered in handoff/reviews/m9.md, "Plan step 9").

  v5-grade.py packets          build blind packets: one per (task, answering vendor, grading vendor)
  v5-grade.py run [--only X]   run each packet through its grading vendor's CLI (skips finished ones)
  v5-grade.py score            both-graders-agree scores per model x arm, [eng]/[kit] split, per-grader too

Each packet holds the 6 answers of one vendor on one task (2 models x 3 arms), shuffled under letters A-F. It
contains the diff (kit files excluded), the final message and the check results. The key file maps letters to
(model, arm) and never enters a packet. The graders are the two vendors other than the answering vendor.
"""
import glob, json, os, random, re, subprocess, sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
REPO = os.path.dirname(REPO) if os.path.basename(REPO) == "handoff" else REPO
W = os.path.join(REPO, "handoff", "work", "scratch", "v5")
V5 = os.path.join(REPO, "evals-v2", "heldout-v5")
G = os.path.join(W, "grading")
VENDOR = {"sonnet": "claude", "opus": "claude", "gpt-6-luna": "gpt", "gpt-6-sol": "gpt",
          "gemini-3.8-flash-medium": "gemini", "gemini-3.1-pro-high": "gemini"}
ARMS = ["nokit", "generic", "kit"]
# answering panel: Gemini 3.1 Pro dropped by the owner on 2026-10-01 after 6/24 cells, before any Gemini grade
# (older generation than 3.8 Flash, so it did not fill the "stronger Gemini" slot). Its partial cells are reported
# separately and never enter packets or pass rules. It stays the pre-registered Gemini grader.
PANEL = ["sonnet", "opus", "gpt-6-luna", "gpt-6-sol", "gemini-3.8-flash-medium"]
CAP = 120_000  # chars per answer diff; longer diffs are cut with a visible marker

def tasks():
    t = open(os.path.join(V5, "tasks.md")).read()
    out = {}
    for m in re.finditer(r"^## (T\d)\b(.*?)(?=^## T\d|\Z)", t, re.S | re.M):
        body = m.group(2)
        prompt = re.search(r"^Prompt:\s*(.*?)(?=^\w[\w ]*:|\Z)", body, re.S | re.M)
        rub = re.search(r"^Rubric:\s*(.*)", body, re.S | re.M)
        items = re.findall(r"^\s*(\d+)\.\s+(.*?)\s*$", rub.group(1) if rub else "", re.M)
        out[m.group(1)] = {"prompt": prompt.group(1).strip() if prompt else "", "items": items}
    return out

def answer_text(run):
    def read(name, cap=None):
        p = os.path.join(run, name)
        if not os.path.isfile(p): return "(none)"
        s = open(p, errors="replace").read()
        return s if cap is None or len(s) <= cap else s[:cap] + f"\n[... cut at {cap} of {len(s)} chars ...]"
    meta = read("meta.txt")
    checks = read("checks.log")
    tail = "\n".join(checks.splitlines()[-40:]) if checks != "(none)" else checks
    text = (f"### Final message\n{read('final.md', 20_000)}\n\n### Diff (project changes)\n```diff\n"
            f"{read('answer.diff', CAP)}\n```\n\n### Checks\n{meta}\n```\n{tail}\n```\n")
    # blinding: names that reveal an instruction file or the kit's install folders become neutral text
    return re.sub(r"\b(CLAUDE|AGENTS|GEMINI)\.md\b|\.(claude|agents)/skills\S*", "[project instructions]", text)

def packets():
    ts = tasks(); os.makedirs(G, exist_ok=True); rng = random.Random(20260930)
    for tid, t in ts.items():
        for vendor in ("claude", "gpt", "gemini"):
            runs = [(m, a) for m in PANEL if VENDOR[m] == vendor for a in ARMS
                    if os.path.isfile(os.path.join(W, "runs", m, f"{tid}-{a}", "meta.txt"))]
            need = 3 * sum(1 for m in PANEL if VENDOR[m] == vendor)
            if len(runs) < need: continue  # build a packet only when every panel model x 3 arms is done
            rng.shuffle(runs)
            key = {chr(65 + i): {"model": m, "arm": a} for i, (m, a) in enumerate(runs)}
            items = "\n".join(f"{n}. {txt}" for n, txt in t["items"])
            body = [f"# Grading packet {tid}\n\nTask given to each agent:\n> {t['prompt']}\n\nRubric:\n{items}\n"]
            for L, (m, a) in zip(key, runs):
                body.append(f"\n## Answer {L}\n" + answer_text(os.path.join(W, "runs", m, f"{tid}-{a}")))
            for grader in {"claude", "gpt", "gemini"} - {vendor}:
                d = os.path.join(G, f"{tid}-{vendor}-by-{grader}")
                if os.path.isfile(os.path.join(d, "grades.json")): continue  # never rebuild a graded packet
                os.makedirs(d, exist_ok=True)
                open(os.path.join(d, "packet.md"), "w").write("".join(body))
                json.dump(key, open(os.path.join(d, "key.json"), "w"), indent=1)
    print("packets:", len(glob.glob(os.path.join(G, "*", "packet.md"))))

INSTR = ("You are a strict, fair grader. Read packet.md in this folder. For every answer (A, B, ...) and every rubric "
         "item, decide pass or fail using only the evidence in the packet: the diff, the final message and the check "
         "results. A claim in the message that the diff does not support is a fail. Do not guess which setup produced "
         "an answer, and do not reward length or style. Write grades.json in this folder: "
         '{"A": {"1": {"pass": true, "why": "<one line>"}, ...}, ...}, covering every answer and every item. '
         "Write nothing else and do not modify packet.md.")

def run(only=None):
    for d in sorted(glob.glob(os.path.join(G, "*"))):
        if only and only not in os.path.basename(d): continue
        if os.path.isfile(os.path.join(d, "grades.json")): continue
        grader = os.path.basename(d).split("-by-")[1]
        cmd = {"claude": ["claude", "-p", INSTR, "--model", "opus", "--setting-sources", "project,local",
                          "--dangerously-skip-permissions"],
               "gpt": ["codex", "exec", "--disable", "memories", "-m", "gpt-6-sol", "-s", "workspace-write",
                       "--skip-git-repo-check", "-C", d, INSTR],
               "gemini": ["agy", "--print", INSTR, "--model", "gemini-3.1-pro-high",
                          "--dangerously-skip-permissions", "--print-timeout", "45m"]}[grader]
        print("grading", os.path.basename(d), flush=True)
        with open(os.path.join(d, "grader.log"), "w") as log:
            subprocess.run(cmd, cwd=d, stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT)
        print("  ->", "ok" if os.path.isfile(os.path.join(d, "grades.json")) else "MISSING grades.json", flush=True)

def score():
    ts = tasks(); tag = {tid: {n: ("kit" if "[kit]" in txt else "eng") for n, txt in t["items"]} for tid, t in ts.items()}
    agree, per = {}, {}
    for d in sorted(glob.glob(os.path.join(G, "*"))):
        tid, rest = os.path.basename(d).split("-", 1); vendor, grader = rest.split("-by-")
        gp = os.path.join(d, "grades.json")
        if not os.path.isfile(gp): print("missing", d); continue
        grades, key = json.load(open(gp)), json.load(open(os.path.join(d, "key.json")))
        for L, who in key.items():
            for n in tag[tid]:
                ok = bool(((grades.get(L) or {}).get(n) or {}).get("pass"))
                cell = (who["model"], who["arm"], tag[tid][n])
                per.setdefault((grader,) + cell, []).append(ok)
                agree.setdefault((tid, L, vendor, n) + cell, []).append(ok)
    tot = {}
    for k, v in agree.items():
        cell = k[4:]; tot.setdefault(cell, []).append(len(v) == 2 and all(v))
    def pct(xs): return f"{100 * sum(xs) / len(xs):5.1f} ({sum(xs)}/{len(xs)})" if xs else "   -"
    print("both graders agree (item passes only if both pass)")
    print(f"{'model':26s} {'arm':8s} {'all':>14s} {'[eng]':>14s} {'[kit]':>14s}")
    for m in PANEL:
        for a in ARMS:
            e, k = tot.get((m, a, "eng"), []), tot.get((m, a, "kit"), [])
            if e or k: print(f"{m:26s} {a:8s} {pct(e + k):>14s} {pct(e):>14s} {pct(k):>14s}")
    print("\nper grader, all items")
    for (g, m, a, _t), v in sorted(per.items()):
        if _t == "eng": print(f"  {g:7s} {m:26s} {a:8s} eng {pct(v)}")

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "score"
    {"packets": packets, "score": score}.get(cmd, lambda: run(sys.argv[3] if "--only" in sys.argv else None))()
