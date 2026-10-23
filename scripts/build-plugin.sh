#!/usr/bin/env bash
# Build the folder that Anthropic's plugin directory installs, then check it
# against the directory's file rules.
#
# Usage: scripts/build-plugin.sh <empty-out-dir>
#
# The directory installs only the plugin folder, so the `claude-plugin`
# branch holds what the plugin needs and nothing else: the manifest and its
# icon, skills/, the listing README (.claude-plugin/README.md), LICENSE and
# NOTICE.md. Only tracked files are copied. The checks mirror the rules in
# https://claude.com/docs/plugins/pre-submission-checklist that a local run
# can see; the portal's Validate stays authoritative.
set -euo pipefail

if [ $# -ne 1 ]; then echo "usage: build-plugin.sh <empty-out-dir>" >&2; exit 2; fi
mkdir -p "$1"
OUT="$(cd "$1" && pwd)"
if [ -n "$(ls -A "$OUT")" ]; then echo "error: not empty: $OUT" >&2; exit 2; fi
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Binary files the directory holds for a reviewer, kept on purpose. Any
# other binary fails the build.
KNOWN_BINARIES="skills/compose-project/templates/project/gradle/wrapper/gradle-wrapper.jar"

SOURCES=(.claude-plugin/plugin.json .claude-plugin/icon.png skills LICENSE)
paths="$(git ls-files -- "${SOURCES[@]}" | grep -v '/_tests/' || true)"
links="$(git ls-files -s -- "${SOURCES[@]}" | awk '$1 == "120000" || $1 == "160000" { print $4 }')"

while IFS= read -r path; do
    mkdir -p "$OUT/$(dirname "$path")"
    cp -p "$path" "$OUT/$path"
done <<EOF
$paths
EOF

# Relative links would 404 on the branch, so point them at main.
for doc in .claude-plugin/README.md:README.md NOTICE.md:NOTICE.md; do
    sed -E 's#\]\(([^):#]+)\)#](https://github.com/Meet-Miyani/compose-skill/blob/main/\1)#g' \
        "${doc%%:*}" > "$OUT/${doc##*:}"
done

cd "$OUT"
fail=0
problem() { echo "FAIL: $*" >&2; fail=1; }

# Name checks read git's list, not the copy: a case-insensitive disk merges
# names that differ only by case, and cp follows symbolic links.
files="$(printf '%s\nREADME.md\nNOTICE.md\n' "$paths" | LC_ALL=C sort)"
count="$(printf '%s\n' "$files" | wc -l | tr -d ' ')"
depth="$(printf '%s\n' "$files" | awk -F/ 'NF - 1 > max { max = NF - 1 } END { print max + 0 }')"

[ "$depth" -le 16 ] || problem "a file sits $depth folders deep (limit 16)"
[ "$count" -le 512 ] || problem "$count files (limit 512)"
[ -z "$links" ] || problem "symbolic links or submodules: $links"
junk="$(printf '%s\n' "$files" | grep -E '(^|/)(\.DS_Store|Thumbs\.db|desktop\.ini|__MACOSX)(/|$)' || true)"
[ -z "$junk" ] || problem "system files: $junk"
clash="$(printf '%s\n' "$files" |
    awk -F/ '{ p = $1; print p; for (i = 2; i <= NF; i++) { p = p "/" $i; print p } }' |
    sort -u | tr 'A-Z' 'a-z' | sort | uniq -d)"
[ -z "$clash" ] || problem "names that differ only by case: $clash"
odd="$(printf '%s\n' "$files" | grep -iE ':|[. ](/|$)|(^|/)(con|prn|aux|nul|com[1-9]|lpt[1-9])(\.[^/]*)?(/|$)' || true)"
[ -z "$odd" ] || problem "names Windows can't hold: $odd"

held=""
while IFS= read -r f; do
    size="$(wc -c < "$f" | tr -d ' ')"
    case "$f" in
        *.png|*.jpg|*.jpeg|*.gif|*.webp|*.svg|*.woff|*.woff2|*.ttf|*.otf)
            [ "$size" -lt 5242880 ] || problem "$f is $size bytes (limit 5 MiB)"
            continue ;;
    esac
    [ "$size" -lt 262144 ] || problem "$f is $size bytes (limit 256 KiB)"
    if [ -s "$f" ] && ! LC_ALL=C grep -Iq '' "$f"; then
        case " $KNOWN_BINARIES " in
            *" $f "*) held="$held $f" ;;
            *) problem "binary file the directory would hold for a reviewer: $f" ;;
        esac
    fi
done <<EOF
$files
EOF

[ -f LICENSE ] || problem "LICENSE missing"
words="$(awk '/^```/ { code = !code; next } !code' README.md | wc -w | tr -d ' ')"
[ "$words" -ge 40 ] || problem "README.md has $words words outside code blocks (minimum 40)"
for skill in skills/*/; do
    name="$(basename "$skill")"
    grep -q "\`$name\`" README.md || problem "README.md does not name the $name skill"
done
icon="$(python3 -c 'import json; print(json.load(open(".claude-plugin/plugin.json"))["icon"])')"
[ -f "$icon" ] || problem "plugin.json icon not found: $icon"

if [ "$fail" -ne 0 ]; then exit 1; fi
echo "Built $OUT: $count files, deepest $depth folders"
[ -z "$held" ] || echo "Held for a reviewer by design:$held"
