#!/usr/bin/env bash
# Test suite for the composekit guard scripts.
#
# Runs on macOS bash 3.2 and Linux: no associative arrays, no GNU-only
# flags, no sed -i. No network. Writes only inside handoff/work/scratch/.
#
# Usage (from the repo root):
#   bash skills-v2/compose-architecture/scripts/tests/run-tests.sh
#
# Asserts every check exits 0 on `fixtures/good/` and exits non-zero
# with the expected message on its own `fixtures/bad/<check>/` tree,
# then asserts the `compose-feature` scaffold fails only
# `check-placeholders` while its SEAMs are unimplemented and passes
# `run-checks.sh` once they are stripped, and that `install-guards.sh`
# installs cleanly.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(dirname "$TESTS_DIR")"
REPO_ROOT="$(cd "$TESTS_DIR/../../../.." && pwd)"
GOOD="$TESTS_DIR/fixtures/good"
BAD="$TESTS_DIR/fixtures/bad"
SCRATCH="$REPO_ROOT/handoff/work/scratch/phase5-tmp"
NEW_FEATURE="$REPO_ROOT/skills-v2/compose-feature/scripts/new-feature.sh"

echo "run-tests.sh under bash $BASH_VERSION"

pass=0
fail=0

expect_pass() {
    label="$1"; shift
    out="$("$@" 2>&1)"; st=$?
    if [ $st -eq 0 ]; then
        echo "PASS: $label"
        pass=$((pass + 1))
    else
        echo "FAIL: $label (exit $st, expected 0)"
        printf '%s\n' "$out" | sed 's/^/    /'
        fail=$((fail + 1))
    fi
}

expect_fail() {
    label="$1"; substring="$2"; shift 2
    out="$("$@" 2>&1)"; st=$?
    matched=0
    case "$out" in *"$substring"*) matched=1 ;; esac
    if [ $st -ne 0 ] && [ $matched -eq 1 ]; then
        echo "PASS: $label"
        pass=$((pass + 1))
    else
        echo "FAIL: $label (exit $st, substring-match $matched, expected non-zero + '$substring')"
        printf '%s\n' "$out" | sed 's/^/    /'
        fail=$((fail + 1))
    fi
}

check() {
    name="$1"; substring="$2"
    expect_pass "$name passes on fixtures/good" bash "$SCRIPTS_DIR/$name.sh" "$GOOD"
    expect_fail "$name fails on fixtures/bad/$name" "$substring" bash "$SCRIPTS_DIR/$name.sh" "$BAD/$name"
}

check check-layering "depends on another feature"
check check-contract-shape "exactly"
check check-packages "five feature packages"
check check-data-boundary "must be internal"
check check-error-handling "without onError"
check check-file-level-state "top-level var"
check check-nav-keys "directly"
# Placeholders root-only follows `git diff --name-only` inside a work tree,
# which is empty for these untracked fixtures, so the bad tree is scanned
# via explicit file args (the check's other mode).
expect_pass "check-placeholders passes on fixtures/good" bash "$SCRIPTS_DIR/check-placeholders.sh" "$GOOD"
expect_fail "check-placeholders fails on fixtures/bad/check-placeholders" "placeholder" bash "$SCRIPTS_DIR/check-placeholders.sh" "$BAD/check-placeholders" "$BAD/check-placeholders/feature/tags/src/commonMain/kotlin/com/example/feature/tags/presentation/tags/TagsScreen.kt"
check check-locale-parity "missing"
expect_fail "check-locale-parity names the module" "resource root feature/tags" bash "$SCRIPTS_DIR/check-locale-parity.sh" "$BAD/check-locale-parity"
expect_fail "check-locale-parity names the missing key" "tags_retry" bash "$SCRIPTS_DIR/check-locale-parity.sh" "$BAD/check-locale-parity"
# LOCALE_DIRS override still scopes the comparison: mod-a is consistent
# while the discoverable feature/broken root is not, so the override passes
# and discovery on the same tree fails.
OVR="$SCRATCH/locale-override"
mkdir -p "$OVR/mod-a" "$OVR/feature/broken/src/commonMain/composeResources"
cp -R "$GOOD/feature/tags/src/commonMain/composeResources/values" "$OVR/mod-a/values"
cp -R "$GOOD/feature/tags/src/commonMain/composeResources/values-ar" "$OVR/mod-a/values-ar"
cp -R "$BAD/check-locale-parity/feature/tags/src/commonMain/composeResources/values" "$OVR/feature/broken/src/commonMain/composeResources/values"
cp -R "$BAD/check-locale-parity/feature/tags/src/commonMain/composeResources/values-de" "$OVR/feature/broken/src/commonMain/composeResources/values-de"
printf '%s\n' 'LOCALE_DIRS="mod-a/values mod-a/values-ar"' > "$OVR/.composekit.conf"
expect_pass "check-locale-parity honors the LOCALE_DIRS override" bash "$SCRIPTS_DIR/check-locale-parity.sh" "$OVR"
printf '%s\n' 'LOCALE_DIRS=""' > "$OVR/.composekit.conf"
expect_fail "check-locale-parity discovers the broken root without the override" "missing" bash "$SCRIPTS_DIR/check-locale-parity.sh" "$OVR"
check check-hardcoded-colors "outside the design-system"

# The compose-feature scaffold (Tags/Tag) ships SEAM markers: a fresh
# scaffold fails only check-placeholders, and passes the full registry
# once the SEAM lines are implemented (stripped here).
rm -rf "$SCRATCH"
mkdir -p "$SCRATCH/scaffold"
expect_pass "new-feature.sh scaffolds Tags/Tag" bash "$NEW_FEATURE" --name Tags --item Tag --package com.example.feature.tags --root "$SCRATCH/scaffold"
cp "$GOOD/.composekit.conf" "$SCRATCH/scaffold/.composekit.conf"
for check in check-layering check-contract-shape check-packages check-data-boundary check-error-handling check-file-level-state check-nav-keys check-locale-parity check-hardcoded-colors; do
    expect_pass "$check passes on the fresh scaffold" bash "$SCRIPTS_DIR/$check.sh" "$SCRATCH/scaffold"
done
# Root-only placeholders follows `git diff --name-only` inside a work tree,
# which is empty for this untracked scaffold, so the scaffold is scanned
# via explicit file args (the check's other mode, as for the bad fixture).
SCAFFOLD_FILES="$(find "$SCRATCH/scaffold" -type f \( -name '*.kt' -o -name '*.kts' -o -name '*.xml' \) -print | sort)"
expect_fail "check-placeholders fails on the fresh scaffold (SEAMs)" "SEAM" bash "$SCRIPTS_DIR/check-placeholders.sh" "$SCRATCH/scaffold" $SCAFFOLD_FILES
find "$SCRATCH/scaffold" -type f -name '*.kt' -print | while IFS= read -r f; do
    if grep -q SEAM "$f" 2>/dev/null; then
        grep -v SEAM "$f" > "$f.noseam" && mv "$f.noseam" "$f"
    fi
done
expect_pass "run-checks.sh passes on the scaffold once SEAMs are implemented" bash "$SCRIPTS_DIR/run-checks.sh" "$SCRATCH/scaffold"
SCAFFOLD_FILES="$(find "$SCRATCH/scaffold" -type f \( -name '*.kt' -o -name '*.kts' -o -name '*.xml' \) -print | sort)"
expect_pass "check-placeholders passes on the scaffold once SEAMs are implemented" bash "$SCRIPTS_DIR/check-placeholders.sh" "$SCRATCH/scaffold" $SCAFFOLD_FILES

# install-guards.sh installs scripts plus a fresh conf into a project.
mkdir -p "$SCRATCH/installed"
expect_pass "install-guards.sh installs into a project dir" bash "$SCRIPTS_DIR/install-guards.sh" "$SCRATCH/installed"
if [ -f "$SCRATCH/installed/scripts/composekit/run-checks.sh" ] && [ -f "$SCRATCH/installed/.composekit.conf" ]; then
    echo "PASS: installed tree holds run-checks.sh and .composekit.conf"
    pass=$((pass + 1))
else
    echo "FAIL: installed tree is missing run-checks.sh or .composekit.conf"
    fail=$((fail + 1))
fi

rm -rf "$SCRATCH"

echo ""
echo "$pass passed, $fail failed"
if [ $fail -ne 0 ]; then exit 1; fi
exit 0
