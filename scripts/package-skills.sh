#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-snapshot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

mkdir -p dist

tar -czf "dist/composekit-skills_${VERSION}.tar.gz" \
  skills/compose/ \
  catalog/skills.json

echo "Created dist/composekit-skills_${VERSION}.tar.gz"
