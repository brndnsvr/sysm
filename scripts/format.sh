#!/bin/bash
set -euo pipefail

echo "Running SwiftFormat..."

if ! command -v swiftformat &> /dev/null; then
    echo "Error: SwiftFormat is not installed"
    echo "Install with: brew install swiftformat"
    exit 1
fi

swiftformat .

echo "✓ SwiftFormat complete"
