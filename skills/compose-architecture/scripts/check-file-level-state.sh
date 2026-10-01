#!/usr/bin/env bash
# check-file-level-state.sh — arch rule 13: no file-level mutable state.
#
# Results travel through a repository write or the nav key, never through
# a file-level `var`: it leaks the setter, is null after process death,
# is shared across panes and is not thread-safe.
#
# Any line starting at column 0 matching `var` (optionally prefixed by
# private/internal/public) in a navigation/ or presentation/ file is a
# violation. Indented `var` (class members, locals) and top-level `val`
# are clean — the `^` anchor handles that.
#
# Runs on macOS bash 3.2 and Linux (no assoc arrays, mapfile, read -d, [[ =~ ]], sed -i, GNU grep).
# No network; no writes anywhere.
#
# Usage:
#   check-file-level-state.sh <project-root>
set -u

ROOT="${1:-}"
if [ $# -ne 1 ] || [ -z "$ROOT" ]; then
  echo "usage: check-file-level-state.sh <project-root>" >&2
  exit 2
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

if command -v rg >/dev/null 2>&1; then
  HAVE_RG=1
else
  HAVE_RG=0
fi

PATTERN='^((private|internal|public)[[:space:]]+)?var[[:space:]]'
AWK_PROG='{ pos = index($0, ":"); lineno = substr($0, 1, pos - 1); content = substr($0, pos + 1); sub(/^(private|internal|public)[ \t]+/, "", content); sub(/^var[ \t]+/, "", content); name = content; sub(/[^A-Za-z0-9_].*$/, "", name); printf "%s:%s: top-level var in navigation/presentation file: %s\n", rel, lineno, name }'

listing="$(find "$ROOT" -path '*/.git/*' -prune -o -type f -name '*.kt' -print | sort)"
violations=""
OLDIFS="$IFS"
IFS='
'
for kt in $listing; do
  IFS="$OLDIFS"
  [ -n "$kt" ] || continue
  krel="${kt#$ROOT/}"
  composekit_skip_path "$krel" && continue
  case "/${kt#$ROOT/}/" in
    */navigation/*|*/presentation/*) ;;
    *) continue ;;
  esac
  if [ "$HAVE_RG" -eq 1 ]; then
    hits="$(rg -n --no-filename -e "$PATTERN" "$kt" 2>/dev/null | awk -v rel="${kt#$ROOT/}" "$AWK_PROG")"
  else
    hits="$(grep -n -E -e "$PATTERN" "$kt" 2>/dev/null | awk -v rel="${kt#$ROOT/}" "$AWK_PROG")"
  fi
  if [ -n "$hits" ]; then
    violations="$violations$hits
"
  fi
done
IFS="$OLDIFS"

if [ -n "$violations" ]; then
  printf '%s' "$violations"
  exit 1
fi
exit 0
