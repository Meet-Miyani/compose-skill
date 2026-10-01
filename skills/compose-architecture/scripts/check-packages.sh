#!/usr/bin/env bash
# Check that feature Kotlin files live only in the five feature packages.
#
# Arch rule 11: a feature holds exactly data/, domain/, presentation/,
# navigation/ and di/ — nothing else (no util/, common/, ui/ roots).
# Every *.kt file under FEATURE_DIRS must contain one of those five as
# a path segment; anything else violates.
#
# Runs on macOS bash 3.2 and Linux: no associative arrays, no GNU-only
# flags, no sed -i. No network; no writes anywhere.
#
# Usage:
#   check-packages.sh <project-root>
set -u

if [ $# -ne 1 ]; then
  echo "usage: check-packages.sh <project-root>" >&2
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

violations=""
for fdir in $FEATURE_DIRS; do
  if [ ! -d "$ROOT/$fdir" ]; then continue; fi
  listing="$(find "$ROOT/$fdir" -type f -name '*.kt' -print)"
  if [ -z "$listing" ]; then continue; fi
  OLDIFS="$IFS"
  IFS='
'
  for f in $listing; do
    IFS="$OLDIFS"
    rel="${f#$ROOT/}"
    composekit_skip_path "$rel" && continue
    # Test source sets (commonTest, androidUnitTest, jvmTest, iosTest, ...)
    # are not bound by the five-package rule: fakes live at the feature
    # root package on purpose.
    case "$rel" in
      */src/*Test*/*) continue ;;
    esac
    case "/$rel/" in
      */data/*|*/domain/*|*/presentation/*|*/navigation/*|*/di/*)
        ;;
      *)
        violations="$violations$rel:1: file outside the five feature packages (data, domain, presentation, navigation, di)
"
        ;;
    esac
  done
  IFS="$OLDIFS"
done

if [ -n "$violations" ]; then
  printf '%s' "$violations"
  exit 1
fi
exit 0
