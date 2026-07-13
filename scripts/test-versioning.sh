#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

expect_valid() {
    "$SCRIPT_DIR/validate-version.sh" "$1"
}

expect_invalid() {
    if "$SCRIPT_DIR/validate-version.sh" "$1" >/dev/null 2>&1; then
        echo "Expected invalid version to fail: $1" >&2
        exit 1
    fi
}

expect_valid "1.26.3.0"
expect_valid "1.26.3.1934"
expect_valid "2.27.1.0"

expect_invalid "1.26.3"
expect_invalid "1.2026.3.0"
expect_invalid "1.26.0.0"
expect_invalid "1.26.5.0"
expect_invalid "1.26.3.01"
expect_invalid "0.26.3.0"

current_version=$(tr -d '[:space:]' < "$PROJECT_ROOT/VERSION")
expect_valid "$current_version"
release_notes="$PROJECT_ROOT/docs/releases/${current_version}.md"
if [[ ! -f "$release_notes" ]]; then
    echo "Release notes not found for current version: $release_notes" >&2
    exit 1
fi
if ! head -n 1 "$release_notes" | grep -q '^# sysm '; then
    echo "Release notes must begin with a '# sysm ' title: $release_notes" >&2
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
mkdir -p "$tmp_dir/scripts"
cp "$SCRIPT_DIR/bump-version.sh" "$SCRIPT_DIR/validate-version.sh" "$tmp_dir/scripts/"
chmod +x "$tmp_dir/scripts/bump-version.sh" "$tmp_dir/scripts/validate-version.sh"

printf '1.13.3\n' > "$tmp_dir/VERSION"
"$tmp_dir/scripts/bump-version.sh" 1.26.3.0 >/dev/null
grep -qx '1.26.3.0' "$tmp_dir/VERSION"

"$tmp_dir/scripts/bump-version.sh" revision >/dev/null
grep -qx '1.26.3.1' "$tmp_dir/VERSION"

printf 'Release-cycle version tests passed\n'
