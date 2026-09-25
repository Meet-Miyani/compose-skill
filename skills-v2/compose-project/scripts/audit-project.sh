#!/usr/bin/env bash
set -u
# audit-project.sh — read-only audit of a project against the kit.
#
# Prints the gap-report skeleton used by the compose-project skill
# (references/adopt-existing.md): the module list, dependency edges,
# missing convention plugins, and guard status. Exits 0 always;
# this is an audit, not a gate. No writes anywhere.
#
# Runs on macOS bash 3.2 and Linux: no associative arrays, no GNU-only
# flags, no sed -i. No network.
#
# Usage: audit-project.sh <project-root>
if [ $# -ne 1 ]; then
  echo "usage: audit-project.sh <project-root>" >&2
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

# Generated and installed trees are never audited (agentic trial T1).
# The canonical exclusion list lives in the compose-architecture helper;
# source it when present (always true inside this repo).
SKIP_HELPER="$(cd "$(dirname "$0")/../../compose-architecture/scripts" && pwd)/lib/composekit-skip.sh"
if [ -f "$SKIP_HELPER" ]; then
  . "$SKIP_HELPER"
fi

echo "== modules (from settings.gradle.kts) =="
if [ -f "$ROOT/settings.gradle.kts" ]; then
  grep -E -e '^[[:space:]]*include\(' "$ROOT/settings.gradle.kts" 2>/dev/null || echo "(no include() lines found)"
else
  echo "(no settings.gradle.kts)"
fi

echo ""
echo "== convention-plugin use (modules not applying a composekit.* plugin) =="
found=0
listing="$(find "$ROOT" -type f -name 'build.gradle.kts' -not -path '*/build/*' -not -path '*/.git/*' -print)"
if [ -n "$listing" ]; then
  OLDIFS="$IFS"
  IFS='
'
  for f in $listing; do
    rel="${f#$ROOT/}"
    if command -v composekit_skip_path >/dev/null 2>&1; then
      composekit_skip_path "$rel" && continue
    fi
    case "$rel" in
      build-logic/*) continue ;;
    esac
    if ! grep -q -E -e 'composekit\.' "$f" 2>/dev/null; then
      echo "$rel: no composekit.* plugin alias"
      found=1
    fi
  done
  IFS="$OLDIFS"
fi
[ $found -eq 0 ] && echo "(every module build file applies a composekit.* plugin)"

echo ""
echo "== dependency edges (project() references per module) =="
if [ -n "$listing" ]; then
  OLDIFS="$IFS"
  IFS='
'
  for f in $listing; do
    rel="${f#$ROOT/}"
    if command -v composekit_skip_path >/dev/null 2>&1; then
      composekit_skip_path "$rel" && continue
    fi
    case "$rel" in
      build-logic/*) continue ;;
    esac
    edges="$(grep -E -e 'projects?\.' "$f" 2>/dev/null || true)"
    if [ -n "$edges" ]; then
      printf '%s\n' "$edges" | while IFS= read -r edge; do
        printf '%s: %s\n' "$rel" "$edge"
      done
    fi
  done
  IFS="$OLDIFS"
fi

echo ""
echo "== guard status =="
if [ -f "$ROOT/.composekit.conf" ]; then
  echo ".composekit.conf: present"
else
  echo ".composekit.conf: MISSING (run install-guards.sh)"
fi
if [ -x "$ROOT/scripts/composekit/run-checks.sh" ]; then
  echo "scripts/composekit/run-checks.sh: installed"
else
  echo "scripts/composekit/run-checks.sh: MISSING (run install-guards.sh)"
fi

echo ""
echo "== gap-report skeleton =="
echo "For each finding above, record: finding | evidence (file:line) |"
echo "existing-project case (1/2/3) | incremental step (guards WARN-first, then"
echo "convention plugins, then base contract for new features). See the"
echo "compose-project skill (references/adopt-existing.md)."
exit 0
