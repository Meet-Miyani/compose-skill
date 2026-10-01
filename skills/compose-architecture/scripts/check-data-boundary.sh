#!/usr/bin/env bash
set -u
# check-data-boundary.sh — data-boundary guards (BOUNDARIES only, M-10).
# macOS bash 3.2 + Linux; no network; no writes. Exits 0 clean, 1 violation, 2 usage.
# Usage: check-data-boundary.sh <project-root>
ROOT="${1:-}"
if [ $# -ne 1 ]; then
  echo "usage: check-data-boundary.sh <project-root>" >&2
  exit 2
fi
if [ ! -d "$ROOT" ]; then
  echo "error: not a directory: $ROOT" >&2
  exit 2
fi
case "$ROOT" in
  */) ROOT="${ROOT%/}" ;;
esac

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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/composekit-skip.sh" ]; then
  . "$SCRIPT_DIR/lib/composekit-skip.sh"
fi

search_kt() {
  pat="$1"
  dir="$2"
  if command -v rg >/dev/null 2>&1; then
    rg -n -e "$pat" --glob '*.kt' "$dir" 2>/dev/null
  else
    grep -R -n -E -e "$pat" --include='*.kt' "$dir" 2>/dev/null
  fi
}

relpath() {
  case "$1" in
    "$ROOT"/*) printf '%s\n' "${1#$ROOT/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

DTO_PAT='^((public|internal|private)[[:space:]]+)?((data[[:space:]]+)?class|object|interface)[[:space:]]+[A-Za-z0-9_]*(Dto|Entity)([^A-Za-z0-9_]|$)'
IMP_PAT='^import (io\.ktor|androidx\.room|androidx\.datastore|kotlinx\.serialization|androidx\.compose)'
STR_PAT='(At|Date)[[:space:]]*:[[:space:]]*String'

fail=0
SEARCH_DIRS="$FEATURE_DIRS $CORE_DIRS $DATA_DIRS $COMPOSITION_ROOT"
for d in $SEARCH_DIRS; do
  dir="$ROOT/$d"
  [ -d "$dir" ] || continue
  while IFS= read -r hit; do
    path="${hit%%:*}"
    rest="${hit#*:}"
    num="${rest%%:*}"
    text="${rest#*:}"
    case "$text" in
      *internal*) continue ;;
    esac
    names="$(printf '%s\n' "$text" | grep -o -E -e '[A-Za-z0-9_]*(Dto|Entity)' 2>/dev/null)"
    name=""
    for n in $names; do
      name="$n"
      break
    done
    if [ -z "$name" ]; then name="Dto"; fi
    rel="$(relpath "$path")"
    composekit_skip_path "$rel" && continue
    printf '%s:%s: public DTO/Entity must be internal: %s\n' "$rel" "$num" "$name"
    fail=1
  done < <(search_kt "$DTO_PAT" "$dir")
  while IFS= read -r hit; do
    path="${hit%%:*}"
    rest="${hit#*:}"
    num="${rest%%:*}"
    text="${rest#*:}"
    case "$path" in
      */domain/*) ;;
      *) continue ;;
    esac
    imp="${text#import }"
    rel="$(relpath "$path")"
    composekit_skip_path "$rel" && continue
    printf '%s:%s: domain must not import infrastructure: %s\n' "$rel" "$num" "$imp"
    fail=1
  done < <(search_kt "$IMP_PAT" "$dir")
  while IFS= read -r hit; do
    path="${hit%%:*}"
    rest="${hit#*:}"
    num="${rest%%:*}"
    text="${rest#*:}"
    case "$path" in
      */domain/*) ;;
      *) continue ;;
    esac
    full="$(printf '%s\n' "$text" | grep -o -E -e '[A-Za-z0-9_]*(At|Date)[[:space:]]*:[[:space:]]*String' 2>/dev/null)"
    cands="$(printf '%s\n' "$full" | grep -o -E -e '[A-Za-z0-9_]*(At|Date)' 2>/dev/null)"
    fname=""
    for c in $cands; do
      fname="$c"
      break
    done
    if [ -z "$fname" ]; then fname="timestamp"; fi
    rel="$(relpath "$path")"
    composekit_skip_path "$rel" && continue
    printf '%s:%s: domain timestamp must be Instant, not String: %s\n' "$rel" "$num" "$fname"
    fail=1
  done < <(search_kt "$STR_PAT" "$dir")
done
[ $fail -ne 0 ] && exit 1
exit 0
