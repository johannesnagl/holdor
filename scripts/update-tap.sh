#!/bin/bash
set -euo pipefail

# Updates the Homebrew cask in johannesnagl/homebrew-tap for a new Holdor release.
# Requires: gh CLI authenticated, git, shasum.
#
# Usage: ./scripts/update-tap.sh <version>
# Example: ./scripts/update-tap.sh 1.4.4
#
# Assumes the release v<version> already exists on github.com/johannesnagl/holdor
# with the asset Holdor-<version>-arm64.dmg attached.

VERSION="${1:?Usage: $0 <version>  (e.g. 1.4.4)}"
DMG_NAME="Holdor-${VERSION}-arm64.dmg"
DMG_URL="https://github.com/johannesnagl/holdor/releases/download/v${VERSION}/${DMG_NAME}"

TAP_REPO="johannesnagl/homebrew-tap"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "==> Verifying release asset exists..."
if ! curl -sfIL "$DMG_URL" > /dev/null; then
    echo "ERROR: $DMG_URL not reachable. Is the release published with the DMG attached?"
    exit 1
fi

echo "==> Downloading DMG to compute SHA-256..."
DMG_PATH="$WORK_DIR/$DMG_NAME"
curl -fsSL -o "$DMG_PATH" "$DMG_URL"
SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
echo "    SHA-256: $SHA256"

echo "==> Cloning $TAP_REPO..."
gh repo clone "$TAP_REPO" "$WORK_DIR/tap" -- --quiet

CASK_FILE="$WORK_DIR/tap/Casks/holdor.rb"
if [ ! -f "$CASK_FILE" ]; then
    echo "ERROR: $CASK_FILE not found in tap"
    exit 1
fi

echo "==> Updating cask..."
# Use a | delimiter to avoid escaping SHA / version characters
sed -i '' -E \
    -e "s|^(  version )\"[^\"]+\"|\1\"${VERSION}\"|" \
    -e "s|^(  sha256 )\"[^\"]+\"|\1\"${SHA256}\"|" \
    "$CASK_FILE"

echo "--- Updated cask ---"
cat "$CASK_FILE"
echo "--------------------"

cd "$WORK_DIR/tap"
if git diff --quiet; then
    echo "==> No changes — cask already at v${VERSION} with matching SHA."
    exit 0
fi

git add Casks/holdor.rb
git commit -m "Bump holdor to v${VERSION}"
git push origin main

echo ""
echo "==> Tap updated. Users can now run:"
echo "    brew install --cask johannesnagl/tap/holdor"
