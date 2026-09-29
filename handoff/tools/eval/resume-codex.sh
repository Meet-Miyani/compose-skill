#!/bin/bash
# Continue a Codex harness run that stopped to ask for confirmation, as a user would: "Yes, go ahead."
# Usage: resume-codex.sh <model> <task-id> <arm>
set -u
H=/private/tmp/claude-501/-Users-meetmiyani-Documents-MeetMiyani-MEET-skills-main-compose-skill/6e711724-74a1-4acc-9d65-5cc44a95b81f/scratchpad/harness
MODEL=$1; TASK=$2; ARM=$3
OUT="$H/runs/$MODEL/$TASK-$ARM"
cd "$OUT/project" || exit 1
T=$(grep -o '"thread_id":"[^"]*"' "$OUT/agent.jsonl" | head -1 | cut -d'"' -f4)
cp "$OUT/final.txt" "$OUT/final-turn1.txt"
START=$(date +%s)
codex exec resume "$T" "Yes, go ahead." --disable memories -m "$MODEL" \
  -c sandbox_mode='"workspace-write"' \
  -c "sandbox_workspace_write.writable_roots=[\"$HOME/.gradle\"]" \
  -c sandbox_workspace_write.network_access=true \
  --json -o "$OUT/final.txt" > "$OUT/agent-turn2.jsonl" 2> "$OUT/agent-turn2.err"
echo "needed_confirmation=1 turn2_exit=$? turn2_seconds=$(( $(date +%s) - START ))" >> "$OUT/meta.txt"
python3 "$H/codex-usage.py" "$OUT/agent-turn2.jsonl" >> "$OUT/meta.txt"
git add -A >/dev/null 2>&1
git diff --cached HEAD > "$OUT/agent.diff"
git diff --cached HEAD --stat > "$OUT/agent.stat"
if [ "$TASK" != HT-03 ]; then
  ./gradlew -q :composeApp:compileKotlinJvm :feature:notes:jvmTest :feature:tags:jvmTest :androidApp:assembleDebug \
    > "$OUT/verify.log" 2>&1
  sed -i '' '/^verify_exit=/d' "$OUT/meta.txt"
  echo "verify_exit=$?" >> "$OUT/meta.txt"
fi
cat "$OUT/meta.txt"
