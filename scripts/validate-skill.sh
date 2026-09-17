#!/usr/bin/env bash
set -euo pipefail

# Fails when the committed skills/sysm.skill no longer matches its source tree,
# or when it documents a version other than VERSION.
#
# The bundle went fourteen releases without a rebuild, still describing v1.12.0,
# because nothing checked it. This runs in CI so that cannot happen quietly.
#
# Usage: ./scripts/validate-skill.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="${PROJECT_ROOT}/skills/sysm"
BUNDLE="${PROJECT_ROOT}/skills/sysm.skill"

for path in "$SOURCE_DIR" "$BUNDLE"; do
    if [[ ! -e "$path" ]]; then
        echo "Error: missing $path" >&2
        exit 1
    fi
done

VERSION=$(tr -d '[:space:]' < "${PROJECT_ROOT}/VERSION")

if ! grep -qF "(v${VERSION})" "${SOURCE_DIR}/SKILL.md"; then
    echo "Error: skills/sysm/SKILL.md does not document version ${VERSION}" >&2
    echo "Run ./scripts/build-skill.sh and commit the result." >&2
    exit 1
fi

extracted=$(mktemp -d)
trap 'rm -rf "$extracted"' EXIT
unzip -q -o "$BUNDLE" -d "$extracted"

if ! diff -ru "$SOURCE_DIR" "${extracted}/sysm"; then
    echo >&2
    echo "Error: skills/sysm.skill does not match skills/sysm/." >&2
    echo "Run ./scripts/build-skill.sh and commit the rebuilt bundle." >&2
    exit 1
fi

echo "Bundled skill matches its source and documents ${VERSION}"
