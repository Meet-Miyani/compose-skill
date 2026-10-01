#!/usr/bin/env bash
# check-nav-keys.sh — arch rule 15: sealed NavKey hierarchies, registered.
# (a) No concrete class/object/interface implements bare NavKey directly;
#     it must extend the feature's sealed interface <Name>NavKey : NavKey.
#     Lines containing "sealed interface" are the sanctioned base and pass.
# (b) Every sealed interface <Name> : NavKey has a subclassesOfSealed<Name>
#     registration string in non-test Kotlin sources.
# Known limitation: single-line declaration scan only; a multi-line
#   data class X(\n...) : NavKey supertype split across lines is missed and
#   needs the bracket-aware supertypes_of form from the house script.
# bash 3.2 safe: no assoc arrays/mapfile/read -d/[[ =~ ]]/sed -i/GNU grep.
# Only grep flags used below: -n -E -e (subset of -R -n -E -e -o
# --include='*.kt'); rg preferred when available, same -n -e subset.
# Test paths are pruned in find (commonTest, test, androidTest, *Test.kt).
# No network; no writes. Usage: check-nav-keys.sh <project-root>
# Exits 0 clean, 1 violation, 2 usage.
set -u

ROOT="${1:-}"
if [ $# -ne 1 ] || [ -z "$ROOT" ]; then
  echo "usage: check-nav-keys.sh <project-root>" >&2
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

DIRECT_ERE='(class|object|interface)[^:=]*:[[:space:]]*NavKey([^A-Za-z0-9_]|$)'
SEALED_ERE='sealed[[:space:]]+interface[[:space:]]+[A-Za-z0-9_]+[^:=]*:[[:space:]]*NavKey([^A-Za-z0-9_]|$)'
DIRECT_AWK='{ pos=index($0, ":"); lineno=substr($0,1,pos-1); content=substr($0,pos+1); if (index(content, "sealed interface")>0) next; c=index(content,"class "); o=index(content,"object "); ii=index(content,"interface "); p=0; kl=0; if (c>0 && (p==0||c>p)) {p=c; kl=6} if (o>0 && (p==0||o>p)) {p=o; kl=7} if (ii>0 && (p==0||ii>p)) {p=ii; kl=10} if (p==0) next; rest=substr(content,p+kl); while (substr(rest,1,1)==" "||substr(rest,1,1)=="\t") rest=substr(rest,2); name=""; for (i=1;i<=length(rest);i++) { ch=substr(rest,i,1); if ((ch>="A"&&ch<="Z")||(ch>="a"&&ch<="z")||(ch>="0"&&ch<="9")||ch=="_") name=name ch; else break } if (name=="") name="declaration"; printf "%s:%s: %s implements NavKey directly; extend the feature sealed interface instead\n", rel, lineno, name }'
SEALED_AWK='{ pos=index($0, ":"); lineno=substr($0,1,pos-1); content=substr($0,pos+1); ip=index(content,"interface"); if (ip==0) next; rest=substr(content,ip+9); while (substr(rest,1,1)==" "||substr(rest,1,1)=="\t") rest=substr(rest,2); name=""; for (i=1;i<=length(rest);i++) { ch=substr(rest,i,1); if ((ch>="A"&&ch<="Z")||(ch>="a"&&ch<="z")||(ch>="0"&&ch<="9")||ch=="_") name=name ch; else break } if (name=="") next; printf "%s:%s:%s\n", name, rel, lineno }'

direct_out="$(find "$ROOT" -path '*/.git/*' -prune -o -path '*/commonTest/*' -prune -o -path '*/test/*' -prune -o -path '*/androidTest/*' -prune -o -name '*Test.kt' -prune -o -type f -name '*.kt' -print | sort | while IFS= read -r kt; do
  [ -n "$kt" ] || continue
  rel="${kt#$ROOT/}"
  composekit_skip_path "$rel" && continue
  if [ "$HAVE_RG" -eq 1 ]; then
    rg -n -e "$DIRECT_ERE" "$kt" 2>/dev/null | awk -v rel="$rel" "$DIRECT_AWK"
  else
    grep -n -E -e "$DIRECT_ERE" "$kt" 2>/dev/null | awk -v rel="$rel" "$DIRECT_AWK"
  fi
done)"

sealed_list="$(find "$ROOT" -path '*/.git/*' -prune -o -path '*/commonTest/*' -prune -o -path '*/test/*' -prune -o -path '*/androidTest/*' -prune -o -name '*Test.kt' -prune -o -type f -name '*.kt' -print | sort | while IFS= read -r kt; do
  [ -n "$kt" ] || continue
  rel="${kt#$ROOT/}"
  composekit_skip_path "$rel" && continue
  if [ "$HAVE_RG" -eq 1 ]; then
    rg -n -e "$SEALED_ERE" "$kt" 2>/dev/null | awk -v rel="$rel" "$SEALED_AWK"
  else
    grep -n -E -e "$SEALED_ERE" "$kt" 2>/dev/null | awk -v rel="$rel" "$SEALED_AWK"
  fi
done)"

fail=0
if [ -n "$direct_out" ]; then
  printf '%s\n' "$direct_out"
  fail=1
fi
if [ -n "$sealed_list" ]; then
  while IFS= read -r entry; do
    if [ -z "$entry" ]; then
      continue
    fi
    sname="${entry%%:*}"
    rest="${entry#*:}"
    srel="${rest%%:*}"
    slineno="${rest#*:}"
    reg_ere="subclassesOfSealed[[:space:]]*<[[:space:]]*$sname[[:space:]]*>"
    found="$(find "$ROOT" -path '*/.git/*' -prune -o -path '*/commonTest/*' -prune -o -path '*/test/*' -prune -o -path '*/androidTest/*' -prune -o -name '*Test.kt' -prune -o -type f -name '*.kt' -print | sort | while IFS= read -r kt2; do
      [ -n "$kt2" ] || continue
      krel2="${kt2#$ROOT/}"
      composekit_skip_path "$krel2" && continue
      if [ "$HAVE_RG" -eq 1 ]; then
        rg -n -e "$reg_ere" "$kt2" 2>/dev/null
      else
        grep -n -E -e "$reg_ere" "$kt2" 2>/dev/null
      fi
    done)"
    if [ -z "$found" ]; then
      printf '%s:%s: sealed NavKey hierarchy %s is never registered with subclassesOfSealed\n' "$srel" "$slineno" "$sname"
      fail=1
    fi
  done <<EOF_SEALED
$sealed_list
EOF_SEALED
fi
exit "$fail"
