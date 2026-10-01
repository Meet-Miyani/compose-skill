#!/usr/bin/env bash
# Install the composekit guard scripts into a project.
#
# Runs on macOS bash 3.2 and Linux: no associative arrays, no GNU-only
# flags, no sed -i. No network. Writes only inside <project-root>.
#
# Usage:
#   install-guards.sh <project-root>
#
# Copies the check scripts to `<root>/scripts/composekit/`, writes
# `.composekit.conf` from the example when the project has none, and
# prints the CI snippet plus agent-hook snippets (the full hook content
# lives in the `compose-project` skill, `references/enforcement.md`).
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="${1:-}"
if [ -z "$ROOT" ]; then echo "usage: install-guards.sh <project-root>" >&2; exit 2; fi
if [ ! -d "$ROOT" ]; then echo "error: not a directory: $ROOT" >&2; exit 2; fi

DEST="$ROOT/scripts/composekit"
mkdir -p "$DEST"

count=0
for src in "$SCRIPT_DIR"/check-*.sh "$SCRIPT_DIR"/run-checks.sh; do
    [ -f "$src" ] || continue
    cp "$src" "$DEST/"
    count=$((count + 1))
done

if [ -d "$SCRIPT_DIR/lib" ]; then
    mkdir -p "$DEST/lib"
    for lib in "$SCRIPT_DIR"/lib/*.sh; do
        [ -f "$lib" ] || continue
        cp "$lib" "$DEST/lib/"
    done
    echo "installed shared guard helpers to scripts/composekit/lib/"
fi

if [ -f "$ROOT/.composekit.conf" ]; then
    echo "kept existing .composekit.conf (not overwritten)"
else
    cp "$SCRIPT_DIR/composekit.conf.example" "$ROOT/.composekit.conf"
    echo "wrote .composekit.conf from the example; adjust it to the project"
fi

echo "installed $count scripts to scripts/composekit/"
echo ""
echo "CI snippet (GitHub Actions):"
echo "  - name: composekit guards"
echo "    run: bash scripts/composekit/run-checks.sh ."
echo ""
echo "Agent hook snippets (run before finishing a Compose change):"
echo "  Claude Code / OpenCode / Cursor: bash scripts/composekit/run-checks.sh ."
echo ""
echo "Kit activation (the compose-project skill owns this; a request to wire hooks is consent):"
echo "  1. Add one line to the project's AGENTS.md / CLAUDE.md:"
echo "     Compose/CMP work: load the compose skill first; it picks the path and the files to read."
echo "  2. Optional Claude Code SessionStart hook that injects the compose"
echo "     entry pointer; see the compose-project skill (references/enforcement.md)"
echo "     for the exact snippet. A user's request to wire CI or agent hooks is consent:"
echo "     install them, then show exactly what was written. Unprompted, print the"
echo "     snippet and write nothing the user did not ask for."
