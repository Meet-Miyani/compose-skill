#!/usr/bin/env bash
# check-locale-parity.sh — identical string keys across each resource root's locales.
# macOS bash 3.2 and Linux. No network; no writes. Usage: check-locale-parity.sh <project-root>
# Reads <project-root>/.composekit.conf when present. Prints <path>:<line>: <message>.
# Exits 0 clean, 1 violation, 2 usage.
#
# Two modes. LOCALE_DIRS set: compare exactly those locale directories
# (each holds one locale's strings.xml), the explicit override. LOCALE_DIRS
# empty: discover every resource root automatically — each
# src/*/composeResources and Android src/*/res directory holding
# values*/strings.xml — and compare string keys across that root's locales
# only. Two modules with different key sets pass when each module is
# internally consistent.
set -u

ROOT="${1:-}"
if [ $# -ne 1 ] || [ -z "$ROOT" ]; then echo "usage: check-locale-parity.sh <project-root>" >&2; exit 2; fi
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

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT INT TERM

# Compare one set of locale directories (project-relative, space-separated
# in "$@" after the root label in $1). Reports the missing key together
# with the locale directory and the resource root it belongs to.
compare_dirs() {
  root_label="$1"
  shift
  rm -f "$TMP"/raw_* "$TMP"/keys_*
  count=0
  existing=""
  for d in "$@"; do
    if [ ! -d "$ROOT/$d" ]; then continue; fi
    count=$((count + 1))
    n="$count"
    first=""
    : > "$TMP/raw_$n"
    for f in "$ROOT/$d"/*.xml; do
      if [ ! -f "$f" ]; then continue; fi
      if [ -z "$first" ]; then first="${f#$ROOT/}"; fi
      sed -n 's/.*name="\([^"]*\)".*/\1/p' "$f" >> "$TMP/raw_$n"
    done
    LC_ALL=C sort -u "$TMP/raw_$n" > "$TMP/keys_$n"
    printf '%s' "$d" > "$TMP/dir_$n"
    printf '%s' "$first" > "$TMP/first_$n"
    existing="$existing $n"
  done

  if [ "$count" -eq 0 ]; then return 0; fi
  LC_ALL=C sort -u "$TMP"/keys_* > "$TMP/union"

  while IFS= read -r key || [ -n "$key" ]; do
    if [ -z "$key" ]; then continue; fi
    for n in $existing; do
      if grep -F -x -e "$key" "$TMP/keys_$n" >/dev/null 2>&1; then continue; fi
      d="$(cat "$TMP/dir_$n")"
      first="$(cat "$TMP/first_$n")"
      present=""
      for m in $existing; do
        if [ "$m" = "$n" ]; then continue; fi
        if grep -F -x -e "$key" "$TMP/keys_$m" >/dev/null 2>&1; then
          present="$(cat "$TMP/dir_$m")"
          break
        fi
      done
      if [ -n "$first" ]; then
        report "$first" "1" "string key \"$key\" missing in $d (resource root $root_label; present in $present)"
      else
        report "$d" "0" "string key \"$key\" missing in $d (resource root $root_label; present in $present)"
      fi
    done
  done < "$TMP/union"
}

# Explicit override: compare exactly the configured locale directories.
if [ -n "$LOCALE_DIRS" ]; then
  compare_dirs "LOCALE_DIRS" $LOCALE_DIRS
  exit "$fail"
fi

# Discovery: every src/*/composeResources or src/*/res directory holding
# values*/strings.xml is a resource root; compare each root's locales only.
strings_list="$(find "$ROOT" -path '*/.git/*' -prune -o -type f -name 'strings.xml' -print 2>/dev/null | sort)"
roots=""
while IFS= read -r f || [ -n "$f" ]; do
  [ -n "$f" ] || continue
  srel="${f#$ROOT/}"
  composekit_skip_path "$srel" && continue
  locdir="$(dirname "$f")"
  case "$(basename "$locdir")" in
    values*) ;;
    *) continue ;;
  esac
  parent="$(dirname "$locdir")"
  case "$(basename "$parent")" in
    composeResources|res) ;;
    *) continue ;;
  esac
  rel="${parent#$ROOT/}"
  case " $roots " in
    *" $rel "*) ;;
    *) roots="$roots $rel" ;;
  esac
done <<< "$strings_list"

for root in $roots; do
  dirs=""
  while IFS= read -r f || [ -n "$f" ]; do
    [ -n "$f" ] || continue
    srel="${f#$ROOT/}"
    composekit_skip_path "$srel" && continue
    locdir="$(dirname "$f")"
    case "$(basename "$locdir")" in
      values*) ;;
      *) continue ;;
    esac
    parent="$(dirname "$locdir")"
    case "$(basename "$parent")" in
      composeResources|res) ;;
      *) continue ;;
    esac
    if [ "${parent#$ROOT/}" = "$root" ]; then
      rel_loc="${locdir#$ROOT/}"
      case " $dirs " in
        *" $rel_loc "*) ;;
        *) dirs="$dirs $rel_loc" ;;
      esac
    fi
  done <<< "$strings_list"
  [ -n "$dirs" ] || continue
  compare_dirs "$root" $dirs
done

exit "$fail"
