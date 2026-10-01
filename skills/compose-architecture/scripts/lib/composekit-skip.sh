#!/usr/bin/env bash
# composekit-skip.sh — the ONE shared exclusion list for every guard.
#
# Generated and installed trees are never scanned: build outputs
# (build/generated/compose/resourceGenerator/**), Gradle/Kotlin/IDE state
# (.gradle/, .kotlin/, .idea/), installed agent skills (.opencode/,
# .claude/, .agents/) and JS tooling (node_modules/) hold files the
# project did not write, so every check skips them at any depth.
#
# Runs on macOS bash 3.2 and Linux: a single case statement, no arrays,
# no grep, no writes. No network.
#
# Usage from a check (installed layout keeps the same relative path,
# scripts/composekit/lib/, because install-guards.sh copies this file):
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   if [ -f "$SCRIPT_DIR/lib/composekit-skip.sh" ]; then
#     . "$SCRIPT_DIR/lib/composekit-skip.sh"
#   fi
#   ...
#   composekit_skip_path "$rel" && continue
#
# Returns 0 (skip) when the project-relative path passes through an
# excluded directory, 1 (scan) otherwise.
composekit_skip_path() {
  case "/$1/" in
    */build/*|*/.gradle/*|*/.kotlin/*|*/.idea/*|*/.opencode/*|*/.claude/*|*/.agents/*|*/node_modules/*)
      return 0 ;;
  esac
  return 1
}
