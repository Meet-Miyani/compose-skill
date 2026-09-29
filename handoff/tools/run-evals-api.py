#!/usr/bin/env python3
"""Moderator eval runner — direct model API (OpenCode Go), no agent harness.

Why not `opencode run`: moderator-diagnosed 2026-09-24 — parallel runs hit "database is locked"
on the shared session DB, session creation stalls intermittently, and one run resolved to this
repo (loading its permissive config and reading the handoff files). Direct API calls have no
filesystem, no tools, no global skills: the model sees exactly what we send.

Modes
  --skill-mode none    baseline (M2): scenario only
  --skill-mode skill   the entry skill's SKILL.md + the target skill's SKILL.md in the system prompt
  --skill-mode full    as `skill` + every references/*.md and examples.md of the target skill
  --triggers           routing test: the model sees the six descriptions + a query and must name
                       the skill(s) to load; scored against evals-v2/triggers.json

Auth: the opencode-go key from ~/.local/share/opencode/auth.json (never printed).
API style per model comes from ~/.cache/opencode/models.json (openai → /responses,
anthropic → /messages, otherwise /chat/completions).

Usage
  handoff/tools/run-evals-api.py --model deepseek-v4.1-flash --out DIR [--skill-mode none] [--only ID,..] [--jobs 6]
  handoff/tools/run-evals-api.py --model muse-spark-1.3-contributor --out DIR --triggers
"""
import argparse, json, os, re, sys, time, uuid, urllib.request, urllib.error
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BASE = "https://opencode.ai/zen/go/v1"
ENTRY = "compose-architecture"

SYSTEM_BASE = (
    "You are a coding agent working in a Kotlin Jetpack Compose / Compose Multiplatform project.\n"
    "There is no project on disk for this task: treat the project context as the real project.\n"
    "Answer completely in one response. Do exactly what the task asks: if it asks for a decision, a\n"
    "plan, routing or a review, give that; write code only when the task asks for an implementation,\n"
    "and then give every file you create or change in full (markdown code blocks with file paths).\n"
    "Do not ask clarifying questions.\n"
)


def key():
    return json.load(open(os.path.expanduser("~/.local/share/opencode/auth.json")))["opencode-go"]["key"]


def style(model):
    try:
        m = json.load(open(os.path.expanduser("~/.cache/opencode/models.json")))["opencode-go"]["models"][model]
        npm = (m.get("provider") or {}).get("npm", "")
    except Exception:
        npm = ""
    return "responses" if npm == "@ai-sdk/openai" else "messages" if npm == "@ai-sdk/anthropic" else "chat"


def call(model, system, user, max_out, retries=4):
    st, k = style(model), key()
    h = {"Content-Type": "application/json", "User-Agent": "opencode/1.18.31",
         "x-opencode-session": "ses_eval_" + uuid.uuid4().hex[:20]}
    if st == "responses":
        path, h["Authorization"] = "/responses", "Bearer " + k
        body = {"model": model, "instructions": system, "input": user, "max_output_tokens": max_out}
    elif st == "messages":
        path, h["x-api-key"], h["anthropic-version"] = "/messages", k, "2023-06-01"
        body = {"model": model, "system": system, "max_tokens": max_out, "messages": [{"role": "user", "content": user}]}
    else:
        path, h["Authorization"] = "/chat/completions", "Bearer " + k
        body = {"model": model, "max_tokens": max_out,
                "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}]}
    last = ""
    for i in range(retries + 1):
        try:
            req = urllib.request.Request(BASE + path, data=json.dumps(body).encode(), headers=h)
            r = json.load(urllib.request.urlopen(req, timeout=900))
            if st == "responses":
                text = "".join(c.get("text", "") for o in r.get("output", []) for c in (o.get("content") or [])
                               if c.get("type") == "output_text")
                usage = r.get("usage", {})
            elif st == "messages":
                text = "".join(c.get("text", "") for c in r.get("content", []) if c.get("type") == "text")
                usage = r.get("usage", {})
            else:
                ch = r["choices"][0]
                text = ch["message"].get("content") or ""
                usage = dict(r.get("usage", {}), finish_reason=ch.get("finish_reason"))
            if not text:
                return "", usage, f"empty answer (usage={json.dumps(usage)[:200]})"
            return text, usage, None
        except urllib.error.HTTPError as e:
            last = f"HTTP {e.code}: {e.read()[:200]!r}"
            if e.code not in (429, 500, 502, 503, 504):
                break
        except Exception as e:  # timeouts, resets
            last = repr(e)
        time.sleep(min(60, 5 * 2 ** i))
    return "", {}, last


def read(path):
    return open(path).read() if os.path.isfile(path) else ""


def skill_text(skill, mode):
    if mode == "none":
        return ""
    parts = []
    for s in [ENTRY] + ([skill] if skill != ENTRY else []):
        d = os.path.join(ROOT, "skills-v2", s)
        body = read(os.path.join(d, "SKILL.md"))
        if body:
            parts.append(f"<skill name=\"{s}\" file=\"SKILL.md\">\n{body}\n</skill>")
    if mode == "full":
        d = os.path.join(ROOT, "skills-v2", skill)
        extra = [os.path.join(d, "examples.md")] + sorted(
            os.path.join(d, "references", f) for f in os.listdir(os.path.join(d, "references"))
            if f.endswith(".md")) if os.path.isdir(os.path.join(d, "references")) else []
        for p in extra:
            if read(p):
                parts.append(f"<skill name=\"{skill}\" file=\"{os.path.relpath(p, d)}\">\n{read(p)}\n</skill>")
    if not parts:
        raise SystemExit(f"skill-mode={mode} but skills-v2/{skill} has no content yet")
    return ("\nThe following skills are loaded. Follow them exactly; they override your defaults.\n\n"
            + "\n\n".join(parts))


def scenarios(path=""):
    d = json.load(open(path or os.path.join(ROOT, "evals-v2", "evals.json")))
    return d if isinstance(d, list) else d.get("evals") or d.get("scenarios")


def run_scenario(sc, a):
    system = SYSTEM_BASE + (("\n" + open(a.system_extra).read()) if a.system_extra else "") + skill_text(sc["skill"], a.skill_mode)
    user = "PROJECT CONTEXT:\n" + sc["context"] + "\n\nTASK:\n" + sc["prompt"]
    t = time.time()
    text, usage, err = call(a.model, system, user, a.max_out)
    el = round(time.time() - t, 1)
    with open(os.path.join(a.out, f"{sc['id']}.md"), "w") as f:
        f.write(f"# {sc['id']} — {sc['skill']}\n\n- model: {a.model}\n- skill-mode: {a.skill_mode}{' + ' + os.path.basename(a.system_extra) if a.system_extra else ''}\n"
                f"- seconds: {el}\n- usage: {json.dumps(usage)}\n- error: {err or 'none'}\n\n"
                f"## Prompt\n\n{sc['prompt']}\n\n## Answer\n\n{text}\n")
    return sc["id"], "ok" if text else "error", el, len(text), err or ""


def run_triggers(a):
    trig = json.load(open(os.path.join(ROOT, "evals-v2", "triggers.json")))
    descs = {}
    for s in sorted(trig):
        m = re.search(r"^description:\s*(.+?)(?=^\w[\w-]*:|^---)", read(os.path.join(ROOT, "skills-v2", s, "SKILL.md")),
                      re.S | re.M)
        descs[s] = " ".join(m.group(1).split()) if m else "(skill not written yet)"
    listing = "\n".join(f"- {s}: {d}" for s, d in descs.items())
    system = ("You route a user request to agent skills. Available skills:\n" + listing +
              "\n\nReply with ONLY a JSON array of the skill names that must be loaded for the request "
              "(the most specific owner first; [] if none apply).")
    items = []
    for s, sets in trig.items():
        for q in sets.get("trigger", []):
            items.append((s, "trigger", re.sub(r"\s*\[should trigger [^\]]+\]\s*$", "", q)))
        for q in sets.get("no_trigger", []):
            items.append((s, "no_trigger", re.sub(r"\s*\[should trigger [^\]]+\]\s*$", "", q)))
    def one(it):
        s, kind, q = it
        text, _, err = call(a.model, system, q, 200)
        m = re.search(r"\[.*?\]", text or "", re.S)
        try:
            picked = json.loads(m.group(0)) if m else []
        except ValueError:
            picked = []
        ok = (s in picked) if kind == "trigger" else (s not in picked)
        return s, kind, q, picked, ok, err or ""
    with ThreadPoolExecutor(max_workers=a.jobs) as ex:
        res = list(ex.map(one, items))
    with open(os.path.join(a.out, "triggers.tsv"), "w") as f:
        f.write("skill\tkind\tok\tpicked\tquery\terror\n")
        for s, kind, q, picked, ok, err in res:
            f.write(f"{s}\t{kind}\t{ok}\t{','.join(picked)}\t{q}\t{err}\n")
    by = {}
    for s, kind, *_rest in res:
        by.setdefault((s, kind), [0, 0])
    for s, kind, q, picked, ok, err in res:
        by[(s, kind)][0] += ok; by[(s, kind)][1] += 1
    for (s, kind), (ok, n) in sorted(by.items()):
        print(f"  {s:22s} {kind:10s} {ok}/{n}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True, help="opencode-go model id, e.g. deepseek-v4.1-flash")
    ap.add_argument("--out", required=True)
    ap.add_argument("--skill-mode", choices=["none", "skill", "full"], default="none")
    ap.add_argument("--system-extra", default="", help="file appended to the system prompt (control arms)")
    ap.add_argument("--triggers", action="store_true")
    ap.add_argument("--only", default="")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--max-out", type=int, default=64000)
    ap.add_argument("--resume", action="store_true",
                    help="skip scenarios whose output file already holds a non-empty answer (usage-limit safe)")
    ap.add_argument("--evals", default="", help="alternate scenario file (e.g. evals-v2/heldout.json)")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    if a.triggers:
        return run_triggers(a)
    scs = scenarios(a.evals)
    if a.only:
        keep = set(a.only.split(","))
        scs = [s for s in scs if s["id"] in keep]
    if a.resume:
        def done(sc):
            f = os.path.join(a.out, f"{sc['id']}.md")
            return os.path.isfile(f) and re.search(r"^## Answer\s*\n\s*\S", open(f).read(), re.M)
        skipped = [s["id"] for s in scs if done(s)]
        scs = [s for s in scs if not done(s)]
        if skipped:
            print(f"resume: skipping {len(skipped)} already answered", flush=True)
    print(f"{len(scs)} scenarios · model={a.model} ({style(a.model)}) · skill-mode={a.skill_mode}", flush=True)
    with ThreadPoolExecutor(max_workers=a.jobs) as ex:
        rows = list(ex.map(lambda s: run_scenario(s, a), scs))
    with open(os.path.join(a.out, "summary.tsv"), "w") as f:
        f.write("id\tstatus\tseconds\tanswer_chars\terror\n")
        for r in rows:
            f.write("\t".join(map(str, r)) + "\n")
            print(f"  {r[0]}: {r[1]} {r[2]}s chars={r[3]} {r[4]}", flush=True)


if __name__ == "__main__":
    sys.exit(main())
