#!/usr/bin/env bash
# Check every *Contract.kt holds exactly UiState, UiAction and UiEffect
# (arch rule 4: three top-level declarations; UiModels and mappers live
# in presentation/<destination>/model/ and mapper/).
#
# macOS bash 3.2 and Linux safe: no assoc arrays, mapfile, read -d,
# [[ =~ ]] or sed -i. No network; no writes. Usage: script <project-root>
set -u

if [ $# -ne 1 ]; then
  echo "usage: check-contract-shape.sh <project-root>" >&2
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

if [ -f "$ROOT/.composekit.conf" ]; then
  . "$ROOT/.composekit.conf"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/composekit-skip.sh" ]; then
  . "$SCRIPT_DIR/lib/composekit-skip.sh"
fi

if command -v rg >/dev/null 2>&1; then
  HAVE_RG=1
else
  HAVE_RG=0
fi

DECL_RE='^((public|internal|private) )?(class |data class |sealed interface |sealed class |interface |object |data object |enum class |typealias |const val |val |fun )'
STRIP_RE='s/^((public|internal|private) )?(class |data class |sealed interface |sealed class |interface |object |data object |enum class |typealias |const val |val |fun )//'

status=0

while IFS= read -r file; do
  case "$file" in
    */.git/*) continue ;;
  esac
  rel="${file#$ROOT/}"
  composekit_skip_path "$rel" && continue
  if [ "$HAVE_RG" -eq 1 ]; then
    matches="$(rg -n -e "$DECL_RE" -- "$file" 2>/dev/null)"
  else
    matches="$(grep -E -n -e "$DECL_RE" -- "$file" 2>/dev/null)"
  fi
  count=0
  names=""
  flat=""
  extra_line=""
  while IFS= read -r mline; do
    case "$mline" in
      "") continue ;;
    esac
    lineno="${mline%%:*}"
    text="${mline#*:}"
    name="$(printf '%s' "$text" | sed -E -e "$STRIP_RE" -e 's/^<[^>]*> *//' -e 's/[^A-Za-z0-9_].*$//')"
    count=$((count + 1))
    case "$names" in
      "") names="$name" ;;
      *) names="$names, $name" ;;
    esac
    flat="$flat $name"
    if [ $count -eq 4 ]; then
      extra_line="$lineno"
    fi
  done <<< "$matches"
  if [ $count -ne 3 ]; then
    case "$extra_line" in
      "") line=1 ;;
      *) line="$extra_line" ;;
    esac
    printf '%s\n' "$rel:$line: Contract must declare exactly UiState, UiAction and UiEffect (found $count: $names)"
    status=1
  else
    nstate=0
    naction=0
    neffect=0
    for n in $flat; do
      case "$n" in
        *UiState) nstate=$((nstate + 1)) ;;
      esac
      case "$n" in
        *UiAction) naction=$((naction + 1)) ;;
      esac
      case "$n" in
        *UiEffect) neffect=$((neffect + 1)) ;;
      esac
    done
    if [ $nstate -ne 1 ] || [ $naction -ne 1 ] || [ $neffect -ne 1 ]; then
      printf '%s\n' "$rel:1: Contract must declare exactly UiState, UiAction and UiEffect (found: $names)"
      status=1
    fi
  fi
done < <(find "$ROOT" -type f -name '*Contract.kt' -print)

exit $status
