#!/usr/bin/env python3
"""Print 'five_hour_used=X weekly_used=Y' for the Codex thread named in an exec --json log."""
import glob, json, os, re, sys
log = open(sys.argv[1]).read()
m = re.search(r'"thread_id":"([^"]+)"', log)
if not m:
    sys.exit(0)
files = glob.glob(os.path.expanduser(f"~/.codex/sessions/*/*/*/*{m.group(1)}.jsonl"))
last = None
for f in files:
    for line in open(f):
        if '"rate_limits"' in line:
            last = line
if last:
    rl = re.search(r'"rate_limits":(\{.*?"plan_type":"[^"]*"[^}]*\})', last)
    d = json.loads(rl.group(1)) if rl else {}
    p, s = d.get("primary") or {}, d.get("secondary") or {}
    print(f"five_hour_used={p.get('used_percent')} weekly_used={s.get('used_percent')}")
