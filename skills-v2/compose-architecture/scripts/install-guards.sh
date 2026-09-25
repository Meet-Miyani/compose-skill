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
echo "See the compose-project skill (references/enforcement.md) for the full hook wiring."
