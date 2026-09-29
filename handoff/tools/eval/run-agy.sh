#!/bin/bash
# Harness trial runner: Antigravity CLI on the Notes baseline, with and without the kit.
# Usage: run-agy.sh <model> <task-id> <kit|nokit>
set -u
H=/private/tmp/claude-501/-Users-meetmiyani-Documents-MeetMiyani-MEET-skills-main-compose-skill/6e711724-74a1-4acc-9d65-5cc44a95b81f/scratchpad/harness
REPO=/Users/meetmiyani/Documents/MeetMiyani/MEET/skills-main/compose-skill
MODEL=$1; TASK=$2; ARM=$3
OUT=$H/runs/$MODEL/$TASK-$ARM
rm -rf "$OUT"; mkdir -p "$OUT"
git clone -q "$H/base" "$OUT/project"
cp "$H/base/local.properties" "$OUT/project/"
cd "$OUT/project" || exit 1

if [ "$ARM" = kit ]; then
  mkdir -p .agents/skills
  for s in compose-architecture compose-feature compose-ui compose-data compose-project compose-platform; do
    cp -R "$REPO/skills-v2/$s" .agents/skills/
  done
  cp -R "$H/kitfiles/scripts" "$H/kitfiles/.github" .
  cp "$H/kitfiles/.composekit.conf" .
  cat > AGENTS.md <<'EOF'
# Agent instructions

Compose/CMP work: load compose-architecture first; it routes to the owning skill.

## Project decisions

- UI_MODEL=when-needed (kit default).
EOF
  git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm "Install compose kit"
fi

PROMPT=$(python3 - "$H/tasks.md" "$TASK" <<'EOF'
import re, sys
t = open(sys.argv[1]).read()
sec = re.search(rf"^## {sys.argv[2]}\b.*?(?=^## |\Z)", t, re.S | re.M).group(0)
print(re.search(r"PROMPT:\n(.*?)\n\nRUBRIC:", sec, re.S).group(1).strip())
EOF
)
echo "$PROMPT" > "$OUT/prompt.txt"

START=$(date +%s)
agy --print "$PROMPT" --model "$MODEL" --dangerously-skip-permissions --sandbox \
  --output-format stream-json --print-timeout 45m > "$OUT/agent.jsonl" 2> "$OUT/agent.err"
echo "agent_exit=$? seconds=$(( $(date +%s) - START ))" > "$OUT/meta.txt"

git add -A >/dev/null 2>&1
git diff --cached HEAD > "$OUT/agent.diff"
git diff --cached HEAD --stat > "$OUT/agent.stat"

if [ "$TASK" != HT-03 ]; then
  ./gradlew -q :composeApp:compileKotlinJvm :feature:notes:jvmTest :feature:tags:jvmTest :androidApp:assembleDebug \
    > "$OUT/verify.log" 2>&1
  echo "verify_exit=$?" >> "$OUT/meta.txt"
fi
cat "$OUT/meta.txt"
