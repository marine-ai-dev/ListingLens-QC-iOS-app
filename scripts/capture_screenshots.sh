#!/bin/bash
# Captures a deterministic set of named screenshots of ListingLens QC running on a
# Simulator, for later App Store screenshot composition. Uses only synthetic,
# project-generated imagery (never real/private photos) seeded into the Simulator's
# Photos library, and plain `xcrun simctl` calls (no XCUITest) so it has no build-time
# dependency beyond the app itself.
#
# Usage:
#   ./scripts/capture_screenshots.sh [device-name] [output-dir]
#
# Defaults to "iPhone 17" (the closest available substitute on this Xcode install,
# since iPhone 14 is not installed) and ./screenshots/<timestamp>/.
#
# The app must already be built for iOS Simulator, e.g.:
#   xcodebuild -project ListingLensQC.xcodeproj -scheme ListingLensQC \
#     -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug \
#     -derivedDataPath build_dd build
#
# This script drives navigation only as far as `simctl` allows deterministically
# (launch, media seeding, appearance/content-size toggles). Screens reached via
# multi-step navigation (Results, Photo Detail, Recommended Order, Settings sub-pages)
# still require a manual tap-through in Simulator between captures — this script
# pauses and prompts before each of those, rather than guessing tap coordinates.

set -euo pipefail

DEVICE_NAME="${1:-iPhone 17}"
OUT_DIR="${2:-screenshots/$(date +%Y%m%d-%H%M%S)}"
BUNDLE_ID="com.marineaidev.listinglensqc"
APP_PATH="build_dd/Build/Products/Debug-iphonesimulator/ListingLens QC.app"
FIXTURE_DIR="$(mktemp -d)"

mkdir -p "$OUT_DIR"

DEVICE_ID=$(xcrun simctl list devices | grep "$DEVICE_NAME (" | grep -oE '[0-9A-F-]{36}' | head -1)
if [ -z "$DEVICE_ID" ]; then
  echo "No simulator named '$DEVICE_NAME' found. Available iPhones:"
  xcrun simctl list devices | grep -i iphone
  exit 1
fi

echo "Using simulator: $DEVICE_NAME ($DEVICE_ID)"
xcrun simctl bootstatus "$DEVICE_ID" -b 2>/dev/null || xcrun simctl boot "$DEVICE_ID"

if [ ! -d "$APP_PATH" ]; then
  echo "App not built at '$APP_PATH'. Build it first (see script header)." >&2
  exit 1
fi

echo "Installing app..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

echo "Generating deterministic synthetic fixtures..."
python3 - "$FIXTURE_DIR" <<'PY'
import sys
from PIL import Image, ImageDraw, ImageFilter

out = sys.argv[1]
img = Image.new("RGB", (1200, 1200), (200, 180, 150))
d = ImageDraw.Draw(img)
for i in range(0, 1200, 40):
    d.line([(i, 0), (i, 1200)], fill=(120, 90, 60), width=3)
d.ellipse((300, 300, 900, 900), fill=(230, 210, 190))
img.save(f"{out}/sample_sharp.png")
img.filter(ImageFilter.GaussianBlur(8)).save(f"{out}/sample_blurred.png")
Image.new("RGB", (800, 800), (10, 8, 6)).save(f"{out}/sample_dark.png")
Image.new("RGB", (800, 800), (250, 250, 248)).save(f"{out}/sample_bright.png")
PY

for f in "$FIXTURE_DIR"/*.png; do
  xcrun simctl addmedia "$DEVICE_ID" "$f"
done

capture() {
  local name="$1"
  sleep 1
  xcrun simctl io "$DEVICE_ID" screenshot "$OUT_DIR/$name.png"
  echo "Captured $OUT_DIR/$name.png"
}

echo "Launching app..."
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"
capture "01_import"

cat <<'EOF'

The remaining screens need manual navigation in the Simulator window
(Import -> Select Photos -> pick a few seeded samples -> Results -> Photo Detail ->
Recommended Order -> Settings -> About/Privacy), since simctl cannot drive taps.
After navigating to each screen, run:

  xcrun simctl io DEVICE_ID screenshot OUT_DIR/NN_screenname.png

using the $DEVICE_ID and $OUT_DIR printed above, e.g.:
EOF
echo "  xcrun simctl io $DEVICE_ID screenshot \"$OUT_DIR/02_results.png\""

rm -rf "$FIXTURE_DIR"
