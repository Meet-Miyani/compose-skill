#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

rm -rf ./tmp-smoke
mkdir -p ./tmp-smoke/bin

go build -o ./tmp-smoke/bin/composekit .

export COMPOSEKIT_HOME="$PWD/tmp-smoke/home"
export COMPOSEKIT_CONFIG_HOME="$PWD/tmp-smoke/config"

mkdir -p "$COMPOSEKIT_HOME/.codex"
mkdir -p "$COMPOSEKIT_HOME/.cursor"
mkdir -p "$COMPOSEKIT_HOME/.claude"
mkdir -p "$COMPOSEKIT_CONFIG_HOME"

./tmp-smoke/bin/composekit version
./tmp-smoke/bin/composekit targets detect

./tmp-smoke/bin/composekit skills list
./tmp-smoke/bin/composekit skills list --long 2>&1 | head -20
./tmp-smoke/bin/composekit skills find kmp

./tmp-smoke/bin/composekit init

test -f "$COMPOSEKIT_HOME/.codex/skills/compose/SKILL.md"
test -f "$COMPOSEKIT_HOME/.cursor/skills/compose/SKILL.md"
test -f "$COMPOSEKIT_HOME/.claude/skills/compose/SKILL.md"

./tmp-smoke/bin/composekit doctor

./tmp-smoke/bin/composekit update --offline

test -f "$COMPOSEKIT_HOME/.codex/skills/compose/.composekit-manifest.json"
test -f "$COMPOSEKIT_HOME/.cursor/skills/compose/.composekit-manifest.json"
test -f "$COMPOSEKIT_HOME/.claude/skills/compose/.composekit-manifest.json"

./tmp-smoke/bin/composekit remove

test ! -d "$COMPOSEKIT_HOME/.codex/skills/compose"
test ! -d "$COMPOSEKIT_HOME/.cursor/skills/compose"
test ! -d "$COMPOSEKIT_HOME/.claude/skills/compose"

# Test --all-agents flag
mkdir -p "$COMPOSEKIT_HOME/.gemini"
./tmp-smoke/bin/composekit init --all-agents

test -f "$COMPOSEKIT_HOME/.codex/skills/compose/SKILL.md"
test -f "$COMPOSEKIT_HOME/.cursor/skills/compose/SKILL.md"
test -f "$COMPOSEKIT_HOME/.claude/skills/compose/SKILL.md"
test -f "$COMPOSEKIT_HOME/.gemini/skills/compose/SKILL.md"

./tmp-smoke/bin/composekit remove --all-agents

test ! -d "$COMPOSEKIT_HOME/.codex/skills/compose"
test ! -d "$COMPOSEKIT_HOME/.cursor/skills/compose"
test ! -d "$COMPOSEKIT_HOME/.claude/skills/compose"
test ! -d "$COMPOSEKIT_HOME/.gemini/skills/compose"

echo "smoke test passed"
