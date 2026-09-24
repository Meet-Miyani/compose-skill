#!/usr/bin/env bash
# Size, code-density and content-policy report for skills-v2/.
# Exit 1 if any FAIL. Usage: handoff/tools/budget.sh [skills-v2/<name> ...]
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIRS=("$@"); [ ${#DIRS[@]} -eq 0 ] && DIRS=("$ROOT"/skills-v2/*/)
fail=0
printf "%-6s %6s %6s %5s  %s\n" "LEVEL" "LINES" "TOKENS" "CODE%" "FILE"
for d in "${DIRS[@]}"; do
  [ -d "$d" ] || continue
  while IFS= read -r f; do
    lines=$(wc -l < "$f" | tr -d ' ')
    tokens=$(( $(wc -c < "$f" | tr -d ' ') / 4 ))
    code=$(awk '/^[[:space:]]*```/{inb=!inb; next} inb{c++} END{print c+0}' "$f")
    pct=0; [ "$lines" -gt 0 ] && pct=$(( 100 * code / lines ))
    base="$(basename "$f")"; level="ok"
    case "$f" in
      */templates/*) level="tmpl" ;;
      */SKILL.md)
        [ "$tokens" -gt 3500 ] && level="WARN"
        [ "$tokens" -gt 5000 ] && level="FAIL"
        [ "$pct" -gt 10 ] && level="FAIL" ;;
      */examples.md) [ "$tokens" -gt 4500 ] && level="WARN" ;;
      *)
        [ "$tokens" -gt 3500 ] && level="WARN"
        [ "$tokens" -gt 4500 ] && level="FAIL"
        [ "$pct" -gt 30 ] && level="WARN" ;;
    esac
    [ "$level" = "FAIL" ] && fail=1
    printf "%-6s %6s %6s %4s%%  %s\n" "$level" "$lines" "$tokens" "$pct" "${f#$ROOT/}"
  done < <(find "$d" -type f -name '*.md' | sort)
done
echo
echo "--- Content policy scan (skills-v2, excluding templates/ and scripts/tests/) ---"
scan() { # $1 level  $2 label  $3 regex
  local hits
  hits=$(grep -rniE "$3" "${DIRS[@]}" --include='*.md' 2>/dev/null | grep -v '/templates/' | grep -v '/scripts/tests/' || true)
  if [ -n "$hits" ]; then
    echo "[$1] $2"; echo "$hits" | sed 's/^/    /' | head -40
    [ "$1" = "FAIL" ] && fail=1
  fi
}
scan FAIL "Source-project names (must be genericized)" '\bhaat|haatpartner|\bqoot\b|sunmi|intercom|restaurant-app|com\.haat|\bpartner\b'
scan WARN "Pinned version numbers (allowed only as a hard floor with a verify instruction)" '[0-9]+\.[0-9]+\.[0-9]+'
scan WARN "Out-of-kit stack mentioned (allowed only in migration/'not supported' notes)" 'navigation 2|nav 2|navhost|navcontroller|\bhilt\b|hiltviewmodel|\bmvvm\b'
scan WARN "Date-relative wording (no 'as of', 'currently', 'new in')" '\bas of\b|\bcurrently\b|\bnew in\b|\brecently\b'
echo
[ $fail -eq 0 ] && echo "RESULT: PASS" || echo "RESULT: FAIL"
exit $fail
