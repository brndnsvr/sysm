#!/bin/bash
set -euo pipefail

# Generate documentation locally using Xcode's DocC
#
# Usage: ./scripts/generate-docs.sh [output-dir]
#
# Requires Xcode 15+ with DocC support

OUTPUT_DIR="${1:-./docs}"

echo "Building documentation for SysmCore..."

# Build documentation
xcodebuild docbuild \
  -scheme SysmCore \
  -derivedDataPath /tmp/sysm-docbuild \
  -destination 'generic/platform=macOS'

# Find the .doccarchive
DOCC_ARCHIVE=$(find /tmp/sysm-docbuild -type d -name "*.doccarchive" | head -n 1)

if [ -z "$DOCC_ARCHIVE" ]; then
  echo "Error: Could not find .doccarchive"
  exit 1
fi

echo "Found archive: $DOCC_ARCHIVE"

# Convert to static website
echo "Processing archive for static hosting..."
xcrun docc process-archive \
  transform-for-static-hosting "$DOCC_ARCHIVE" \
  --output-path "$OUTPUT_DIR" \
  --hosting-base-path sysm

# Create .nojekyll
touch "$OUTPUT_DIR/.nojekyll"

echo ""
echo "✓ Documentation generated at: $OUTPUT_DIR"
echo ""
echo "To preview locally:"
echo "  cd $OUTPUT_DIR && python3 -m http.server 8000"
echo "  Open: http://localhost:8000/documentation/sysmcore"
echo ""
