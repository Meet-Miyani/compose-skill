#!/usr/bin/env bash
# Runs the repo's skill validator (scripts/validate-skill.sh, hard-wired to skills/compose)
# against every skill under skills-v2/ (or the skill dirs given as arguments).
# Usage: handoff/tools/validate-v2.sh [--score-only|--quick|--md] [skills-v2/<name> ...]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLAGS=()
DIRS=()
for a in "$@"; do
  case "$a" in --*) FLAGS+=("$a") ;; *) DIRS+=("$a") ;; esac
done
if [ ${#DIRS[@]} -eq 0 ]; then
  for d in "$ROOT"/skills-v2/*/; do [ -f "$d/SKILL.md" ] && DIRS+=("${d%/}"); done
fi
[ ${#DIRS[@]} -eq 0 ] && { echo "No skills found under skills-v2/"; exit 1; }
TMP="$(mktemp -t validate-v2.XXXXXX)"
trap 'rm -f "$TMP"' EXIT
status=0
for d in "${DIRS[@]}"; do
  abs="$(cd "$d" 2>/dev/null && pwd)" || { abs="$(cd "$ROOT/$d" && pwd)"; }
  sed "5s#.*#cd \"$abs\"#" "$ROOT/scripts/validate-skill.sh" > "$TMP"
  echo "=== $(basename "$abs") ==="
  bash "$TMP" ${FLAGS[@]+"${FLAGS[@]}"} || status=1
done
exit $status
