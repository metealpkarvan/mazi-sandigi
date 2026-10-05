#!/bin/bash
set -euo pipefail
MAZI_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAZI_VERSION="${1:-1.0.0}"
if [[ ! "$MAZI_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'Version must use MAJOR.MINOR.PATCH.' >&2
  exit 1
fi
cd "$MAZI_ROOT"
mkdir -p dist
MAZI_STAGE="$(mktemp -d "$MAZI_ROOT/dist/staging.XXXXXX")"
trap 'rm -rf "$MAZI_STAGE"' EXIT
for MAZI_ARCH in x86_64 arm64; do
  swift build -c release -j 2 --triple "$MAZI_ARCH-apple-macosx11.0" --scratch-path ".build/$MAZI_ARCH" --product MaziSandigi
done
MAZI_INTEL="$(swift build -c release --triple x86_64-apple-macosx11.0 --scratch-path .build/x86_64 --show-bin-path)"
MAZI_ARM="$(swift build -c release --triple arm64-apple-macosx11.0 --scratch-path .build/arm64 --show-bin-path)"
MAZI_APP="$MAZI_STAGE/Mazi Sandığı.app"
mkdir -p "$MAZI_APP/Contents/MacOS" "$MAZI_APP/Contents/Resources"
lipo -create "$MAZI_INTEL/MaziSandigi" "$MAZI_ARM/MaziSandigi" -output "$MAZI_APP/Contents/MacOS/MaziSandigi"
cp Resources/Info.plist "$MAZI_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $MAZI_VERSION" "$MAZI_APP/Contents/Info.plist"
cp Resources/salon.png "$MAZI_APP/Contents/Resources/salon.png"
cp LICENSE "$MAZI_APP/Contents/Resources/LICENSE.txt"
swift scripts/make-icon.swift "$MAZI_STAGE/AppIcon.iconset"
iconutil -c icns "$MAZI_STAGE/AppIcon.iconset" -o "$MAZI_APP/Contents/Resources/AppIcon.icns"
# Ad-hoc signature verifies integrity; it is not Apple notarization or Developer ID signing.
codesign --force --sign - --timestamp=none "$MAZI_APP"
codesign --verify --strict "$MAZI_APP"
lipo "$MAZI_APP/Contents/MacOS/MaziSandigi" -verify_arch x86_64 arm64
(cd "$MAZI_STAGE" && "$MAZI_APP/Contents/MacOS/MaziSandigi" --smoke-test)
MAZI_ZIP="MaziSandigi-v$MAZI_VERSION-universal.zip"
rm -f "dist/$MAZI_ZIP"
ditto -c -k --sequesterRsrc --keepParent "$MAZI_APP" "dist/$MAZI_ZIP"
(cd dist && shasum -a 256 "$MAZI_ZIP" > SHA256SUMS.txt)
echo "Packaged: dist/$MAZI_ZIP"
lipo -archs "$MAZI_APP/Contents/MacOS/MaziSandigi"
