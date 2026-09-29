#!/usr/bin/env python3
"""Apply tie-break rulings to two grading passes without touching the originals.

For each model, copies g-<m>-h4-{a,b} to g-<m>-h4-{a,b}-adj (key, snapshot, results) and replaces the split
verdicts with the ruling. Rulings name pass-A labels; the arm is found through pass A's key and mapped to the
matching label in pass B.
Usage: adjudicate.py <m9-dir> <rulings.json> [<rulings.json> ...]
Then score: score2.py evals-v2/heldout-v4.md <m9>/g-<m>-h4-a-adj <m9>/g-<m>-h4-b-adj
"""
import json, os, shutil, sys

m9, files = sys.argv[1], sys.argv[2:]
entries = [e for f in files for e in json.load(open(f))]
done = set()
for e in entries:
    m, sid = e["model"], e["id"]
    src = {p: os.path.join(m9, f"g-{m}-h4-{p}") for p in "ab"}
    dst = {p: src[p] + "-adj" for p in "ab"}
    if m not in done:
        for p in "ab":
            if os.path.isdir(dst[p]):
                shutil.rmtree(dst[p])
            shutil.copytree(src[p], dst[p], ignore=shutil.ignore_patterns("packets", "xgrade-sol", "quarantine-*"))
        done.add(m)
    keys = {p: json.load(open(os.path.join(src[p], "grading-key.json")))[sid] for p in "ab"}
    b_label = {arm: lab for lab, arm in keys["b"].items()}
    res = {p: json.load(open(os.path.join(dst[p], "grading", "results", f"{sid}.json"))) for p in "ab"}
    for r in e.get("rulings", []):
        arm = keys["a"][r["label"]]
        for p, lab in (("a", r["label"]), ("b", b_label[arm])):
            for it in res[p]["items"]:
                if it["n"] == r["n"]:
                    it[lab] = {"pass": bool(r["pass"]), "ev": "ADJ: " + r.get("ev", "")}
    for lab, val in (e.get("pressure") or {}).items():
        arm = keys["a"][lab]
        res["a"]["pressure_held"][lab] = bool(val)
        res["b"]["pressure_held"][b_label[arm]] = bool(val)
    for p in "ab":
        json.dump(res[p], open(os.path.join(dst[p], "grading", "results", f"{sid}.json"), "w"), indent=1)
print("adjudicated:", ", ".join(sorted(done)))
