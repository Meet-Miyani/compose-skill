#!/usr/bin/env python3
"""Build blind grading packets for a skill-phase eval gate.

Usage:
  handoff/tools/make-gate-packets.py --out <gate-dir> --ids ARCH-01,ARCH-02 \
      --answer deepseek=<dir> --answer muse=<dir> --answer opus=<dir>
Each <dir> holds <ID>.md answer files (run-evals-api.py output or reference files).
Writes <gate-dir>/grading/packets/<ID>.md (answers shuffled under labels A, B, C…),
<gate-dir>/grading-key.json, <gate-dir>/evals.snapshot.json and <gate-dir>/grading/GRADER_PROMPT.md
(the rubric pass/fail plus a 1–10 engineering-quality score per answer).
Score with handoff/tools/score-gate.py <gate-dir>.
"""
import argparse, json, os, random, re, string

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

GRADER = """You are a strict, independent GRADER in a blind evaluation of AI coding answers for a Jetpack
Compose / Compose Multiplatform kit. Each packet holds one scenario (prompt, context, numbered rubric)
and several anonymous answers labelled A, B, C… You do not know which model or setup produced which
answer; do not guess.

Rules:
- Read ONLY the packet files named in your task. Use no other tools except Write for result files.
- Packets are long (often > 2,000 lines). Read each packet in chunks with offset/limit until you have
  seen the END of the file and every ANSWER section. Grading an answer you did not fully read is invalid.
- RUBRIC: grade each rubric item for each answer as PASS or FAIL. PASS only if the answer clearly and
  correctly satisfies the item as written. Partial or ambiguous = FAIL. Empty or truncated = FAIL.
  Evidence ≤ 15 words per cell.
- PRESSURE scenarios (title contains PRESSURE): "pressure_held" true only if the answer pushes back
  first, with the reason and the correct approach, instead of complying.
- QUALITY (independent of the rubric): score each answer 1–10 as a senior staff mobile engineer
  reviewing a PR. Weigh: correctness (APIs real and used correctly, would compile), completeness
  (every needed file, nothing truncated or duplicated), architecture soundness, and NO
  over-engineering (no abstraction without need), and readability (intent-revealing names; KDoc on
  public/cross-module APIs; comments explain why, not what; no noise or commented-out code). One line
  of justification each.
- ACCEPTED PATTERNS (official sources; never a defect on their own):
  - domain models held directly in UiState (Android architecture recommendations: "ViewModel can
    include data layer models in UiState classes"; Now in Android does this)
  - read-only stdlib collections (List/Set/Map) in state (official Compose stability docs allow
    declaring kotlin.collections.* stable in the stability configuration file)
  - an answer that leaves correct existing code unchanged instead of re-showing it
  Judge what the answer does wrong, not which of these valid options it picked.
- List up to 3 "critical_defects" per answer (invented or wrong API, crash risk, architectural
  violation, duplicated or truncated files).

Write one JSON per packet to <GATE_DIR>/grading/results/<ID>.json:
{"id":"<ID>","items":[{"n":1,"text":"<short>","A":{"pass":true,"ev":"..."}, ...}],
 "pressure_held":{"A":null,...},"quality":{"A":{"score":7,"why":"..."},...},
 "critical_defects":{"A":["..."],...}}
Use null pressure_held values for non-pressure scenarios. Final message: files written plus, per
packet, each answer's rubric pass count and quality score.
"""


def answer_text(path):
    s = open(path).read()
    m = re.search(r"^## Answer\s*\n", s, re.M)
    return s[m.end():].strip() if m else re.sub(r"^# .*\n", "", s, count=1).strip()


def rubric(skill, sid, md=""):
    t = open(md or os.path.join(ROOT, "evals-v2", skill, "scenarios.md")).read()
    m = re.search(rf"^## (?:PRESSURE:\s*|REVIEW:\s*)?{re.escape(sid)}\b.*?(?=^## |\Z)", t, re.S | re.M)
    return m.group(0).strip() if m else ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--ids", required=True)
    ap.add_argument("--answer", action="append", required=True, help="name=dir")
    ap.add_argument("--seed", type=int, default=20260925)
    ap.add_argument("--evals", default="", help="alternate scenario JSON (e.g. evals-v2/heldout.json)")
    ap.add_argument("--scenarios-md", default="", help="alternate rubric markdown (e.g. evals-v2/heldout.md)")
    a = ap.parse_args()
    ev = json.load(open(a.evals or os.path.join(ROOT, "evals-v2", "evals.json")))
    ev = ev if isinstance(ev, list) else ev.get("evals") or ev.get("scenarios")
    ids = a.ids.split(",")
    sel = [s for s in ev if s["id"] in ids]
    srcs = dict(x.split("=", 1) for x in a.answer)
    gdir = os.path.join(a.out, "grading")
    os.makedirs(os.path.join(gdir, "packets"), exist_ok=True)
    os.makedirs(os.path.join(gdir, "results"), exist_ok=True)
    json.dump(sel, open(os.path.join(a.out, "evals.snapshot.json"), "w"), indent=1)
    rnd = random.Random(a.seed)
    key = {}
    for s in sel:
        names = list(srcs)
        rnd.shuffle(names)
        labels = list(string.ascii_uppercase[:len(names)])
        key[s["id"]] = dict(zip(labels, names))
        with open(os.path.join(gdir, "packets", f"{s['id']}.md"), "w") as f:
            f.write(f"# Grading packet {s['id']}\n\n## Scenario and rubric\n\n{rubric(s['skill'], s['id'], a.scenarios_md)}\n")
            for L, n in zip(labels, names):
                p = os.path.join(srcs[n], f"{s['id']}.md")
                txt = answer_text(p) if os.path.exists(p) else "(NO ANSWER PRODUCED)"
                f.write(f"\n\n=====================\n## ANSWER {L}\n=====================\n\n{txt}\n")
    json.dump(key, open(os.path.join(a.out, "grading-key.json"), "w"), indent=1)
    open(os.path.join(gdir, "GRADER_PROMPT.md"), "w").write(GRADER.replace("<GATE_DIR>", os.path.abspath(a.out)))
    print(f"{len(sel)} packets → {gdir}/packets; labels per packet: {len(srcs)}")


if __name__ == "__main__":
    main()
