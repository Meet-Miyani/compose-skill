#!/bin/bash
# Plan step 9 (v5) runner, pre-registered in evals-v2/method/preregistration-v5.md.
# Usage: v5-run.sh <claude|codex|agy> <model> <T1..T8> <nokit|generic|kit>
# Clones the finished base app, installs the arm, applies the task setup, runs the agent headless, then adds the
# hidden test (bug fixes) and runs the task's checks. Outputs in evals-v2/method/work/v5/runs/<model>/<task>-<arm>/.
set -u
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-23.jdk/Contents/Home
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
W=$REPO/evals-v2/method/work/v5
V5=$REPO/evals-v2/heldout-v5
TOOL=$1; MODEL=$2; TASK=$3; ARM=$4
# Pause point between cells: while PAUSE exists, no new cell starts (running cells finish normally).
while [ -f "$W/PAUSE" ]; do sleep 30; done
OUT=$W/runs/$MODEL/$TASK-$ARM
[ -f "$OUT/meta.txt" ] && { echo "done already: $OUT"; exit 0; }
rm -rf "$OUT"; mkdir -p "$OUT"
git clone -q "$W/base" "$OUT/project"
cp "$W/base/local.properties" "$OUT/project/"
cd "$OUT/project" || exit 1

field() { python3 - "$V5/tasks.md" "$TASK" "$1" <<'EOF'
import re, sys
t = open(sys.argv[1]).read()
sec = re.search(rf"^## {sys.argv[2]}\b.*?(?=^## |\Z)", t, re.S | re.M).group(0)
m = re.search(rf"^{sys.argv[3]}:\s*(.*?)(?=^\w[\w ]*:|\Z)", sec, re.S | re.M)
print(m.group(1).strip() if m else "")
EOF
}
PROMPT=$(field Prompt); SETUP=$(field Setup); HIDDEN=$(field "Hidden test"); CHECKS=$(field Checks)
printf '%s\n' "$PROMPT" > "$OUT/prompt.txt"

# 1. arm
if [ "$ARM" != kit ]; then rm -rf scripts/composekit .composekit.conf .github/workflows/composekit.yml; fi
case "$TOOL" in claude) INSTR=CLAUDE.md; SK=.claude/skills ;; *) INSTR=AGENTS.md; SK=.agents/skills ;; esac
case "$ARM" in
  generic) cp "$REPO/evals-v2/control/generic-senior-prompt.md" "$INSTR" ;;
  kit) printf '%s\n' 'Compose/CMP work: load the compose skill first; it picks the path and the files to read.' > "$INSTR"
       mkdir -p "$SK"
       for s in compose compose-architecture compose-feature compose-ui compose-data compose-project compose-platform; do
         cp -R "$REPO/skills/$s" "$SK/"; done ;;
esac
[ "$TOOL" = agy ] && [ -f AGENTS.md ] && cp AGENTS.md GEMINI.md
git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm "Project setup"
# 2. task setup, as its own commit so a review task's "PR" is visible in git history
TITLE=$(field Commit); [ -n "$TITLE" ] || TITLE="Update"
case "$SETUP" in none|"") ;; *) bash "$V5/setup/$TASK.sh" > "$OUT/setup.log" 2>&1 || { echo "setup failed" >&2; exit 3; }
  git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm "$TITLE" ;; esac
START_SHA=$(git rev-parse HEAD)

# 3. agent (60 min hard cap)
cap() { perl -e 'alarm 3600; exec @ARGV' "$@"; }
T0=$(date +%s)
case "$TOOL" in
  claude) cap claude -p "$PROMPT" --model "$MODEL" --setting-sources project,local --dangerously-skip-permissions \
            --output-format stream-json --verbose < /dev/null > "$OUT/agent.jsonl" 2> "$OUT/agent.err" ;;
  codex)  cap codex exec --disable memories -m "$MODEL" -s workspace-write --add-dir "$HOME/.gradle" --add-dir "$HOME/.konan" \
            -c sandbox_workspace_write.network_access=true --json -o "$OUT/final.md" "$PROMPT" < /dev/null \
            > "$OUT/agent.jsonl" 2> "$OUT/agent.err" ;;
  agy)    cap agy --print "$PROMPT" --model "$MODEL" --dangerously-skip-permissions \
            --output-format stream-json --print-timeout 60m < /dev/null > "$OUT/agent.jsonl" 2> "$OUT/agent.err" ;;
esac
echo "agent_exit=$? seconds=$(( $(date +%s) - T0 ))" > "$OUT/meta.tmp"

# 4. final message and diff (kit files excluded so graders stay blind to the arm)
python3 - "$TOOL" "$OUT" <<'EOF'
import json, sys, os
tool, out = sys.argv[1], sys.argv[2]
if tool == "codex": sys.exit(0)
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

# 5. hidden test + checks
case "$HIDDEN" in none|"") ;; *) D=$(cat "$V5/hidden/$TASK/DEST"); mkdir -p "$(dirname "$D")"
  cp "$(find "$V5/hidden/$TASK" -name '*.kt' | head -1)" "$D" ;; esac
case "$CHECKS" in none|"") echo "checks=none" >> "$OUT/meta.tmp" ;;
  *) ./gradlew --console=plain $CHECKS < /dev/null > "$OUT/checks.log" 2>&1; echo "checks_exit=$?" >> "$OUT/meta.tmp" ;; esac
mv "$OUT/meta.tmp" "$OUT/meta.txt"; cat "$OUT/meta.txt"
