#!/usr/bin/env bash
set -euo pipefail

# Builds skills/sysm.skill from the reviewable source tree in skills/sysm/.
#
# The bundle ships with every release and the Homebrew formula tells users to
# unzip it into ~/.claude/skills, so it has to describe the version it ships
# with. The version line in SKILL.md is rewritten from VERSION here rather than
# maintained by hand, and scripts/validate-skill.sh fails the build when the
# committed bundle no longer matches this source tree.
#
# Usage: ./scripts/build-skill.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="${PROJECT_ROOT}/skills/sysm"
BUNDLE="${PROJECT_ROOT}/skills/sysm.skill"

# A fixed timestamp keeps the zip byte-identical when the content has not
# changed, so rebuilding does not churn the committed binary.
FIXED_TIMESTAMP="202001010000"

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: skill source not found: $SOURCE_DIR" >&2
    exit 1
fi

VERSION=$(tr -d '[:space:]' < "${PROJECT_ROOT}/VERSION")
"${SCRIPT_DIR}/validate-version.sh" "$VERSION"

python3 - "${SOURCE_DIR}/SKILL.md" "$VERSION" <<'PY'
import re
import sys

path, version = sys.argv[1], sys.argv[2]
with open(path) as handle:
    text = handle.read()

updated, count = re.subn(r"\(v\d+\.\d+\.\d+\.\d+\)", f"(v{version})", text, count=1)
if count != 1:
    sys.exit(f"{path} has no version marker of the form (v1.2.3.4)")

if updated != text:
    with open(path, "w") as handle:
        handle.write(updated)
    print(f"Set skill version to {version}")
PY

staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT

cp -R "$SOURCE_DIR" "${staging}/sysm"
find "${staging}/sysm" -exec touch -t "$FIXED_TIMESTAMP" {} +

rm -f "$BUNDLE"
(cd "$staging" && zip -q -r -X "$BUNDLE" sysm)

echo "Built ${BUNDLE}"
unzip -l "$BUNDLE" | tail -n 3
