#!/bin/bash
# Moderator runner: a Codex model, single-shot in an empty read-only folder, one setup of held-out v4.
# Usage: run-codex-arm.sh <model> <inputs-dir> <out-dir> <label>
# Resumes finished ids. Stops when Codex use passes 80% of the 5-hour window or 50% of the week (owner guard).
MODEL=$1; IN=$2; OUT=$3; LABEL=$4; EMPTY=$(mktemp -d); mkdir -p "$OUT"
HERE=$(cd "$(dirname "$0")" && pwd)
for n in 01 02 03 04 05 06 07 08 09 10 11 12; do id=H4-$n
  awk '/^## Answer/{f=1;next} f&&NF{found=1;exit} END{exit !found}' "$OUT/$id.md" 2>/dev/null && { echo "$id done"; continue; }
  start=$(date +%s)
  codex exec --skip-git-repo-check --disable memories -s read-only -m "$MODEL" -C "$EMPTY" --json \
    -o "$OUT/$id.final.txt" - < "$IN/$id.md" > "$OUT/$id.jsonl" 2> "$OUT/$id.err"; code=$?
  usage=$(python3 "$HERE/codex-usage.py" "$OUT/$id.jsonl")
  { echo "# $id"; echo; echo "- model: $MODEL via Codex CLI (single-shot, empty read-only folder)"; echo "- skill-mode: $LABEL"
    echo "- seconds: $(( $(date +%s) - start ))"; echo "- exit: $code"; echo "- $usage"; echo; echo "## Answer"; echo
    cat "$OUT/$id.final.txt" 2>/dev/null; } > "$OUT/$id.md"
  echo "$id exit=$code chars=$(wc -c < "$OUT/$id.final.txt" 2>/dev/null | tr -d ' ') $usage"
  five=$(echo "$usage" | grep -o 'five_hour_used=[0-9.]*' | cut -d= -f2); week=$(echo "$usage" | grep -o 'weekly_used=[0-9.]*' | cut -d= -f2)
  if python3 -c "import sys; sys.exit(0 if float('${five:-100}') > 80 or float('${week:-100}') > 50 else 1)"; then
    echo "USAGE GUARD: five_hour=${five}% weekly=${week}%; stopping"; exit 3; fi
done
echo "$LABEL DONE"
