#!/usr/bin/env bash
# composekit-conf.sh — the ONE shared reader for <project-root>/.composekit.conf.
#
# The conf is data, never executed: only KEY=value lines for the keys in
# composekit_load_conf below are read, and `$`, backticks, `$(...)`, `;`
# and every other piece of shell syntax are taken literally. A conf from
# an untrusted project therefore cannot run commands through a check.
#
# Accepted line forms: KEY="value", KEY='value', KEY=value (a ` #`
# starts a trailing comment), an optional `export ` prefix, CRLF line
# endings, a UTF-8 byte-order mark on the first line. Blank lines and
# `#` comments are skipped.
#
# Values are validated before use, because checks pass them to find,
# grep and sed: BASE_PACKAGE is a package name (dot-separated
# identifiers of letters, digits and `_`, none empty or starting with a
# digit); directory keys hold project-relative paths (letters, digits,
# `_`, `.`, `/`, `-`, spaces between items; no `..` segment, no leading
# `/`); UI_MODEL is `always`, `when-needed` or empty (the default). Any
# other line (no `=`, an unknown key or `KEY+=`, an unterminated quote
# such as a value split over lines, text after the closing quote, an
# invalid value) prints one warning on stderr and does not change the
# key, which keeps its value from the check's default or an earlier
# line. The loader then returns 2 and the check exits 2: a check that ran
# on values the conf did not mean could pass while covering nothing.
# Warnings never echo control bytes from the conf.
#
# Runs on macOS bash 3.2 and Linux: no arrays, no eval, no grep, no
# writes. No network.
#
# Usage from a check (installed layout keeps the same relative path,
# scripts/composekit/lib/, because install-guards.sh copies this file):
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   . "$SCRIPT_DIR/lib/composekit-conf.sh"
#   composekit_load_conf "$ROOT/.composekit.conf" || exit 2
#
# Keys absent from the conf keep the defaults the check set beforehand.

# composekit_conf_print <format> <args...>: printf to stderr with control
# and non-ASCII bytes removed, so conf text cannot drive the terminal.
composekit_conf_print() {
  local fmt=$1
  shift
  printf "$fmt" "$@" | LC_ALL=C tr -d '\000-\011\013-\037\177-\377' >&2
}

# composekit_conf_warn <file> <line number> <message>: counts the line
# in composekit_load_conf's `bad`.
composekit_conf_warn() {
  bad=$((bad + 1))
  composekit_conf_print 'warning: %s:%s: %s; line ignored\n' "$1" "$2" "$3"
}

# composekit_conf_dirs_ok <value>: 0 when every space-separated item is a
# safe project-relative path. Empty is allowed (several keys mean "auto").
composekit_conf_dirs_ok() {
  local item
  case "$1" in
    *[!A-Za-z0-9_./\ -]*) return 1 ;;
  esac
  for item in $1; do
    case "$item" in
      /*|..|../*|*/..|*/../*) return 1 ;;
    esac
  done
  return 0
}

composekit_load_conf() {
  local line key val rest q n bad
  [ -f "$1" ] || return 0
  n=0
  bad=0
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    if [ "$n" -eq 1 ]; then line=${line#$'\xef\xbb\xbf'}; fi
    line=${line%$'\r'}
    line=${line#"${line%%[![:space:]]*}"}
    case "$line" in
      export[[:space:]]*)
        line=${line#export}
        line=${line#"${line%%[![:space:]]*}"} ;;
    esac
    case "$line" in
      ''|'#'*) continue ;;
      *=*) ;;
      *) composekit_conf_warn "$1" "$n" "not a KEY=value line"; continue ;;
    esac
    key=${line%%=*}
    val=${line#*=}
    case "$val" in
      \"*|\'*)
        q=${val%"${val#?}"}
        rest=${val#?}
        case "$rest" in
          *"$q"*) ;;
          *) composekit_conf_warn "$1" "$n" "unterminated quote in $key"; continue ;;
        esac
        val=${rest%%"$q"*}
        rest=${rest#*"$q"}
        rest=${rest#"${rest%%[![:space:]]*}"}
        case "$rest" in
          ''|'#'*) ;;
          *) composekit_conf_warn "$1" "$n" "text after the closing quote in $key"; continue ;;
        esac ;;
      *)
        val=${val%%[[:space:]]#*}
        val=${val%"${val##*[![:space:]]}"} ;;
    esac
    case "$key" in
      FEATURE_DIRS|CORE_DIRS|DATA_DIRS|COMPOSITION_ROOT|DESIGN_SYSTEM_MODULE|DESIGN_SYSTEM_DIRS|LOCALE_DIRS)
        if ! composekit_conf_dirs_ok "$val"; then
          composekit_conf_warn "$1" "$n" "$key must list project-relative paths (letters, digits, _ . / -; no '..', no leading /)"
          continue
        fi ;;
      BASE_PACKAGE)
        case "$val" in
          ''|*[!A-Za-z0-9_.]*|.*|*.|*..*|[0-9]*|*.[0-9]*)
            composekit_conf_warn "$1" "$n" "BASE_PACKAGE must be a package name (dot-separated identifiers of letters, digits and _, none empty or starting with a digit)"
            continue ;;
        esac ;;
      UI_MODEL)
        case "$val" in
          ''|always|when-needed) ;;
          *) composekit_conf_warn "$1" "$n" "UI_MODEL must be always, when-needed or empty"; continue ;;
        esac ;;
      *)
        composekit_conf_warn "$1" "$n" "unknown key '$key'"
        continue ;;
    esac
    case "$key" in
      FEATURE_DIRS) FEATURE_DIRS=$val ;;
      CORE_DIRS) CORE_DIRS=$val ;;
      DATA_DIRS) DATA_DIRS=$val ;;
      COMPOSITION_ROOT) COMPOSITION_ROOT=$val ;;
      DESIGN_SYSTEM_MODULE) DESIGN_SYSTEM_MODULE=$val ;;
      DESIGN_SYSTEM_DIRS) DESIGN_SYSTEM_DIRS=$val ;;
      LOCALE_DIRS) LOCALE_DIRS=$val ;;
      BASE_PACKAGE) BASE_PACKAGE=$val ;;
      UI_MODEL) UI_MODEL=$val ;;
    esac
  done < "$1"
  if [ "$bad" -gt 0 ]; then
    composekit_conf_print 'error: %s: %s unusable line(s); fix them so the checks scan what the conf means\n' "$1" "$bad"
    return 2
  fi
  return 0
}
