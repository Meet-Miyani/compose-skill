#!/usr/bin/env bash
# Run every composekit guard against a project and print a summary table.
#
# Runs on macOS bash 3.2 and Linux: no associative arrays, no GNU-only
# flags, no sed -i. No network; no writes anywhere.
#
# Usage:
#   run-checks.sh <project-root> [--base <ref>]
#
# Reads `<project-root>/.composekit.conf` (each check reads it itself).
# Exits 0 when every check passes, 1 otherwise.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="${1:-}"
if [ -z "$ROOT" ]; then echo "usage: run-checks.sh <project-root> [--base <ref>]" >&2; exit 2; fi
if [ ! -d "$ROOT" ]; then echo "error: not a directory: $ROOT" >&2; exit 2; fi
BASE=""
if [ $# -gt 1 ]; then
    if [ $# -ne 3 ] || [ "$2" != "--base" ] || [ -z "$3" ] || [ "${3#--}" != "$3" ]; then
        echo "usage: run-checks.sh <project-root> [--base <ref>]" >&2; exit 2
    fi
    BASE="$3"
fi

CHECKS="check-layering check-contract-shape check-packages check-data-boundary check-error-handling check-file-level-state check-nav-keys check-placeholders check-locale-parity check-hardcoded-colors check-commonmain-imports"

pass=0
fail=0
failed_list=""
printf '%-24s %s\n' "check" "result"
for check in $CHECKS; do
    script="$SCRIPT_DIR/$check.sh"
    if [ ! -f "$script" ]; then
        printf '%-24s %s\n' "$check" "FAIL (script missing)"
        fail=$((fail + 1))
        failed_list="$failed_list $check"
        continue
    fi
    if [ "$check" = "check-placeholders" ] && [ -n "$BASE" ]; then
        output="$(bash "$script" "$ROOT" --base "$BASE" 2>&1)"
    else
        output="$(bash "$script" "$ROOT" 2>&1)"
    fi
    status=$?
    if [ $status -eq 0 ]; then
        case "$check:$output" in
            check-placeholders:*"warning: no source files scanned"*)
                printf '%-24s %s\n' "$check" "WARN (0 files)" ;;
            *) printf '%-24s %s\n' "$check" "PASS" ;;
        esac
        [ "$check" = "check-placeholders" ] && printf '%s\n' "$output" | sed 's/^/    /'
        pass=$((pass + 1))
    else
        printf '%-24s %s\n' "$check" "FAIL"
        printf '%s\n' "$output" | sed 's/^/    /'
        fail=$((fail + 1))
        failed_list="$failed_list $check"
    fi
done

printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [ $fail -ne 0 ]; then
    echo "failing checks:$failed_list" >&2
    exit 1
fi
exit 0
