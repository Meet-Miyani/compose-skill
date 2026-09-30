#!/usr/bin/env bash
# Test suite for the composekit guard scripts.
#
# Runs on macOS bash 3.2 and Linux: no associative arrays, no GNU-only
# flags, no sed -i. No network. Writes only inside handoff/work/scratch/.
#
# Usage (from the repo root):
#   bash skills-v2/_tests/compose-architecture/run-tests.sh
#
# The suite lives outside the installed skill folders so shipped skills
# contain no fixtures. Guard scripts under test live in
# skills-v2/compose-architecture/scripts/.
# Asserts every check exits 0 on `fixtures/good/` and exits non-zero
# with the expected message on its own `fixtures/bad/<check>/` tree,
# then asserts the `compose-feature` scaffold fails only
# `check-placeholders` while its SEAMs are unimplemented and passes
# `run-checks.sh` once they are stripped, and that `install-guards.sh`
# installs cleanly.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/../../.." && pwd)"
SCRIPTS_DIR="$REPO_ROOT/skills-v2/compose-architecture/scripts"
GOOD="$TESTS_DIR/fixtures/good"
BAD="$TESTS_DIR/fixtures/bad"
SCRATCH="$REPO_ROOT/handoff/work/scratch/phase5-tmp"
NEW_FEATURE="$REPO_ROOT/skills-v2/compose-feature/scripts/new-feature.sh"

echo "run-tests.sh under bash $BASH_VERSION"

pass=0
fail=0

frontmatter_check() {
    file="$1" expected="$2"
    if python3 -c 'import yaml' >/dev/null 2>&1; then
        python3 - "$file" "$expected" <<'PY'
import sys, yaml
path, expected = sys.argv[1:]
try:
    parts = open(path, encoding="utf-8").read().split("---", 2)
    assert len(parts) == 3 and not parts[0].strip()
    data = yaml.safe_load(parts[1])
    assert isinstance(data, dict)
    assert data.get("name") == expected
    assert isinstance(data.get("description"), str)
    assert len(data["description"]) <= 1024
except (OSError, yaml.YAMLError, AssertionError) as exc:
    print(f"invalid frontmatter: {path}: {exc}")
    sys.exit(1)
PY
    elif command -v ruby >/dev/null 2>&1 && ruby -ryaml -e '' >/dev/null 2>&1; then
        ruby -ryaml - "$file" "$expected" <<'RUBY'
path, expected = ARGV
begin
  parts = File.read(path).split('---', 3)
  raise 'missing delimiters' unless parts.length == 3 && parts[0].strip.empty?
  data = YAML.safe_load(parts[1])
  raise 'invalid fields' unless data.is_a?(Hash) && data['name'] == expected && data['description'].is_a?(String) && data['description'].length <= 1024
rescue => e
  warn "invalid frontmatter: #{path}: #{e}"
  exit 1
end
RUBY
    else
        echo "error: frontmatter tests require python3 with PyYAML or ruby with yaml" >&2
        return 2
    fi
}

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

for skill in compose compose-architecture compose-data compose-feature compose-platform compose-project compose-ui; do
    expect_pass "$skill frontmatter parses and matches schema" frontmatter_check "$REPO_ROOT/skills-v2/$skill/SKILL.md" "$skill"
done
expect_pass "compose backticked file paths exist" python3 - "$REPO_ROOT/skills-v2/compose/SKILL.md" <<'PY'
from pathlib import Path
import re
import sys

skill = Path(sys.argv[1])
paths = re.findall(r'`(\.\./[^`]+)`', skill.read_text(encoding='utf-8'))
assert paths, 'no file paths found'
missing = [path for path in paths if not (skill.parent / path).is_file()]
assert not missing, f'missing paths: {missing}'
PY
expect_pass "compose stays within 12000 characters" python3 - "$REPO_ROOT/skills-v2/compose/SKILL.md" <<'PY'
from pathlib import Path
import sys

count = len(Path(sys.argv[1]).read_text(encoding='utf-8'))
assert count <= 12000, f'{count} characters exceeds 12000'
PY
mkdir -p "$SCRATCH/frontmatter-bad"
printf '%s\n' '---' 'name: compose-bad' 'description: invalid: unquoted colon' '---' > "$SCRATCH/frontmatter-bad/SKILL.md"
expect_fail "unquoted colon in description fails frontmatter" "invalid frontmatter" frontmatter_check "$SCRATCH/frontmatter-bad/SKILL.md" "compose-bad"

check check-layering "depends on another feature"
# Dependency guards must catch type-safe accessors as well as literal paths.
LAYERS="$SCRATCH/layer-edges"
mkdir -p "$LAYERS/feature/a" "$LAYERS/core/model"
printf '%s\n' 'implementation(projects.feature.b)' > "$LAYERS/feature/a/build.gradle.kts"
expect_fail "check-layering catches projects.feature.b" "depends on another feature" bash "$SCRIPTS_DIR/check-layering.sh" "$LAYERS"
printf '%s\n' 'implementation(projects.feature.noteDetail)' > "$LAYERS/feature/a/build.gradle.kts"
expect_fail "check-layering converts camelCase accessors" "feature/note-detail" bash "$SCRIPTS_DIR/check-layering.sh" "$LAYERS"
printf '%s\n' 'implementation(projects.data.notes)' > "$LAYERS/core/model/build.gradle.kts"
expect_fail "check-layering catches core to data" "depends on data" bash "$SCRIPTS_DIR/check-layering.sh" "$LAYERS"
check check-contract-shape "exactly"
check check-packages "five feature packages"
check check-data-boundary "must be internal"
check check-error-handling "without onError"
check check-file-level-state "top-level var"
check check-nav-keys "directly"
# Placeholders root-only mode covers the tracked diff plus untracked files
# inside a work tree. The fixtures live in the repo tree, so the bad tree
# is still scanned via explicit file args (the check's other mode) to name
# the exact file under test.
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
check check-commonmain-imports "platform import"

out="$(bash "$NEW_FEATURE" --name 2>&1)"; st=$?
if [ "$st" -eq 2 ]; then
    echo "PASS: new-feature.sh --name without value exits 2"
    pass=$((pass + 1))
else
    echo "FAIL: new-feature.sh --name without value exited $st (expected 2)"
    fail=$((fail + 1))
fi

# Untracked files count in a git work tree: an untracked file with TODO
# fails check-placeholders in root-only mode (defect #9). A fresh scaffold
# failing on its SEAMs stays the intended behaviour.
mkdir -p "$SCRATCH/untracked/feature/demo/src/commonMain/kotlin/demo"
printf '%s\n' 'FEATURE_DIRS="feature"' 'COMPOSITION_ROOT="app"' > "$SCRATCH/untracked/.composekit.conf"
printf '%s\n' 'package demo' '// TODO: implement the demo' > "$SCRATCH/untracked/feature/demo/src/commonMain/kotlin/demo/Demo.kt"
git init -q "$SCRATCH/untracked" 2>/dev/null
expect_fail "check-placeholders fails on an untracked TODO file" "TODO" bash "$SCRIPTS_DIR/check-placeholders.sh" "$SCRATCH/untracked"

# Build two scratch commits with git plumbing; never invoke git commit.
HISTORY="$SCRATCH/placeholder-history"
mkdir -p "$HISTORY/feature/demo"
git init -q "$HISTORY" 2>/dev/null
printf '%s\n' 'fun demo() = 1' > "$HISTORY/feature/demo/Demo.kt"
git -C "$HISTORY" add feature/demo/Demo.kt
tree="$(git -C "$HISTORY" write-tree)"
base="$(printf 'base\n' | git -C "$HISTORY" -c user.name=Test -c user.email=test@example.invalid commit-tree "$tree")"
git -C "$HISTORY" update-ref HEAD "$base"
printf '%s\n' '// TODO: staged' >> "$HISTORY/feature/demo/Demo.kt"
git -C "$HISTORY" add feature/demo/Demo.kt
expect_fail "check-placeholders catches staged TODO" "TODO" bash "$SCRIPTS_DIR/check-placeholders.sh" "$HISTORY"
tree="$(git -C "$HISTORY" write-tree)"
head="$(printf 'second\n' | git -C "$HISTORY" -c user.name=Test -c user.email=test@example.invalid commit-tree "$tree" -p "$base")"
git -C "$HISTORY" update-ref HEAD "$head"
expect_fail "check-placeholders catches committed TODO with --base" "TODO" bash "$SCRIPTS_DIR/check-placeholders.sh" "$HISTORY" --base "$base"
expect_fail "run-checks passes --base to placeholders" "TODO" bash "$SCRIPTS_DIR/run-checks.sh" "$HISTORY" --base "$base"

# A fresh guard install leaves untracked scripts plus wrapper files beside a
# clean source tree: the git scan skips the installed guard directory and
# non-source files, so the check passes (compile-gate r3 defect #2). A fresh
# scaffold still fails on its SEAMs, by design.
mkdir -p "$SCRATCH/cleaninstall/feature/demo/src/commonMain/kotlin/demo"
printf '%s\n' 'FEATURE_DIRS="feature"' 'COMPOSITION_ROOT="app"' > "$SCRATCH/cleaninstall/.composekit.conf"
printf '%s\n' 'package demo' 'fun hello(): String = "hi"' > "$SCRATCH/cleaninstall/feature/demo/src/commonMain/kotlin/demo/Demo.kt"
git init -q "$SCRATCH/cleaninstall" 2>/dev/null
expect_pass "install-guards.sh installs into the clean tree" bash "$SCRIPTS_DIR/install-guards.sh" "$SCRATCH/cleaninstall"
expect_pass "check-placeholders passes with untracked guard scripts and clean sources" bash "$SCRIPTS_DIR/check-placeholders.sh" "$SCRATCH/cleaninstall"

# Agentic trial T1: generated and installed trees are never scanned. Every
# violation below sits under build/ or .opencode/ (plus one .gradle-adjacent
# commonMain copy), so every check must pass on this tree. The tree is a git
# work tree with everything untracked, so check-placeholders takes its git
# branch (tracked diff plus untracked files), the mode that caught the trial.
T1="$SCRATCH/t1-skip"
mkdir -p "$T1/feature/demo/src/commonMain/kotlin/com/example/feature/demo/presentation/demo"
mkdir -p "$T1/feature/demo/build/generated/compose/resourceGenerator/kotlin/presentation/gen"
mkdir -p "$T1/feature/demo/build/generated/compose/resourceGenerator/kotlin"
mkdir -p "$T1/feature/demo/build/src/commonMain/kotlin"
mkdir -p "$T1/feature/demo/build/generated/compose/resourceGenerator/res/values"
mkdir -p "$T1/feature/demo/build/generated/compose/resourceGenerator/res/values-de"
mkdir -p "$T1/.opencode/skills/demo/fixtures/bad/src/commonMain/kotlin"
mkdir -p "$T1/.opencode/skills/demo/fixtures/bad/res/values"
mkdir -p "$T1/.opencode/skills/demo/fixtures/bad/res/values-de"
cp "$GOOD/.composekit.conf" "$T1/.composekit.conf"
printf '%s\n' 'package com.example.feature.demo.presentation.demo' 'fun demo(): String = "hi"' > "$T1/feature/demo/src/commonMain/kotlin/com/example/feature/demo/presentation/demo/DemoScreen.kt"
printf '%s\n' 'package com.example.gen' '// TODO: regenerate this file' 'import com.example.feature.other.domain.OtherThing' 'import androidx.compose.ui.graphics.Color' 'val accent = Color(0xFF000000)' > "$T1/feature/demo/build/generated/compose/resourceGenerator/kotlin/GenScreen.kt"
printf '%s\n' 'package com.example.gen.presentation' '// TODO: regenerate this file' 'var genCache = 0' 'data class GenDto(val id: Long)' > "$T1/feature/demo/build/generated/compose/resourceGenerator/kotlin/presentation/gen/GenState.kt"
printf '%s\n' 'package com.example.gen' '// TODO: regenerate this file' 'import java.util.UUID' 'val genId: UUID? = null' > "$T1/feature/demo/build/src/commonMain/kotlin/GenRes.kt"
printf '%s\n' '<resources>' '    <string name="gen_ok">ok</string>' '</resources>' > "$T1/feature/demo/build/generated/compose/resourceGenerator/res/values/strings.xml"
printf '%s\n' '<resources>' '    <string name="gen_ok">ok</string>' '    <string name="gen_extra">extra</string>' '</resources>' > "$T1/feature/demo/build/generated/compose/resourceGenerator/res/values-de/strings.xml"
printf '%s\n' 'package demo.bad' '// TODO: bad fixture copy' 'class BadContract' > "$T1/.opencode/skills/demo/fixtures/bad/BadContract.kt"
printf '%s\n' 'package demo.bad' '// TODO: bad fixture copy' 'fun load() { launchGuarded { reload() } }' > "$T1/.opencode/skills/demo/fixtures/bad/BadViewModel.kt"
printf '%s\n' 'package demo.bad' '// TODO: bad fixture copy' 'data class BadKey(val id: Long) : NavKey' > "$T1/.opencode/skills/demo/fixtures/bad/BadNavKey.kt"
printf '%s\n' 'package demo.bad' '// TODO: bad fixture copy' 'import java.util.UUID' 'val badId: UUID? = null' > "$T1/.opencode/skills/demo/fixtures/bad/src/commonMain/kotlin/BadCommon.kt"
printf '%s\n' '<resources>' '    <string name="bad_ok">ok</string>' '</resources>' > "$T1/.opencode/skills/demo/fixtures/bad/res/values/strings.xml"
printf '%s\n' '<resources>' '    <string name="bad_ok">ok</string>' '    <string name="bad_extra">extra</string>' '</resources>' > "$T1/.opencode/skills/demo/fixtures/bad/res/values-de/strings.xml"
git init -q "$T1" 2>/dev/null
for t1check in check-layering check-contract-shape check-packages check-data-boundary check-error-handling check-file-level-state check-nav-keys check-placeholders check-locale-parity check-hardcoded-colors check-commonmain-imports; do
    expect_pass "$t1check skips build/ and .opencode/ trees" bash "$SCRIPTS_DIR/$t1check.sh" "$T1"
done
expect_pass "run-checks.sh passes with only build/ and .opencode/ violations" bash "$SCRIPTS_DIR/run-checks.sh" "$T1"

# The compose-feature scaffold (Tags/Tag) ships SEAM markers: a fresh
# scaffold fails only check-placeholders, and passes the full registry
# once the SEAM lines are implemented (stripped here). M-11: both the
# default (domain model in UiState) and the --ui-model variants pass.
scaffold_case() {
    tag="$1"; dir="$2"; shift 2
    mkdir -p "$dir"
    expect_pass "new-feature.sh scaffolds Tags/Tag $tag" bash "$NEW_FEATURE" --name Tags --item Tag --package com.example.feature.tags --root "$dir" "$@"
    cp "$GOOD/.composekit.conf" "$dir/.composekit.conf"
    for check in check-layering check-contract-shape check-packages check-data-boundary check-error-handling check-file-level-state check-nav-keys check-locale-parity check-hardcoded-colors check-commonmain-imports; do
        expect_pass "$check passes on the fresh scaffold $tag" bash "$SCRIPTS_DIR/$check.sh" "$dir"
    done
    # Root-only placeholders scans the tracked diff plus untracked files
    # inside a work tree; the scaffold is scanned via explicit file args
    # (the check's other mode, as for the bad fixture) to name the tree.
    SCAFFOLD_FILES="$(find "$dir" -type f \( -name '*.kt' -o -name '*.kts' -o -name '*.xml' \) -print | sort)"
    expect_fail "check-placeholders fails on the fresh scaffold $tag (SEAMs)" "SEAM" bash "$SCRIPTS_DIR/check-placeholders.sh" "$dir" $SCAFFOLD_FILES
    find "$dir" -type f -name '*.kt' -print | while IFS= read -r f; do
        if grep -q SEAM "$f" 2>/dev/null; then
            grep -v SEAM "$f" > "$f.noseam" && mv "$f.noseam" "$f"
        fi
    done
    expect_pass "run-checks.sh passes on the scaffold $tag once SEAMs are implemented" bash "$SCRIPTS_DIR/run-checks.sh" "$dir"
    SCAFFOLD_FILES="$(find "$dir" -type f \( -name '*.kt' -o -name '*.kts' -o -name '*.xml' \) -print | sort)"
    expect_pass "check-placeholders passes on the scaffold $tag once SEAMs are implemented" bash "$SCRIPTS_DIR/check-placeholders.sh" "$dir" $SCAFFOLD_FILES
}
rm -rf "$SCRATCH"
scaffold_case "(default)" "$SCRATCH/scaffold"
scaffold_case "(--ui-model)" "$SCRATCH/scaffold-uimodel" --ui-model
# UI_MODEL=always in .composekit.conf makes --ui-model the default;
# --no-ui-model forces it off. Asserted on dry-run output (no writes).
mkdir -p "$SCRATCH/uiconf"
printf '%s\n' 'UI_MODEL="always"' > "$SCRATCH/uiconf/.composekit.conf"
out="$(bash "$NEW_FEATURE" --name Tags --item Tag --package com.example.feature.tags --root "$SCRATCH/uiconf" --dry-run 2>&1)"
case "$out" in
    *UiMapper.kt*)
        echo "PASS: UI_MODEL=always defaults to the UiModel pair"
        pass=$((pass + 1)) ;;
    *)
        echo "FAIL: UI_MODEL=always did not default to the UiModel pair"
        printf '%s\n' "$out" | sed 's/^/    /'
        fail=$((fail + 1)) ;;
esac
out="$(bash "$NEW_FEATURE" --name Tags --item Tag --package com.example.feature.tags --root "$SCRATCH/uiconf" --no-ui-model --dry-run 2>&1)"
case "$out" in
    *UiMapper.kt*)
        echo "FAIL: --no-ui-model still planned the UiModel pair"
        printf '%s\n' "$out" | sed 's/^/    /'
        fail=$((fail + 1)) ;;
    *)
        echo "PASS: --no-ui-model skips the UiModel pair"
        pass=$((pass + 1)) ;;
esac

# install-guards.sh installs scripts plus a fresh conf into a project.
mkdir -p "$SCRATCH/installed"
expect_pass "install-guards.sh installs into a project dir" bash "$SCRIPTS_DIR/install-guards.sh" "$SCRATCH/installed"
if [ -f "$SCRATCH/installed/scripts/composekit/run-checks.sh" ] && [ -f "$SCRATCH/installed/.composekit.conf" ] && [ -f "$SCRATCH/installed/scripts/composekit/lib/composekit-skip.sh" ]; then
    echo "PASS: installed tree holds run-checks.sh, .composekit.conf and lib/composekit-skip.sh"
    pass=$((pass + 1))
else
    echo "FAIL: installed tree is missing run-checks.sh, .composekit.conf or lib/composekit-skip.sh"
    fail=$((fail + 1))
fi

rm -rf "$SCRATCH"

echo ""
echo "$pass passed, $fail failed"
if [ $fail -ne 0 ]; then exit 1; fi
exit 0
