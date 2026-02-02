#!/usr/bin/env bash
set -euo pipefail

# Semantic version bumper for sysm
# Updates VERSION file with new version number

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="${PROJECT_ROOT}/VERSION"

usage() {
    cat <<EOF
Usage: $(basename "$0") <major|minor|patch|VERSION>

Bump the version number in VERSION file.

Arguments:
  major       Increment major version (X.0.0)
  minor       Increment minor version (0.X.0)
  patch       Increment patch version (0.0.X)
  VERSION     Set specific version (e.g., 1.2.3)

Examples:
  $(basename "$0") patch    # 1.0.0 -> 1.0.1
  $(basename "$0") minor    # 1.0.0 -> 1.1.0
  $(basename "$0") major    # 1.0.0 -> 2.0.0
  $(basename "$0") 2.0.0    # Set to 2.0.0
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

# Parse current version
if [[ ! "$current" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "Error: Invalid version format in VERSION file: $current" >&2
    echo "Expected format: X.Y.Z" >&2
    exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"

case "$1" in
    major)
        new_version="$((major + 1)).0.0"
        ;;
    minor)
        new_version="${major}.$((minor + 1)).0"
        ;;
    patch)
        new_version="${major}.${minor}.$((patch + 1))"
        ;;
    [0-9]*.[0-9]*.[0-9]*)
        new_version="$1"
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Error: Invalid argument: $1" >&2
        echo "Use 'major', 'minor', 'patch', or specify a version like '1.2.3'" >&2
        exit 1
        ;;
esac

echo "$new_version" > "$VERSION_FILE"
echo "Version bumped: $current -> $new_version"
echo "VERSION file updated: $VERSION_FILE"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff VERSION"
echo "  2. Build and test: ./scripts/release.sh test"
echo "  3. Commit: git add VERSION && git commit -m 'chore: bump version to $new_version'"
echo "  4. Tag: git tag v$new_version"
echo "  5. Push: git push && git push --tags"
