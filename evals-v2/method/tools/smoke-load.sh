#!/bin/bash
# Plan step 8 native-loading smoke test (pre-registered in evals-v2/method/preregistration-v5.md).
# Usage: smoke-load.sh <claude|codex|agy> <S1|S2|S3>
# Copies the base Notes app, installs the kit in the tool's native skills folder with the one-line pointer,
# runs the task headless, and keeps the tool's event log for evals-v2/method/tools/smoke-parse.py.
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
W=$REPO/evals-v2/method/work/smoke8
TOOL=$1; TASK=$2
OUT=$W/runs/$TOOL-$TASK
rm -rf "$OUT"; mkdir -p "$OUT"
git clone -q "$W/base" "$OUT/project"
cp "$W/base/local.properties" "$OUT/project/"
cd "$OUT/project" || exit 1

POINTER='Compose/CMP work: load the compose skill first; it picks the path and the files to read.'
case "$TOOL" in
  claude) SK=.claude/skills; printf '%s\n' "$POINTER" > CLAUDE.md ;;
  codex)  SK=.agents/skills; printf '%s\n' "$POINTER" > AGENTS.md ;;
  agy)    SK=.agents/skills; printf '%s\n' "$POINTER" > AGENTS.md; cp AGENTS.md GEMINI.md ;;
  *) echo "unknown tool $TOOL" >&2; exit 2 ;;
esac
mkdir -p "$SK"
for s in compose compose-architecture compose-feature compose-ui compose-data compose-project compose-platform; do
  cp -R "$REPO/skills/$s" "$SK/"
done

VM=feature/notes/src/commonMain/kotlin/com/example/feature/notes/presentation/notes/NotesViewModel.kt
case "$TASK" in
  S1) PROMPT='Add a Tags screen: list the user'"'"'s tags stored on the device, with add and delete.' ;;
  S2) # plant the bug: remove the single-flight save guard and the test that would reveal it
      sed -i '' -e '/if (saveJob?.isActive == true) return/d' -e 's/saveJob = launchGuarded(/launchGuarded(/' "$VM"
      T=$(find feature/notes -name 'NotesViewModelTest.kt')
      python3 - "$T" <<'EOF'
import re, sys
p = sys.argv[1]; t = open(p).read()
t = re.sub(r"\n    @Test\n    fun `double save makes one repository write`\(\).*?\n    }\n", "\n", t, flags=re.S)
open(p, "w").write(t)
EOF
      PROMPT='Bug: double-tapping Save on the note screen saves the note twice. Fix it.' ;;
  S3) PROMPT='Review the notes screen composable and tell me what should change. Don'"'"'t edit anything.' ;;
  *) echo "unknown task $TASK" >&2; exit 2 ;;
esac
git add -A && git -c user.name=dev -c user.email=dev@example.com commit -qm "Install kit ($TOOL, $TASK)"
printf '%s\n' "$PROMPT" > "$OUT/prompt.txt"

START=$(date +%s)
case "$TOOL" in
  claude) claude -p "$PROMPT" --model sonnet --setting-sources project,local \
            --dangerously-skip-permissions --output-format stream-json --verbose < /dev/null \
            > "$OUT/agent.jsonl" 2> "$OUT/agent.err" ;;
  codex)  codex exec --disable memories -m gpt-6-luna -s workspace-write --add-dir "$HOME/.gradle" \
            -c sandbox_workspace_write.network_access=true --json -o "$OUT/final.txt" "$PROMPT" < /dev/null \
            > "$OUT/agent.jsonl" 2> "$OUT/agent.err" ;;
  agy)    agy --print "$PROMPT" --model gemini-3.8-flash-medium --dangerously-skip-permissions --sandbox \
            --output-format stream-json --print-timeout 45m < /dev/null > "$OUT/agent.jsonl" 2> "$OUT/agent.err" ;;
esac
echo "agent_exit=$? seconds=$(( $(date +%s) - START ))" > "$OUT/meta.txt"
git add -A >/dev/null 2>&1; git diff --cached HEAD --stat > "$OUT/agent.stat"
cat "$OUT/meta.txt"
