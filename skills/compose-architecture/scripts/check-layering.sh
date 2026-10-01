#!/usr/bin/env bash
# check-layering.sh — module dependency direction (arch rules 1-3, BOUNDARIES only).
# macOS bash 3.2 and Linux. No network; no writes. Usage: check-layering.sh <project-root>
# Reads <project-root>/.composekit.conf when present. Prints <path>:<line>: <message>.
# Exits 0 clean, 1 violation, 2 usage.
set -u

ROOT="${1:-}"
if [ $# -ne 1 ] || [ -z "$ROOT" ]; then echo "usage: check-layering.sh <project-root>" >&2; exit 2; fi
if [ ! -d "$ROOT" ]; then echo "error: not a directory: $ROOT" >&2; exit 2; fi

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

fail=0
report() { printf '%s:%s: %s\n' "$1" "$2" "$3"; fail=1; }

HAVE_RG=0
if command -v rg >/dev/null 2>&1; then
  HAVE_RG=1
fi
# file:line:content matches for an ERE in Kotlin sources; rg preferred.
search_sources() {
  pattern="$1"; shift
  if [ "$HAVE_RG" -eq 1 ]; then
    rg -n -e "$pattern" --glob '*.kt' --glob '*.kts' "$@"
  else
    grep -R -n -E -e "$pattern" --include='*.kt' --include='*.kts' "$@"
  fi
}
# Dots in the base package must match literally inside the ERE.
BASE_ESC="$(printf '%s' "$BASE_PACKAGE" | sed -e 's/\./\\./g')"
IMPORT_ERE="^import $BASE_ESC\\.feature\\."
# One converted target path from a build file. Scope: feature | core | data.
check_target() {
  rel="$1"; lineno="$2"; own="$3"; scope="$4"; target_path="$5"
  if [ "$target_path" = "$COMPOSITION_ROOT" ]; then
    [ "$scope" = "feature" ] && report "$rel" "$lineno" "module $own depends on the composition root: $target_path"
    [ "$scope" != "feature" ] && report "$rel" "$lineno" "core/data module $own depends on the composition root: $target_path"
    return
  fi
  for fd in $FEATURE_DIRS; do
    case "$target_path" in
      "$fd"/*)
        [ "$target_path" = "$own" ] && continue
        [ "$scope" = "feature" ] && report "$rel" "$lineno" "feature $own depends on another feature: $target_path"
        [ "$scope" != "feature" ] && report "$rel" "$lineno" "core/data module $own depends on a feature: $target_path"
        ;;
    esac
  done
  if [ "$scope" = "core" ]; then
    for dd in $DATA_DIRS; do
      case "$target_path" in
        "$dd"/*) report "$rel" "$lineno" "core module $own depends on data: $target_path" ;;
      esac
    done
  fi
}
# Every project() target in one build file. Args: <rel-path> <scope>.
check_gradle_file() {
  rel="$1"; scope="$2"; own="$(dirname "$rel")"; lineno=0
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    targets="$(printf '%s\n' "$line" | sed -n -e 's/.*project( *"\([^"]*\)".*/\1/p' -e "s/.*project( *'\([^']*\)'.*/\1/p")"
    # Type-safe Gradle accessors: projects.feature.noteDetail -> feature/note-detail.
    accessors="$(printf '%s\n' "$line" | grep -o -E 'projects(\.[A-Za-z][A-Za-z0-9]*)+' || true)"
    while IFS= read -r accessor || [ -n "$accessor" ]; do
      [ -n "$accessor" ] || continue
      target_path="$(printf '%s' "${accessor#projects.}" | sed -E 's/([a-z0-9])([A-Z])/\1-\2/g' | tr '[:upper:].' '[:lower:]/')"
      check_target "$rel" "$lineno" "$own" "$scope" "$target_path"
    done <<< "$accessors"
    [ -n "$targets" ] || continue
    while IFS= read -r target || [ -n "$target" ]; do
      [ -n "$target" ] || continue
      target_path="$(printf '%s' "$target" | sed -e 's/^://' -e 's/:/\//g')"
      [ -n "$target_path" ] || continue
      check_target "$rel" "$lineno" "$own" "$scope" "$target_path"
    done <<< "$targets"
  done < "$ROOT/$rel"
}

# Every build.gradle.kts under a dir list. Args: <dirs> <scope>.
check_gradle_dirs() {
  dirlist="$1"; scope="$2"
  for d in $dirlist; do
    [ -d "$ROOT/$d" ] || continue
    files="$(find "$ROOT/$d" -name 'build.gradle.kts' 2>/dev/null)"
    [ -n "$files" ] || continue
    while IFS= read -r file || [ -n "$file" ]; do
      [ -n "$file" ] || continue
      frel="${file#$ROOT/}"
      composekit_skip_path "$frel" && continue
      check_gradle_file "${file#$ROOT/}" "$scope"
    done <<< "$files"
  done
}

# Kotlin feature imports under a dir list. Args: <dirs> <scope>.
check_import_dirs() {
  dirlist="$1"; scope="$2"
  for d in $dirlist; do
    [ -d "$ROOT/$d" ] || continue
    matches="$(search_sources "$IMPORT_ERE" "$ROOT/$d" 2>/dev/null)"
    [ -n "$matches" ] || continue
    while IFS= read -r result || [ -n "$result" ]; do
      [ -n "$result" ] || continue
      file="${result%%:*}"; rest="${result#*:}"
      lineno="${rest%%:*}"; content="${rest#*:}"
      rel="${file#$ROOT/}"; imp="${content#import }"; imp="${imp%% *}"
      composekit_skip_path "$rel" && continue
      tail="${rel#$d/}"; ownseg="${tail%%/*}"
      if [ "$scope" = "feature" ]; then
        seg="$(printf '%s\n' "$content" | sed -n -e "s/^import $BASE_ESC\\.feature\\.\\([A-Za-z0-9_][A-Za-z0-9_]*\\).*/\\1/p")"
        [ -n "$seg" ] || continue
        [ "$seg" != "$ownseg" ] || continue
        report "$rel" "$lineno" "feature $d/$ownseg depends on another feature: $imp"
      else
        report "$rel" "$lineno" "core/data module $d/$ownseg depends on a feature: $imp"
      fi
    done <<< "$matches"
  done
}

check_gradle_dirs "$FEATURE_DIRS" "feature"
check_gradle_dirs "$CORE_DIRS" "core"
check_gradle_dirs "$DATA_DIRS" "data"
check_import_dirs "$FEATURE_DIRS" "feature"
check_import_dirs "$CORE_DIRS $DATA_DIRS" "coredata"

exit "$fail"
