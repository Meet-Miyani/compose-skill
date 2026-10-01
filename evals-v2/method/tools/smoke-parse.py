#!/usr/bin/env python3
"""Parse plan step 8 smoke runs (pre-registered in evals-v2/method/preregistration-v5.md).

For each run in evals-v2/method/work/smoke8/runs/<tool>-<task>/, list the kit files the agent opened, in order, from
the tool's own event log (Codex command_execution, Claude tool_use incl. the Skill tool, Antigravity step_update
tool parameters). Kit tokens = full size/4 of every distinct kit .md file opened: an upper bound on what reached
the model (partial reads count in full), so a pass under it is a pass under the pre-registered rule.
Usage: smoke-parse.py [run-dir ...]
"""
import glob, json, os, re, sys

W = os.path.join(os.path.dirname(__file__), "..", "work", "smoke8", "runs")
KEY = {"S1": "compose-feature/SKILL.md", "S2": "compose-feature/references/testing.md",
       "S3": "compose-feature/references/review-mode.md"}
PAT = re.compile(r"skills/(compose(?:-[a-z]+)?)/([A-Za-z0-9_./-]+?\.md)")

def call_texts(path):
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            e = json.loads(line)
        except ValueError:
            continue
        it = e.get("item") or {}
        if e.get("type") == "item.completed" and it.get("type") == "command_execution":
            yield it.get("command", "")
        msg = e.get("message") or {}
        if e.get("type") == "assistant" and isinstance(msg.get("content"), list):
            for c in msg["content"]:
                if c.get("type") == "tool_use":
                    inp = c.get("input") or {}
                    if c.get("name") == "Skill" and str(inp.get("skill", "")).startswith("compose"):
                        yield "skills/%s/SKILL.md" % inp["skill"].split(":")[-1]
                    yield json.dumps(inp)
        su = e.get("step_update") or {}
        if su.get("state") == "DONE" and su.get("tool_info"):
            yield json.dumps(su["tool_info"].get("parameters") or {})

def analyse(run):
    name = os.path.basename(run.rstrip("/"))
    task = name.split("-")[-1]
    log = os.path.join(run, "agent.jsonl")
    if not os.path.isfile(log):
        return name, None
    order = []
    for text in call_texts(log):
        for skill, rel in PAT.findall(text):
            f = "%s/%s" % (skill, rel)
            if f not in order:
                order.append(f)
    proj = os.path.join(run, "project")
    roots = [os.path.join(proj, ".claude", "skills"), os.path.join(proj, ".agents", "skills")]
    size = 0
    for f in order:
        for r in roots:
            p = os.path.join(r, f)
            if os.path.isfile(p):
                size += os.path.getsize(p)
                break
    tokens = size // 4
    act = bool(order) and order[0] == "compose/SKILL.md"
    route = KEY[task] in order
    ok = act and route and tokens <= 20000
    meta = open(os.path.join(run, "meta.txt")).read().strip() if os.path.isfile(os.path.join(run, "meta.txt")) else "running"
    return name, dict(act=act, route=route, tokens=tokens, ok=ok, files=order, meta=meta)

runs = sys.argv[1:] or sorted(glob.glob(os.path.join(W, "*-S[123]")))
for run in runs:
    name, r = analyse(run)
    if r is None:
        print(f"{name}: no log"); continue
    print(f"{name:10s} activation={'Y' if r['act'] else 'N'} routing={'Y' if r['route'] else 'N'} "
          f"kit_tokens={r['tokens']:6d} pass={'Y' if r['ok'] else 'N'}  ({r['meta']})")
    for f in r["files"]:
        print("    " + f)
