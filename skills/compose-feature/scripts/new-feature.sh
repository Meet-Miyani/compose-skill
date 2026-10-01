#!/usr/bin/env bash
# Scaffold a feature slice from templates/feature/ into a project module.
#
# Runs on macOS bash 3.2 and Linux: no associative arrays, no GNU-only
# flags, no sed -i. Reads templates, never edits them.
#
# Usage:
#   new-feature.sh --name <Name> --item <Item> --package <base.package> --root <project-root> \
#     [--module-dir <path>] [--ui-model] [--no-ui-model] [--dry-run]
#
# The default scaffold holds the domain model in UiState directly (ruling
# M-11: no model/ and no mapper/). --ui-model also writes the
# __Item__UiModel and __Item__UiMapper templates for a named M-11 trigger.
# UI_MODEL=always|when-needed in $root/.composekit.conf (default
# when-needed) makes --ui-model the default; --no-ui-model forces it off.
#
# Example:
#   new-feature.sh --name Notes --item Note --package com.example.feature.notes --root ~/proj
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates/feature"

usage() {
    echo "usage: new-feature.sh --name <Name> --item <Item> --package <base.package> --root <project-root> [--module-dir <path>] [--ui-model] [--no-ui-model] [--dry-run]" >&2
    echo "  --name       PascalCase feature name, e.g. Notes" >&2
    echo "  --item       PascalCase singular record name, e.g. Note" >&2
    echo "  --package    feature package root, e.g. com.example.feature.notes" >&2
    echo "  --root       project root directory (must exist)" >&2
    echo "  --module-dir module path under root (default: feature/<lower-name>)" >&2
    echo "  --ui-model   also write the UiModel + UiMapper templates (M-11 trigger)" >&2
    echo "  --no-ui-model  never write them, even when UI_MODEL=always" >&2
    echo "  --dry-run    print the planned tree and exit without writing" >&2
}

name=""
item=""
package=""
root=""
moduledir=""
uimodel="auto"
dryrun=0

while [ $# -gt 0 ]; do
    case "${1:-}" in
        --name|--item|--package|--root|--module-dir)
            case "${2:-}" in
                ""|--*) echo "error: $1 requires a value" >&2; usage; exit 2 ;;
            esac ;;
    esac
    case "${1:-}" in
        --name) name="${2:-}"; shift 2 ;;
        --item) item="${2:-}"; shift 2 ;;
        --package) package="${2:-}"; shift 2 ;;
        --root) root="${2:-}"; shift 2 ;;
        --module-dir) moduledir="${2:-}"; shift 2 ;;
        --ui-model) uimodel="yes"; shift ;;
        --no-ui-model) uimodel="no"; shift ;;
        --dry-run) dryrun=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "error: unknown flag: ${1:-}" >&2; usage; exit 2 ;;
    esac
done

[ -n "$name" ] || { echo "error: --name is required" >&2; usage; exit 2; }
[ -n "$item" ] || { echo "error: --item is required" >&2; usage; exit 2; }
[ -n "$package" ] || { echo "error: --package is required" >&2; usage; exit 2; }
[ -n "$root" ] || { echo "error: --root is required" >&2; usage; exit 2; }

printf '%s' "$name" | grep -Eq '^[A-Z][A-Za-z0-9]*$' \
    || { echo "error: --name must be PascalCase alphanumerics, got: $name" >&2; exit 2; }
printf '%s' "$item" | grep -Eq '^[A-Z][A-Za-z0-9]*$' \
    || { echo "error: --item must be PascalCase alphanumerics, got: $item" >&2; exit 2; }
printf '%s' "$package" | grep -Eq '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$' \
    || { echo "error: --package must be dotted lowercase, got: $package" >&2; exit 2; }
[ -d "$root" ] || { echo "error: --root is not a directory: $root" >&2; exit 2; }
[ -d "$TEMPLATE_DIR" ] || { echo "error: template dir missing: $TEMPLATE_DIR" >&2; exit 2; }

# Resolve the UiModel default: an explicit flag wins, else UI_MODEL from
# $root/.composekit.conf (always|when-needed, default when-needed).
if [ "$uimodel" = "auto" ]; then
    uiconf=""
    if [ -f "$root/.composekit.conf" ]; then
        uiconf="$(grep -E '^[[:space:]]*UI_MODEL=' "$root/.composekit.conf" 2>/dev/null | tail -n 1 | cut -d= -f2 | tr -d ' "')"
    fi
    if [ "$uiconf" = "always" ]; then uimodel="yes"; else uimodel="no"; fi
fi

lower="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
itemlower="$(printf '%s' "$item" | tr '[:upper:]' '[:lower:]')"
[ -n "$moduledir" ] || moduledir="feature/$lower"

case "$root" in
    *\|*) echo "error: --root must not contain '|', got: $root" >&2; exit 2 ;;
esac
case "$moduledir" in
    *\|*) echo "error: --module-dir must not contain '|', got: $moduledir" >&2; exit 2 ;;
esac

# subst <text>: replace the five placeholders on one line of text.
subst() {
    printf '%s' "$1" | sed -e "s/__Name__/$name/g" -e "s/__name__/$lower/g" -e "s/__PACKAGE__/$package/g" -e "s/__Item__/$item/g" -e "s/__item__/$itemlower/g"
}

# dest_for <template-src> <template-relative-path>: print the project-relative
# destination. Sources land under src/<source-set>/kotlin/<package-path>/ so
# the tree matches the package declarations; package-less files land at the
# module root.
dest_for() {
    src="$1"
    rel="$2"
    base="$(subst "$(basename "$rel")")"
    pkg="$(sed -n 's/^package //p' "$src" | head -n 1)"
    pkg="$(subst "$pkg")"
    if [ -z "$pkg" ]; then
        printf '%s\n' "$base"
        return
    fi
    pkgdir="$(printf '%s' "$pkg" | tr '.' '/')"
    case "$rel" in
        commonTest/*) printf '%s\n' "src/commonTest/kotlin/$pkgdir/$base" ;;
        *) printf '%s\n' "src/commonMain/kotlin/$pkgdir/$base" ;;
    esac
}

# Collect the file list first so a collision aborts before anything is written.
listfile="$(mktemp "${TMPDIR:-/tmp}/new-feature.XXXXXX")"
find "$TEMPLATE_DIR" -type f | sort > "$listfile"
planned=""
count=0
collisions=""
while IFS= read -r src; do
    rel="${src#$TEMPLATE_DIR/}"
    # M-11: the UiModel pair ships only with --ui-model (or UI_MODEL=always).
    case "$rel" in
        presentation/__name__/model/__Item__UiModel.kt|presentation/__name__/mapper/__Item__UiMapper.kt)
            if [ "$uimodel" != "yes" ]; then continue; fi ;;
    esac
    dest="$moduledir/$(dest_for "$src" "$rel")"
    planned="$planned$src|$root/$dest
"
    count=$((count + 1))
    [ -e "$root/$dest" ] && collisions="$collisions$root/$dest
"
done < "$listfile"
rm -f "$listfile"

if [ -n "$collisions" ]; then
    echo "error: refusing to overwrite existing files:" >&2
    printf '%s' "$collisions" >&2
    exit 1
fi

if [ "$dryrun" -eq 1 ]; then
    echo "dry run: would create $count files under $root/$moduledir"
    printf '%s' "$planned" | sed -e 's/^[^|]*|//' | sort
    exit 0
fi

printf '%s' "$planned" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    src="${line%%|*}"
    dest="${line#*|}"
    mkdir -p "$(dirname "$dest")"
    sed -e "s/__Name__/$name/g" -e "s/__name__/$lower/g" -e "s/__PACKAGE__/$package/g" -e "s/__Item__/$item/g" -e "s/__item__/$itemlower/g" "$src" > "$dest"
done

echo "created $count files under $root/$moduledir"
if [ "$uimodel" != "yes" ]; then
    echo "UiState holds the domain $item directly (M-11 default). Re-run with --ui-model when a trigger fires."
fi
find "$root/$moduledir" -type f | sort
echo ""
echo "next steps:"
echo "  1. implement each SEAM comment (search: rg -n SEAM $moduledir)"
echo "  2. add the module to settings.gradle.kts and .composekit.conf"
echo "  3. register its Koin module in the composition root"
echo "  4. register ${lower}NavSerializers and the entry in the composition root (see templates/feature/README.md)"
echo "  5. run the compose-feature Verification gates"
