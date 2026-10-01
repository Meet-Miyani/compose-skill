#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:-snapshot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p dist
tar -czf "dist/compose-kit-skills_${VERSION}.tar.gz" --exclude='*/_tests' --exclude='*/_tests/*' skills/
echo "Created dist/compose-kit-skills_${VERSION}.tar.gz"
