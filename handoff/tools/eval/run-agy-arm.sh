#!/bin/bash
# Moderator runner: Gemini 3.8 Flash via Antigravity, single-shot, one arm of held-out v4.
# Usage: run-agy-arm.sh <inputs-dir> <out-dir> <label> [ids...]
# Resumes: skips ids whose answer file already has a non-empty "## Answer". One retry on a retryable error;
# stops the whole run on RESOURCE_EXHAUSTED (quota) so no id is burned twice.
IN=$1; OUT=$2; LABEL=$3; shift 3
IDS=${*:-H4-01 H4-02 H4-03 H4-04 H4-05 H4-06 H4-07 H4-08 H4-09 H4-10 H4-11 H4-12}
EMPTY=$(mktemp -d); mkdir -p "$OUT"
one() {
  local id=$1 start code
  start=$(date +%s)
  ( cd "$EMPTY" && agy --print "$(cat "$IN/$id.md")" --model gemini-3.8-flash-medium --sandbox \
      --dangerously-skip-permissions --disable-slash-commands --output-format json --print-timeout 30m \
      > "$OUT/$id.json" 2> "$OUT/$id.err" ); code=$?
  python3 -c "import json,sys; d=json.load(open(sys.argv[1])); open(sys.argv[2],'w').write(d.get('response',''))" \
    "$OUT/$id.json" "$OUT/$id.final.txt" 2>/dev/null
  { echo "# $id"; echo; echo "- model: gemini-3.8-flash-medium via agy CLI (single-shot, empty folder)"
    echo "- skill-mode: $LABEL"; echo "- seconds: $(( $(date +%s) - start ))"; echo "- exit: $code"; echo
    echo "## Answer"; echo; cat "$OUT/$id.final.txt" 2>/dev/null; } > "$OUT/$id.md"
  echo "$id exit=$code chars=$(wc -c < "$OUT/$id.final.txt" 2>/dev/null | tr -d ' ')"
}
for id in $IDS; do
  awk '/^## Answer/{f=1;next} f&&NF{found=1;exit} END{exit !found}' "$OUT/$id.md" 2>/dev/null && { echo "$id done"; continue; }
  one "$id"
  if grep -q RESOURCE_EXHAUSTED "$OUT/$id.err" 2>/dev/null; then echo "QUOTA EXHAUSTED at $id; stopping"; exit 3; fi
  if grep -q '"retryable":true' "$OUT/$id.err" 2>/dev/null; then
    mkdir -p "$OUT/failed-attempt-1"; mv "$OUT/$id".* "$OUT/failed-attempt-1/"; echo "$id retry (endpoint error)"; one "$id"
  fi
done
echo "$LABEL DONE"
