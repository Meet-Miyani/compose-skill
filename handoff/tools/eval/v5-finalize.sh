#!/bin/bash
# Finishes a v5 cell whose agent completed but whose runner wrap-up crashed (2026-09-30 incident: v5-run.sh was
# edited while running). Performs exactly v5-run.sh steps 4-5 on the saved project: final message, blind diff,
# hidden test and checks; then writes meta.txt with the given agent exit code.
# Usage: v5-finalize.sh <claude|codex|agy> <model> <T1..T8> <arm> <agent_exit> <note>
set -u
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-23.jdk/Contents/Home
REPO=/Users/meetmiyani/Documents/MeetMiyani/MEET/skills-main/compose-skill
W=$REPO/handoff/work/scratch/v5; V5=$REPO/evals-v2/heldout-v5
TOOL=$1; MODEL=$2; TASK=$3; ARM=$4; EXIT=$5; NOTE=$6
OUT=$W/runs/$MODEL/$TASK-$ARM
[ -f "$OUT/meta.txt" ] && { echo "already complete: $OUT"; exit 0; }
cd "$OUT/project" || exit 1
field() { python3 - "$V5/tasks.md" "$TASK" "$1" <<'EOF'
import re, sys
t = open(sys.argv[1]).read()
sec = re.search(rf"^## {sys.argv[2]}\b.*?(?=^## |\Z)", t, re.S | re.M).group(0)
m = re.search(rf"^{sys.argv[3]}:\s*(.*?)(?=^\w[\w ]*:|\Z)", sec, re.S | re.M)
print(m.group(1).strip() if m else "")
EOF
}
HIDDEN=$(field "Hidden test"); CHECKS=$(field Checks)
# the harness's own last commit (author "dev") is the starting point; agents commit as other authors, if at all
START_SHA=$(git log --author='^dev ' --format=%H -1)
python3 - "$TOOL" "$OUT" <<'EOF'
import json, sys, os
tool, out = sys.argv[1], sys.argv[2]
if tool == "codex" and os.path.isfile(os.path.join(out, "final.md")): sys.exit(0)
text = ""
for l in open(os.path.join(out, "agent.jsonl"), errors="replace"):
    try: e = json.loads(l)
    except ValueError: continue
    if tool == "claude" and e.get("type") == "result": text = str(e.get("result", ""))
    if tool == "agy" and e.get("event") == "result": text = str((e.get("result") or {}).get("response", ""))
open(os.path.join(out, "final.md"), "w").write(text)
EOF
git add -A >/dev/null 2>&1
git diff --cached "$START_SHA" -- . ':(exclude).claude' ':(exclude).agents' ':(exclude)CLAUDE.md' \
  ':(exclude)AGENTS.md' ':(exclude)GEMINI.md' ':(exclude)**/build/**' > "$OUT/answer.diff"
{ echo "agent_exit=$EXIT seconds=unknown"; echo "note=$NOTE"; } > "$OUT/meta.tmp"
case "$HIDDEN" in none|"") ;; *) D=$(cat "$V5/hidden/$TASK/DEST"); mkdir -p "$(dirname "$D")"
  cp "$(find "$V5/hidden/$TASK" -name '*.kt' | head -1)" "$D" ;; esac
case "$CHECKS" in none|"") echo "checks=none" >> "$OUT/meta.tmp" ;;
  *) ./gradlew --console=plain $CHECKS < /dev/null > "$OUT/checks.log" 2>&1; echo "checks_exit=$?" >> "$OUT/meta.tmp" ;; esac
rm -f "$OUT/meta.pending"; mv "$OUT/meta.tmp" "$OUT/meta.txt"; cat "$OUT/meta.txt"
