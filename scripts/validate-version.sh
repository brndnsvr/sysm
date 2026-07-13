#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $(basename "$0") GENERATION.YY.QUARTER.REVISION" >&2
    exit 2
}

if [[ $# -ne 1 ]]; then
    usage
fi

version="$1"
pattern='^([1-9][0-9]*)\.([0-9][0-9])\.([1-4])\.(0|[1-9][0-9]*)$'

if [[ ! "$version" =~ $pattern ]]; then
    echo "Error: Invalid release-cycle version: $version" >&2
    echo "Expected GENERATION.YY.QUARTER.REVISION (for example, 1.26.3.0)" >&2
    exit 1
fi
