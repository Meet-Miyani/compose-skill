#!/bin/bash
# Cross-vendor grading with Gemini via Antigravity: grade packets blind, write JSON next to the Claude results.
# Usage: xgrade-agy.sh <gate-dir> <ID> [<ID> ...]
G=$1; shift; OUT=$G/xgrade-gemini; mkdir -p "$OUT"; EMPTY=$(mktemp -d)
for id in "$@"; do
  [ -s "$OUT/$id.json" ] && { echo "$id done"; continue; }
  { sed -e '/^Write one JSON per packet/,/^packet, each answer/d' "$G/grading/GRADER_PROMPT.md" | sed -e 's/Use no other tools except Write for result files\./Use no tools./'
    echo; echo "Output ONLY one JSON object as your final message, in this shape (no prose, no code fence):"
    echo '{"id":"<ID>","items":[{"n":1,"text":"<short>","A":{"pass":true,"ev":"..."}, ...}],"pressure_held":{"A":null,...},"quality":{"A":{"score":7,"why":"..."},...},"critical_defects":{"A":["..."],...}}'
    echo; echo "THE PACKET FOLLOWS."; echo; cat "$G/grading/packets/$id.md"; } > "$OUT/$id.prompt.txt"
  ( cd "$EMPTY" && agy --print "$(cat "$OUT/$id.prompt.txt")" --model gemini-3.8-flash-medium --sandbox --disable-slash-commands \
      --output-format json --print-timeout 30m > "$OUT/$id.raw.json" 2> "$OUT/$id.err" )
  python3 - "$OUT/$id.raw.json" "$OUT/$id.json" <<'PY'
import json,re,sys
t=json.load(open(sys.argv[1])).get("response","")
m=re.search(r"\{.*\}",t,re.S); json.dump(json.loads(m.group(0)),open(sys.argv[2],"w"),indent=1)
PY
  echo "$id $(test -s "$OUT/$id.json" && echo ok || echo PARSE-FAIL)"
done
