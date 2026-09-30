#!/usr/bin/env python3
"""Route budget for the compose entry skill (release plan step 6, O-17).

Parses skills-v2/compose/SKILL.md. Every tree leaf is one bullet line; files are backticked relative .md paths.
Leaves under "Question 1" are task paths and leaves under "Question 2" are areas. For every (task leaf, area leaf)
pair, the kit context is: entry SKILL.md + the union of files named on both leaves. Sizes are chars/4 tokens.
Prints the worst pairs and exits 1 if any pair exceeds the cap (default 18,000, i.e. 10% margin under 20k).
Usage: route-budget.py [--cap N] [--two-areas]
"""
import os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ENTRY = os.path.join(ROOT, "skills-v2", "compose", "SKILL.md")
cap = int(sys.argv[sys.argv.index("--cap") + 1]) if "--cap" in sys.argv else 18000
two_areas = "--two-areas" in sys.argv

def tokens(path):
    return os.path.getsize(path) // 4

base = os.path.dirname(ENTRY)
section, q1, q2, missing = None, [], [], []
for line in open(ENTRY, encoding="utf-8"):
    low = line.lower()
    if not line.startswith("#"):
        pass
    elif "question 1" in low:
        section = "q1"
    elif "question 2" in low:
        section = "q2"
    paths = re.findall(r"`([^`\s]+\.md)`", line)
    if not paths or not line.lstrip().startswith("-") or section is None:
        continue
    files = []
    for p in paths:
        full = os.path.normpath(os.path.join(base, p))
        (files if os.path.isfile(full) else missing).append(full if os.path.isfile(full) else p)
    label = re.sub(r"\s+", " ", line.strip())[:70]
    (q1 if section == "q1" else q2).append((label, set(files)))

if missing:
    print("MISSING PATHS:", *sorted(set(missing)), sep="\n  ")
if not q1 or not q2:
    print(f"could not find leaves: question 1 = {len(q1)}, question 2 = {len(q2)}")
    sys.exit(2)

entry = tokens(ENTRY)
rows = []
for l1, f1 in q1:
    for i, (l2, f2) in enumerate(q2):
        extra = [q2[j][1] for j in range(i + 1, len(q2))] if two_areas else [set()]
        for f3 in extra:
            files = f1 | f2 | f3
            rows.append((entry + sum(tokens(f) for f in files), l1, l2, len(files)))
rows.sort(reverse=True)
print(f"entry {entry} tokens; {len(q1)} task leaves x {len(q2)} area leaves; cap {cap}"
      + (" (two areas per task)" if two_areas else ""))
for t, l1, l2, n in rows[:8]:
    print(f"{t:6d}  files={n}  {l1[:34]:34s} | {l2[:34]}")
over = [r for r in rows if r[0] > cap]
print(f"worst {rows[0][0]}; {len(over)} of {len(rows)} routes over the cap")
sys.exit(1 if over or missing else 0)
