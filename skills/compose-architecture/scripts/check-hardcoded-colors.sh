#!/usr/bin/env bash
set -u
# check-hardcoded-colors.sh — raw Color(0x...) literals live in the design-system
# directories only (DESIGN_SYSTEM_DIRS; DESIGN_SYSTEM_MODULE is its one-item
# alias).
# Everywhere else, UI code reads color from theme tokens (e.g. AppTheme.colors.<semantic>).
# macOS bash 3.2 + Linux; no network; no writes. Exits 0 clean, 1 violation, 2 usage.
# Usage: check-hardcoded-colors.sh <project-root>
ROOT="${1:-}"
if [ $# -ne 1 ]; then
  echo "usage: check-hardcoded-colors.sh <project-root>" >&2
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
: "$FEATURE_DIRS" "$CORE_DIRS" "$DATA_DIRS" "$COMPOSITION_ROOT" "$DESIGN_SYSTEM_MODULE" "$LOCALE_DIRS" "$BASE_PACKAGE"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/composekit-skip.sh" ]; then
  . "$SCRIPT_DIR/lib/composekit-skip.sh"
fi
# DESIGN_SYSTEM_MODULE stays a one-item alias: when DESIGN_SYSTEM_DIRS is
# empty, the single module is the whole allowlist (branding/theme modules
# count; palette colors legitimately live there).
if [ -z "$DESIGN_SYSTEM_DIRS" ]; then
  DESIGN_SYSTEM_DIRS="$DESIGN_SYSTEM_MODULE"
fi

search_kt() {
  if command -v rg >/dev/null 2>&1; then
    rg -n -e 'Color\(0x' --glob '*.kt' --glob '*.kts' "$ROOT" 2>/dev/null
  else
    grep -R -n -E -e 'Color\(0x' --include='*.kt' --include='*.kts' "$ROOT" 2>/dev/null
  fi
}

relpath() {
  case "$1" in
    "$ROOT"/*) printf '%s\n' "${1#$ROOT/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

fail=0
while IFS= read -r hit; do
  path="${hit%%:*}"
  rest="${hit#*:}"
  num="${rest%%:*}"
  rel="$(relpath "$path")"
  composekit_skip_path "$rel" && continue
  case "$rel" in
    .git/*|*/.git/*) continue ;;
  esac
  allowed=0
  for dd in $DESIGN_SYSTEM_DIRS; do
    case "$rel" in
      "$dd"/*) allowed=1 ;;
    esac
  done
  if [ "$allowed" -eq 1 ]; then continue; fi
  printf '%s:%s: hardcoded Color(0x...) outside the design-system module; use theme tokens\n' "$rel" "$num"
  fail=1
done < <(search_kt)
[ $fail -ne 0 ] && exit 1
exit 0
