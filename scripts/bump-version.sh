#!/usr/bin/env bash
set -euo pipefail

# Release-cycle version bumper for sysm
# Updates VERSION using GENERATION.YY.QUARTER.REVISION.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="${PROJECT_ROOT}/VERSION"

usage() {
    cat <<EOF
Usage: $(basename "$0") <revision|VERSION>

Bump or set the release-cycle version in VERSION.

Arguments:
  revision    Increment the revision field
  VERSION     Set GENERATION.YY.QUARTER.REVISION explicitly

Examples:
  $(basename "$0") revision  # 1.26.3.0 -> 1.26.3.1
  $(basename "$0") 1.26.4.0 # Start the Q4 2026 release cycle
EOF
    exit 1
}

if [[ $# -ne 1 ]]; then
    usage
fi

if [[ ! -f "$VERSION_FILE" ]]; then
    echo "Error: VERSION file not found at $VERSION_FILE" >&2
    exit 1
fi

current=$(cat "$VERSION_FILE" | tr -d '[:space:]')

case "$1" in
    revision)
        "$SCRIPT_DIR/validate-version.sh" "$current"
        if [[ ! "$current" =~ ^([1-9][0-9]*)\.([0-9][0-9])\.([1-4])\.(0|[1-9][0-9]*)$ ]]; then
            echo "Error: Could not parse current release-cycle version: $current" >&2
            exit 1
        fi
        new_version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}.$((BASH_REMATCH[4] + 1))"
        ;;
    [0-9]*.[0-9]*.[0-9]*.[0-9]*)
        "$SCRIPT_DIR/validate-version.sh" "$1"
        new_version="$1"
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Error: Invalid argument: $1" >&2
        echo "Use 'revision' or specify a version like '1.26.3.0'" >&2
        exit 1
        ;;
esac

echo "$new_version" > "$VERSION_FILE"
echo "Release-cycle version updated: $current -> $new_version"
echo "VERSION file updated: $VERSION_FILE"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff VERSION"
echo "  2. Build and test: ./scripts/release.sh test"
echo "  3. Commit: git add VERSION && git commit -m 'SYSM-###: release $new_version'"
echo "  4. Tag: git tag v$new_version"
echo "  5. Push: git push && git push --tags"
