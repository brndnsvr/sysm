#!/bin/bash
set -euo pipefail

echo "Running SwiftLint..."

if ! command -v swiftlint &> /dev/null; then
    echo "Error: SwiftLint is not installed"
    echo "Install with: brew install swiftlint"
    exit 1
fi

swiftlint lint --strict

echo "✓ SwiftLint passed"
