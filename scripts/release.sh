#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# sysm release script
# =============================================================================
# Usage: ./scripts/release.sh [command] [options]
#
# Commands:
#   build       Build debug binary
#   release     Build optimized release binary
#   install     Install to ~/bin (or PREFIX)
#   test        Run test suite
#   clean       Remove build artifacts
#   version     Show current version
#   completions Generate shell completions (bash/zsh/fish)
#   package     Create distributable archive (future)
#   github      Create GitHub release (future)
#   homebrew    Update Homebrew formula (future)
#   all         Full pipeline: clean → test → release → install → completions
#
# Options:
#   --prefix PATH   Install prefix (default: ~/bin)
#   --skip-tests    Skip test suite (for systems without full Xcode)
#   --dry-run       Show what would happen without doing it
#   -h, --help      Show this help
# =============================================================================

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BINARY_NAME="sysm"
DEFAULT_PREFIX="${HOME}/bin"

# Future: fill these in when ready
GITHUB_REPO=""        # e.g., "username/sysm"
HOMEBREW_TAP=""       # e.g., "username/homebrew-tap"

# Runtime options
PREFIX="${DEFAULT_PREFIX}"
DRY_RUN=false
SKIP_TESTS=false

# Colors (if terminal supports them)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

log() {
    echo -e "${BLUE}==>${NC} ${BOLD}$*${NC}"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

die() {
    log_error "$*"
    exit 1
}

run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}

get_version() {
    local version_file="${PROJECT_ROOT}/Sources/sysm/Sysm.swift"
    if [[ ! -f "$version_file" ]]; then
        die "Version file not found: $version_file"
    fi
    grep -o 'version: "[^"]*"' "$version_file" | sed 's/version: "\(.*\)"/\1/'
}

check_swift() {
    if ! command -v swift &> /dev/null; then
        die "swift not found. Install Xcode or Swift toolchain."
    fi
}

check_project() {
    if [[ ! -f "${PROJECT_ROOT}/Package.swift" ]]; then
        die "Not in a Swift package directory. Run from project root or scripts/."
    fi
}

# -----------------------------------------------------------------------------
# Commands
# -----------------------------------------------------------------------------

cmd_build() {
    log "Building debug binary..."
    check_swift
    cd "$PROJECT_ROOT"
    run swift build
    log_success "Debug build complete"
}

cmd_release() {
    log "Building release binary..."
    check_swift
    cd "$PROJECT_ROOT"
    run swift build -c release
    log_success "Release build complete: .build/release/${BINARY_NAME}"
}

cmd_test() {
    log "Running tests..."

    # Check if tests should be skipped
    if [[ "$SKIP_TESTS" == "true" ]]; then
        log_warn "Tests skipped (--skip-tests)"
        return 0
    fi

    check_swift
    cd "$PROJECT_ROOT"

    # Check if Tests directory exists with actual test files
    if [[ ! -d "${PROJECT_ROOT}/Tests" ]] || [[ -z "$(ls -A "${PROJECT_ROOT}/Tests" 2>/dev/null)" ]]; then
        log_warn "No tests found (Tests directory empty or missing)"
        return 0
    fi

    # Check if XCTest is available (requires full Xcode, not just Command Line Tools)
    if ! xcode-select -p 2>/dev/null | grep -q "Xcode.app"; then
        log_warn "Full Xcode not detected (only Command Line Tools installed)"
        log_warn "XCTest requires full Xcode. Skipping tests."
        log_warn "To run tests, install Xcode from the App Store"
        log_warn "Or use --skip-tests to silence this warning"
        return 0
    fi

    run swift test
    log_success "Tests passed"
}

cmd_install() {
    log "Installing ${BINARY_NAME} to ${PREFIX}..."

    local binary="${PROJECT_ROOT}/.build/release/${BINARY_NAME}"
    if [[ ! -f "$binary" ]]; then
        log_warn "Release binary not found. Building first..."
        cmd_release
    fi

    run mkdir -p "$PREFIX"
    run cp "$binary" "${PREFIX}/${BINARY_NAME}"
    run chmod +x "${PREFIX}/${BINARY_NAME}"

    log_success "Installed to ${PREFIX}/${BINARY_NAME}"

    # Verify
    if [[ "$DRY_RUN" != "true" ]]; then
        local installed_version
        installed_version=$("${PREFIX}/${BINARY_NAME}" --version 2>/dev/null || echo "unknown")
        log_success "Verified: ${BINARY_NAME} ${installed_version}"
    fi
}

cmd_clean() {
    log "Cleaning build artifacts..."
    cd "$PROJECT_ROOT"
    run swift package clean
    run rm -rf .build
    log_success "Clean complete"
}

cmd_version() {
    local version
    version=$(get_version)
    echo "${BINARY_NAME} ${version}"
}

cmd_package() {
    # Future: create distributable archive
    log "Creating distribution package..."

    local version arch archive
    version=$(get_version)
    arch=$(uname -m)
    archive="${BINARY_NAME}-${version}-macos-${arch}.tar.gz"

    # Ensure release binary exists
    local binary="${PROJECT_ROOT}/.build/release/${BINARY_NAME}"
    if [[ ! -f "$binary" ]]; then
        cmd_release
    fi

    cd "$PROJECT_ROOT"
    run tar -czf "$archive" -C .build/release "${BINARY_NAME}"

    log_success "Created ${archive}"

    # Show SHA for Homebrew
    if [[ "$DRY_RUN" != "true" && -f "$archive" ]]; then
        local sha
        sha=$(shasum -a 256 "$archive" | cut -d' ' -f1)
        echo "  SHA256: ${sha}"
    fi
}

cmd_github() {
    # Future: create GitHub release
    log "Creating GitHub release..."

    if [[ -z "$GITHUB_REPO" ]]; then
        die "GITHUB_REPO not configured. Edit scripts/release.sh to set it."
    fi

    if ! command -v gh &> /dev/null; then
        die "GitHub CLI (gh) not found. Install with: brew install gh"
    fi

    local version tag
    version=$(get_version)
    tag="v${version}"

    # Create package first
    cmd_package

    local archive
    archive="${BINARY_NAME}-${version}-macos-$(uname -m).tar.gz"

    log "Creating release ${tag}..."
    run gh release create "$tag" "$archive" \
        --repo "$GITHUB_REPO" \
        --title "${BINARY_NAME} ${version}" \
        --generate-notes

    log_success "Released ${tag} to GitHub"
}

cmd_homebrew() {
    # Future: update Homebrew formula
    log "Updating Homebrew formula..."

    if [[ -z "$HOMEBREW_TAP" ]]; then
        die "HOMEBREW_TAP not configured. Edit scripts/release.sh to set it."
    fi

    log_warn "Homebrew update not yet implemented"
    log_warn "Manual steps:"
    echo "  1. Update formula with new version and SHA"
    echo "  2. Push to ${HOMEBREW_TAP}"
    echo "  3. Test with: brew install --build-from-source ${BINARY_NAME}"
}

cmd_completions() {
    log "Generating shell completions..."

    local completions_dir="${PROJECT_ROOT}/completions"
    local binary="${PROJECT_ROOT}/.build/release/${BINARY_NAME}"

    # Ensure release binary exists
    if [[ ! -f "$binary" ]]; then
        log_warn "Release binary not found. Building first..."
        cmd_release
    fi

    run mkdir -p "$completions_dir"

    # Generate for each shell
    if [[ "$DRY_RUN" != "true" ]]; then
        "$binary" --generate-completion-script bash > "${completions_dir}/${BINARY_NAME}.bash"
        "$binary" --generate-completion-script zsh > "${completions_dir}/_${BINARY_NAME}"
        "$binary" --generate-completion-script fish > "${completions_dir}/${BINARY_NAME}.fish"
    else
        echo "[dry-run] Generate bash completions to ${completions_dir}/${BINARY_NAME}.bash"
        echo "[dry-run] Generate zsh completions to ${completions_dir}/_${BINARY_NAME}"
        echo "[dry-run] Generate fish completions to ${completions_dir}/${BINARY_NAME}.fish"
    fi

    log_success "Generated completions in ${completions_dir}/"
    echo "  bash: ${BINARY_NAME}.bash"
    echo "  zsh:  _${BINARY_NAME}"
    echo "  fish: ${BINARY_NAME}.fish"
    echo ""
    echo "Installation:"
    echo "  bash: source ${completions_dir}/${BINARY_NAME}.bash"
    echo "  zsh:  cp ${completions_dir}/_${BINARY_NAME} /usr/local/share/zsh/site-functions/"
    echo "  fish: cp ${completions_dir}/${BINARY_NAME}.fish ~/.config/fish/completions/"
}

cmd_all() {
    log "Running full release pipeline..."
    echo

    cmd_clean
    echo
    cmd_test
    echo
    cmd_release
    echo
    cmd_install
    echo
    cmd_completions

    echo
    log_success "Full pipeline complete!"
    cmd_version
}

cmd_help() {
    head -25 "$0" | tail -22 | sed 's/^# //' | sed 's/^#//'
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    check_project

    # Parse options
    local cmd=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --prefix)
                PREFIX="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            -h|--help)
                cmd_help
                exit 0
                ;;
            -*)
                die "Unknown option: $1"
                ;;
            *)
                cmd="$1"
                shift
                ;;
        esac
    done

    # Default command
    if [[ -z "$cmd" ]]; then
        cmd="all"
    fi

    # Dispatch
    case "$cmd" in
        build)       cmd_build ;;
        release)     cmd_release ;;
        test)        cmd_test ;;
        install)     cmd_install ;;
        clean)       cmd_clean ;;
        version)     cmd_version ;;
        completions) cmd_completions ;;
        package)     cmd_package ;;
        github)      cmd_github ;;
        homebrew)    cmd_homebrew ;;
        all)         cmd_all ;;
        help)        cmd_help ;;
        *)           die "Unknown command: $cmd. Run with --help for usage." ;;
    esac
}

main "$@"
