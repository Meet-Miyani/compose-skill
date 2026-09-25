#!/usr/bin/env bash
set -u
# check-commonmain-imports.sh — shared code stays platform-free.
#
# Arch rule (compose-ui rule 11, enforced here): files under any
# src/commonMain/ directory never import java.*, javax.*, android.*,
# LocalContext, or an Android R class. Time is kotlin.time.Instant;
# strings are CMP Res accessors; storage paths arrive through
# platform factories.
#
# macOS bash 3.2 + Linux; BSD grep compatible (no ripgrep needed).
# No network; no writes. Exits 0 clean, 1 violation, 2 usage.
# Usage: check-commonmain-imports.sh <project-root>
if [ $# -ne 1 ]; then
  echo "usage: check-commonmain-imports.sh <project-root>" >&2
  exit 2
fi
ROOT="$1"
if [ ! -d "$ROOT" ]; then
  echo "error: not a directory: $ROOT" >&2
  exit 2
fi
case "$ROOT" in
  */) ROOT="${ROOT%/}" ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/composekit-skip.sh" ]; then
  . "$SCRIPT_DIR/lib/composekit-skip.sh"
fi

fail=0
listing="$(find "$ROOT" -type d -name commonMain -path '*/src/*' -print)"
if [ -z "$listing" ]; then exit 0; fi
OLDIFS="$IFS"
IFS='
'
for dir in $listing; do
  drel="${dir#$ROOT/}"
  composekit_skip_path "$drel" && continue
  files="$(find "$dir" -type f -name '*.kt' -print)"
  if [ -z "$files" ]; then continue; fi
  for f in $files; do
    rel="${f#$ROOT/}"
    composekit_skip_path "$rel" && continue
    case "$rel" in
      .git/*|*/.git/*) continue ;;
    esac
    hits="$(grep -n -E -e '^import java\.' -e '^import javax\.' -e '^import android\.' -e '^import .*LocalContext' -e '^import .*\<R\>' "$f" 2>/dev/null | grep -v -E -e '^[0-9]+:[[:space:]]*//' -e '^[0-9]+:[[:space:]]*/?\*' )"
    if [ -n "$hits" ]; then
      printf '%s\n' "$hits" | while IFS= read -r hit; do
        printf '%s:%s: platform import in commonMain; use the multiplatform equivalent\n' "$rel" "$hit"
      done
      fail=1
    fi
  done
done
IFS="$OLDIFS"
[ $fail -ne 0 ] && exit 1
exit 0
