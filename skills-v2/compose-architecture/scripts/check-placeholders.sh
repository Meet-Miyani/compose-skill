#!/usr/bin/env bash
# check-placeholders.sh — feature rule 2: no TODO/FIXME/stub reaches done.
# bash 3.2 safe (no assoc arrays/mapfile/read -d/[[ =~ ]]/sed -i/GNU grep).
# No network; no writes. Usage: check-placeholders.sh <project-root> [file ...]
# File args: scan exactly those (each must exist). Otherwise: `git diff
# --name-only` in a work tree (tracked diff only), else *.kt/*.kts/*.xml
# under the configured module dirs. SEAM is a placeholder too: template
# SEAMs are implemented, not shipped (compose-feature rule 2).
# Prints <path>:<line>: <message>; exits 0 clean, 1 violation, 2 usage/error.
set -u

if [ $# -lt 1 ]; then
  echo "usage: check-placeholders.sh <project-root> [file ...]" >&2
  exit 2
fi
ROOT="$1"
shift
if [ ! -d "$ROOT" ]; then
  echo "error: not a directory: $ROOT" >&2
  exit 2
fi
ROOT="${ROOT%/}"

FEATURE_DIRS="feature"
CORE_DIRS="core"
DATA_DIRS="data"
COMPOSITION_ROOT="app"
DESIGN_SYSTEM_MODULE="core/designsystem"
DESIGN_SYSTEM_DIRS=""
LOCALE_DIRS=""
BASE_PACKAGE="com.example"
if [ -f "$ROOT/.composekit.conf" ]; then
  . "$ROOT/.composekit.conf"
fi
: "$FEATURE_DIRS" "$CORE_DIRS" "$DATA_DIRS" "$COMPOSITION_ROOT" "$DESIGN_SYSTEM_MODULE" "$LOCALE_DIRS" "$BASE_PACKAGE"

HAVE_RG=0
if command -v rg >/dev/null 2>&1; then HAVE_RG=1; fi
PATTERN='TODO|FIXME|NotImplementedError|SEAM'

fail=0
check_file() {
  file="$1"
  rel="$2"
  if [ "$HAVE_RG" -eq 1 ]; then
    hits="$(rg -n -e "$PATTERN" -- "$file" 2>/dev/null)"
  else
    hits="$(grep -n -E -e "$PATTERN" -- "$file" 2>/dev/null)"
  fi
  [ -n "$hits" ] || return 0
  while IFS= read -r hit || [ -n "$hit" ]; do
    [ -n "$hit" ] || continue
    lineno="${hit%%:*}"
    rest="${hit#*:}"
    token="TODO"
    case "$rest" in
      *NotImplementedError*) token="NotImplementedError" ;;
      *FIXME*) token="FIXME" ;;
      *SEAM*) token="SEAM" ;;
    esac
    printf '%s:%s: placeholder %s found; no placeholder reaches done\n' "$rel" "$lineno" "$token"
    fail=1
  done <<< "$hits"
}

if [ $# -gt 0 ]; then
  for f in "$@"; do
    if [ ! -f "$f" ]; then
      echo "error: no such file: $f" >&2
      exit 2
    fi
    check_file "$f" "${f#$ROOT/}"
  done
  exit "$fail"
fi

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  difflist="$(git -C "$ROOT" diff --name-only 2>/dev/null)"
  while IFS= read -r entry || [ -n "$entry" ]; do
    [ -n "$entry" ] || continue
    cand="$ROOT/$entry"
    [ -f "$cand" ] || continue
    check_file "$cand" "$entry"
  done <<< "$difflist"
  exit "$fail"
fi

filelist=""
for d in $FEATURE_DIRS $CORE_DIRS $DATA_DIRS $COMPOSITION_ROOT $DESIGN_SYSTEM_MODULE; do
  [ -n "$d" ] && [ -d "$ROOT/$d" ] || continue
  found="$(find "$ROOT/$d" -path '*/.git/*' -prune -o -type f \( -name '*.kt' -o -name '*.kts' -o -name '*.xml' \) -print 2>/dev/null)"
  filelist="$filelist
$found"
done
sorted="$(printf '%s\n' "$filelist" | sort -u)"
while IFS= read -r kt || [ -n "$kt" ]; do
  [ -n "$kt" ] || continue
  [ -f "$kt" ] || continue
  check_file "$kt" "${kt#$ROOT/}"
done <<< "$sorted"
exit "$fail"
