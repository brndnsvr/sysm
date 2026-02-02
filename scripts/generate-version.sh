#!/usr/bin/env bash
set -euo pipefail

# Generates Sources/sysm/Version.swift from VERSION file
# Called automatically by release script before builds

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="${PROJECT_ROOT}/VERSION"
OUTPUT_FILE="${PROJECT_ROOT}/Sources/sysm/Version.swift"

if [[ ! -f "$VERSION_FILE" ]]; then
    echo "Error: VERSION file not found at $VERSION_FILE" >&2
    exit 1
fi

VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')

if [[ -z "$VERSION" ]]; then
    echo "Error: VERSION file is empty" >&2
    exit 1
fi

cat > "$OUTPUT_FILE" <<EOF
// This file is auto-generated from VERSION by scripts/generate-version.sh
// Do not edit directly - edit VERSION file instead

let appVersion = "$VERSION"
EOF

echo "Generated $OUTPUT_FILE with version $VERSION"
