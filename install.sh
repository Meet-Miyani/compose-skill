#!/usr/bin/env bash
set -euo pipefail

REPO="${COMPOSEKIT_REPO:-Meet-Miyani/composekit}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
BINARY="composekit"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"

case "$os" in
  darwin) os="darwin" ;;
  linux) os="linux" ;;
  *) echo "Unsupported OS: $os"; exit 1 ;;
esac

case "$arch" in
  x86_64|amd64) arch="amd64" ;;
  arm64|aarch64) arch="arm64" ;;
  *) echo "Unsupported architecture: $arch"; exit 1 ;;
esac

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

api="https://api.github.com/repos/${REPO}/releases/latest"
release_json="$tmp/release.json"

curl -fsSL "$api" -o "$release_json"

asset_url="$(grep -o '"browser_download_url": "[^"]*"' "$release_json" \
  | cut -d'"' -f4 \
  | grep "${os}_${arch}" \
  | head -n 1)"

checksums_url="$(grep -o '"browser_download_url": "[^"]*"' "$release_json" \
  | cut -d'"' -f4 \
  | grep 'checksums.txt' \
  | head -n 1)"

if [ -z "${asset_url:-}" ]; then
  echo "Could not find release asset for ${os}_${arch}"
  exit 1
fi

if [ -z "${checksums_url:-}" ]; then
  echo "Could not find checksums.txt"
  exit 1
fi

archive="$tmp/archive"
checksums="$tmp/checksums.txt"

curl -fsSL "$asset_url" -o "$archive"
curl -fsSL "$checksums_url" -o "$checksums"

archive_name="$(basename "$asset_url")"
if command -v sha256sum >/dev/null 2>&1; then
  sha_cmd="sha256sum"
else
  sha_cmd="shasum -a 256"
fi
actual_sha="$($sha_cmd "$archive" | awk '{print $1}')"
expected_sha="$(grep "$archive_name" "$checksums" | awk '{print $1}')"

if [ "$actual_sha" != "$expected_sha" ]; then
  echo "Checksum verification failed"
  echo "expected: $expected_sha"
  echo "actual:   $actual_sha"
  exit 1
fi

mkdir -p "$tmp/extract"
case "$archive_name" in
  *.tar.gz) tar -xzf "$archive" -C "$tmp/extract" ;;
  *.zip) unzip -q "$archive" -d "$tmp/extract" ;;
  *) echo "Unsupported archive format: $archive_name"; exit 1 ;;
esac

mkdir -p "$INSTALL_DIR"
found_binary="$(find "$tmp/extract" -type f -name "$BINARY" -perm -111 | head -n 1)"

if [ -z "${found_binary:-}" ]; then
  found_binary="$(find "$tmp/extract" -type f -name "$BINARY" | head -n 1)"
fi

if [ -z "${found_binary:-}" ]; then
  echo "Could not find $BINARY in archive"
  exit 1
fi

cp "$found_binary" "$INSTALL_DIR/$BINARY"
chmod +x "$INSTALL_DIR/$BINARY"

echo "Installed $BINARY to $INSTALL_DIR/$BINARY"

# Run init if --init flag is passed
for arg in "$@"; do
  if [ "$arg" = "--init" ]; then
    echo ""
    echo "Running composekit init..."
    "$INSTALL_DIR/$BINARY" init
    break
  fi
done

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    echo ""
    echo "Add this to your shell profile if needed:"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac
