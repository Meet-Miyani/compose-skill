#!/usr/bin/env bash
# Run every composekit guard against a project and print a summary table.
#
# Runs on macOS bash 3.2 and Linux: no associative arrays, no GNU-only
# flags, no sed -i. No network; no writes anywhere.
#
# Usage:
#   run-checks.sh <project-root>
#
# Reads `<project-root>/.composekit.conf` (each check reads it itself).
# Exits 0 when every check passes, 1 otherwise.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="${1:-}"
if [ -z "$ROOT" ]; then echo "usage: run-checks.sh <project-root>" >&2; exit 2; fi
if [ ! -d "$ROOT" ]; then echo "error: not a directory: $ROOT" >&2; exit 2; fi

CHECKS="check-layering check-contract-shape check-packages check-data-boundary check-error-handling check-file-level-state check-nav-keys check-placeholders check-locale-parity check-hardcoded-colors"

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
    output="$(bash "$script" "$ROOT" 2>&1)"
    status=$?
    if [ $status -eq 0 ]; then
        printf '%-24s %s\n' "$check" "PASS"
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
