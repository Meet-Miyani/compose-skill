#!/usr/bin/env bash
# Verifies handoff/work/HARVEST_LEDGER.md covers every file of the legacy skill and that
# every row has a class and a destination. Usage: handoff/tools/ledger-check.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
L="$ROOT/handoff/work/HARVEST_LEDGER.md"
[ -f "$L" ] || { echo "FAIL: $L missing"; exit 1; }
fail=0
for f in "$ROOT"/skills/compose/SKILL.md "$ROOT"/skills/compose/references/*.md; do
  n="$(basename "$f")"
  grep -qE "^## (references/)?${n//./\\.}\b" "$L" || { echo "FAIL: no section for $n"; fail=1; }
done
rows=$(grep -cE '^\| *[A-Z]+-[0-9]+ *\|' "$L")
bad=$(grep -E '^\| *[A-Z]+-[0-9]+ *\|' "$L" | awk -F'|' '{c=$5; d=$6; gsub(/ /,"",c); gsub(/ /,"",d); if (c=="" || d=="") print}' )
[ -n "$bad" ] && { echo "FAIL: rows missing class or destination:"; echo "$bad" | head -20; fail=1; }
echo "Rows: $rows"
echo "By class:"; grep -E '^\| *[A-Z]+-[0-9]+ *\|' "$L" | awk -F'|' '{gsub(/ /,"",$5); print $5}' | sort | uniq -c
echo "Dropped:"; grep -E '^\| *[A-Z]+-[0-9]+ *\|' "$L" | awk -F'|' '{gsub(/^ +| +$/,"",$6); if ($6 ~ /^DROP/) n++} END{print n+0}'
if [ -d "$ROOT/skills-v2" ]; then
  echo "Unlanded (destination file not found in skills-v2):"
  grep -E '^\| *[A-Z]+-[0-9]+ *\|' "$L" | awk -F'|' '{gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$6); print $2 "\t" $6}' \
   | while IFS=$'\t' read -r id dest; do
       case "$dest" in DROP*|"") continue ;; esac
       file="${dest%%#*}"
       [ -f "$ROOT/skills-v2/$file" ] || echo "  $id -> $dest"
     done
fi

echo "Dup-chain problems (dup target missing or itself dropped):"
chain=$(python3 - "$L" <<'PY'
import re,sys
rows={}
for line in open(sys.argv[1]):
    if not re.match(r'^\|\s*[A-Z]+-\d+\s*\|',line): continue
    c=[x.strip() for x in line.strip().strip('|').split('|')]
    if len(c)>=5: rows[c[0]]=c[4]
for k,d in rows.items():
    m=re.search(r'dup of ([A-Z]+-\d+)',d)
    if m and (m.group(1) not in rows or rows[m.group(1)].startswith('DROP')):
        print(f"  {k} -> {m.group(1)}")
PY
)
if [ -n "$chain" ]; then echo "$chain"; echo "WARN: fix dup chains before Phase 9 sign-off"; else echo "  none"; fi
[ $fail -eq 0 ] && echo "RESULT: PASS" || echo "RESULT: FAIL"
exit $fail
