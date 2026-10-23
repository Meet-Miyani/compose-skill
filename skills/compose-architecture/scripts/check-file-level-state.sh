#!/usr/bin/env bash
# check-file-level-state.sh — arch rule 13: no file-level or module-level
# mutable state.
#
# Results travel through a repository write or the nav key, never through
# file-level mutable state: it leaks the setter, is null after process
# death, is shared across panes and is not thread-safe.
#
# Violations in any main source set (test source sets are skipped):
# - a column-0 `var`, with any annotations or modifiers (`lateinit`,
#   `@Volatile`, visibility, `actual`) before it;
# - a column-0 `val` initialised with a mutable holder (MutableStateFlow,
#   MutableSharedFlow, mutableStateOf, mutable collections, Channel);
# - either form as a direct member of an `object` or `companion object`.
# Class members, locals, constructor parameters and anonymous `object :`
# expressions are clean. Object bodies are tracked by counting braces and
# parentheses outside strings and comments.
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
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ ! -f "$SCRIPT_DIR/lib/composekit-conf.sh" ]; then
  echo "error: missing lib/composekit-conf.sh next to $(basename "$0"); re-run install-guards.sh" >&2
  exit 2
fi
. "$SCRIPT_DIR/lib/composekit-conf.sh"
composekit_load_conf "$ROOT/.composekit.conf" || exit 2
: "$FEATURE_DIRS" "$CORE_DIRS" "$DATA_DIRS" "$COMPOSITION_ROOT" "$DESIGN_SYSTEM_MODULE" "$LOCALE_DIRS" "$BASE_PACKAGE"

if [ -f "$SCRIPT_DIR/lib/composekit-skip.sh" ]; then
  . "$SCRIPT_DIR/lib/composekit-skip.sh"
fi

# One pass per file. `clean` is the line with block comments, raw strings,
# string and char literals and line comments removed; `top` means the line
# starts at column 0. `depth` counts braces and parentheses inside an
# object body, so depth 1 holds the object's direct members.
AWK_PROG='
function decl(s) {
  while (sub(/^@[A-Za-z_][A-Za-z0-9_.:]*(\([^)]*\))?[ \t]*/, "", s) || sub(/^(private|internal|public|protected|actual|expect|lateinit|override|open|final|const)[ \t]+/, "", s)) {}
  return s
}
function kind(d) {
  # `var Type.name` / `var <T> Type<T>.name` is an extension property: no backing field.
  if (d ~ /^var[ \t]+(<|[A-Za-z_][A-Za-z0-9_]*(<[^>]*>)?\??\.)/) return ""
  if (d ~ /^var[ \t]/) return "var"
  if (d ~ /^val[ \t]/ && d ~ /=[ \t]*(MutableStateFlow|MutableSharedFlow|mutableStateOf|mutableIntStateOf|mutableLongStateOf|mutableFloatStateOf|mutableDoubleStateOf|mutableStateListOf|mutableStateMapOf|mutableListOf|mutableMapOf|mutableSetOf|arrayListOf|hashMapOf|hashSetOf|linkedMapOf|linkedSetOf|Channel)[ \t]*[<(]/) return "mutable val"
  return ""
}
function report(label, d,   n) {
  n = d; sub(/^va[lr][ \t]+/, "", n); sub(/[^A-Za-z0-9_].*$/, "", n)
  printf "%s:%d: %s: %s (arch rule 13)\n", rel, FNR, label, n
}
function count(s, re) { return gsub(re, "", s) }
{
  line = $0
  cont = in_block || in_raw
  if (in_block) {
    p = index(line, "*/"); if (p == 0) next
    line = substr(line, p + 2); in_block = 0
  }
  if (in_raw) {
    p = index(line, "\"\"\""); if (p == 0) next
    line = substr(line, p + 3); in_raw = 0
  }
  top = (!cont && line ~ /^[^ \t]/)
  clean = line
  while (match(clean, /"""/)) {
    rest = substr(clean, RSTART + 3); q = index(rest, "\"\"\"")
    if (q == 0) { clean = substr(clean, 1, RSTART - 1); in_raw = 1; break }
    clean = substr(clean, 1, RSTART - 1) "\"\"" substr(rest, q + 3)
  }
  gsub(/"([^"\\]|\\.)*"/, "\"\"", clean)
  gsub(/'\''([^'\''\\]|\\.)*'\''/, "'\'''\''", clean)
  gsub(/\/\*([^*]|\*+[^*\/])*\*+\//, "", clean)
  p = index(clean, "/*")
  if (p > 0) { clean = substr(clean, 1, p - 1); in_block = 1 }
  sub(/\/\/.*$/, "", clean)
  body = clean; sub(/^[ \t]+/, "", body)
  if (body == "") next
  d = decl(body)
  if (top) in_obj = 0
  if (in_obj) {
    if (depth == 1 && (k = kind(d)) != "") report(k " in object", d)
    depth += count(clean, "[{(]") - count(clean, "[})]")
    if (depth <= 0) in_obj = 0
    next
  }
  if (top && (k = kind(d)) != "") report("top-level " k, d)
  if (d ~ /^(data[ \t]+)?object[ \t]+[A-Za-z_]/ || d ~ /^companion[ \t]+object([ \t{:]|$)/) {
    p = index(d, "{")
    if (p > 0) {
      member = substr(d, p + 1); sub(/^[ \t]+/, "", member); member = decl(member)
      if ((k = kind(member)) != "") report(k " in object", member)
    }
    depth = count(clean, "[{(]") - count(clean, "[})]")
    if (depth > 0) in_obj = 1
  }
}'

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
  case "/$krel/" in
    */src/test/*|*/src/*Test/*) continue ;;
  esac
  hits="$(awk -v rel="$krel" "$AWK_PROG" "$kt")"
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
