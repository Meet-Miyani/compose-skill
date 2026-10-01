#!/bin/bash
# v5 task gate: the only accepted proof that the held-out tasks work (owner decision, 2026-09-30, option B).
# Usage: v5-verify-tasks.sh <base-project-git-dir> <tasks-dir: tasks.md, setup/, hidden/, fix/> <work-dir>
# For each task, on a fresh clone of the base:
#   1. the setup script exits 0
#   2. the setup state builds (jvmJar, assembleDebug) and every existing JVM test passes
#   3. bug fixes only: the hidden test compiles and FAILS on the setup state (a test failure, not a compile error)
#   4. bug fixes only: after `git apply fix/T<n>.patch`, the hidden test and every JVM test PASS
# Prints one line per check and "ALL 8 TASKS VERIFIED" only when every check passes. Exit 0 only then.
set -u
BASE=$(cd "$1" && pwd); TD=$(cd "$2" && pwd); WK=$3
export JAVA_HOME=${JAVA_HOME:-/Library/Java/JavaVirtualMachines/jdk-23.jdk/Contents/Home}
mkdir -p "$WK"; WK=$(cd "$WK" && pwd)
fail=0
ok()  { echo "PASS  $1"; }
bad() { echo "FAIL  $1"; fail=1; }
gradle() { ./gradlew --console=plain "$@" < /dev/null > "$LOG" 2>&1; }
field() { python3 - "$TD/tasks.md" "$1" "$2" <<'EOF'
import re, sys
t = open(sys.argv[1]).read()
m = re.search(rf"^## {sys.argv[2]}\b.*?(?=^## |\Z)", t, re.S | re.M)
f = re.search(rf"^{sys.argv[3]}:\s*(.*)$", m.group(0), re.M) if m else None
print(f.group(1).strip() if f else "")
EOF
}
for n in 1 2 3 4 5 6 7 8; do
  T=T$n; D=$WK/$T; rm -rf "$D"; git clone -q "$BASE" "$D"; cp "$BASE/local.properties" "$D/" 2>/dev/null
  cd "$D" || exit 2
  [ -n "$(field $T Prompt)" ] || bad "$T tasks.md has a Prompt"
  if ! bash "$TD/setup/$T.sh" > "$WK/$T-setup.log" 2>&1; then bad "$T setup exits 0"; continue; fi
  ok "$T setup exits 0"
  git add -A >/dev/null; git -c user.name=v -c user.email=v@v commit -qm setup
  LOG=$WK/$T-build.log
  if gradle :composeApp:jvmJar :androidApp:assembleDebug jvmTest; then ok "$T setup state builds and existing tests pass"
  else bad "$T setup state builds and existing tests pass (see $LOG)"; continue; fi
  H=$(field $T "Hidden test")
  case "$H" in none|"") continue ;; esac
  DEST=$(cat "$TD/hidden/$T/DEST"); mkdir -p "$(dirname "$DEST")"; cp "$TD/hidden/$T/Hidden${T}Test.kt" "$DEST"
  LOG=$WK/$T-hidden-before.log
  gradle jvmTest --tests "*Hidden${T}Test*"
  if grep -q "^e: .*Hidden${T}Test" "$LOG"; then bad "$T hidden test compiles"
  elif grep -q "Hidden${T}Test.*FAILED" "$LOG"; then ok "$T hidden test fails on the bug (test failure, not compile error)"
  else bad "$T hidden test fails on the bug (see $LOG)"; fi
  [ -f "$TD/fix/$T.patch" ] || { bad "$T fix/$T.patch exists"; continue; }
  if git apply "$TD/fix/$T.patch"; then ok "$T fix patch applies"; else bad "$T fix patch applies"; continue; fi
  LOG=$WK/$T-hidden-after.log
  if gradle jvmTest; then ok "$T hidden test and all JVM tests pass after the fix"
  else bad "$T hidden test and all JVM tests pass after the fix (see $LOG)"; fi
done
[ $fail -eq 0 ] && echo "ALL 8 TASKS VERIFIED" || echo "NOT VERIFIED"
exit $fail
