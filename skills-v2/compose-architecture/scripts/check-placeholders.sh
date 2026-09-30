#!/usr/bin/env bash
# check-placeholders.sh — feature rule 2: no TODO/FIXME/stub reaches done.
# bash 3.2 safe (no assoc arrays/mapfile/read -d/[[ =~ ]]/sed -i/GNU grep).
# No network; no writes. Usage: check-placeholders.sh <project-root> [--base <ref>] [file ...]
# File args: scan exactly those (each must exist). Otherwise: unstaged,
# staged, base...HEAD when requested, and untracked files (`git ls-files --others
# --exclude-standard`) in a work tree, filtered to source and resource
# files and excluding the installed guard directory, else *.kt/*.kts/*.xml
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
BASE=""
if [ "${1:-}" = "--base" ]; then
  if [ $# -lt 2 ] || [ -z "$2" ] || [ "${2#--}" != "$2" ]; then
    echo "error: --base requires a ref" >&2; exit 2
  fi
  BASE="$2"
  shift 2
fi
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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/composekit-skip.sh" ]; then
  . "$SCRIPT_DIR/lib/composekit-skip.sh"
fi

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
  echo "scanned $# files"
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
  staged="$(git -C "$ROOT" diff --name-only --cached 2>/dev/null)"
  untracked="$(git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null)"
  committed=""
  if [ -n "$BASE" ]; then
    git -C "$ROOT" rev-parse --verify "$BASE^{commit}" >/dev/null 2>&1 || { echo "error: invalid base ref: $BASE" >&2; exit 2; }
    committed="$(git -C "$ROOT" diff --name-only "$BASE...HEAD")" || exit 2
  fi
  difflist="$difflist
$staged
$committed
$untracked"
  difflist="$(printf '%s\n' "$difflist" | sort -u)"
  scanned=0
  while IFS= read -r entry || [ -n "$entry" ]; do
    [ -n "$entry" ] || continue
    # Generated and installed trees are never scanned (agentic trial T1):
    # build outputs, Gradle/Kotlin/IDE state, installed skills, node_modules.
    composekit_skip_path "$entry" && continue
    # Source and resource files only, never the installed guard directory:
    # the guard scripts carry TODO/FIXME/SEAM literals in their own comments
    # and pattern strings, so scanning them fails the check on itself.
    case "$entry" in
      scripts/composekit/*) continue ;;
    esac
    case "$entry" in
      *.kt|*.kts|*.xml|*.gradle) ;;
      *) continue ;;
    esac
    cand="$ROOT/$entry"
    [ -f "$cand" ] || continue
    scanned=$((scanned + 1))
    check_file "$cand" "$entry"
  done <<< "$difflist"
  echo "scanned $scanned files"
  [ "$scanned" -gt 0 ] || echo "warning: no source files scanned"
  exit "$fail"
fi

[ -z "$BASE" ] || { echo "error: --base requires a git work tree" >&2; exit 2; }

filelist=""
for d in $FEATURE_DIRS $CORE_DIRS $DATA_DIRS $COMPOSITION_ROOT $DESIGN_SYSTEM_MODULE; do
  [ -n "$d" ] && [ -d "$ROOT/$d" ] || continue
  found="$(find "$ROOT/$d" -path '*/.git/*' -prune -o -type f \( -name '*.kt' -o -name '*.kts' -o -name '*.xml' \) -print 2>/dev/null)"
  filelist="$filelist
$found"
done
sorted="$(printf '%s\n' "$filelist" | sort -u)"
scanned=0
while IFS= read -r kt || [ -n "$kt" ]; do
  [ -n "$kt" ] || continue
  [ -f "$kt" ] || continue
  krel="${kt#$ROOT/}"
  composekit_skip_path "$krel" && continue
  scanned=$((scanned + 1))
  check_file "$kt" "${kt#$ROOT/}"
done <<< "$sorted"
echo "scanned $scanned files"
[ "$scanned" -gt 0 ] || echo "warning: no source files scanned"
exit "$fail"
