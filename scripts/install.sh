#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# sysm installation script
# =============================================================================
# One-line installation for sysm on macOS
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/brndnsvr/sysm/main/scripts/install.sh | bash
#
# Or download and run:
#   ./install.sh [options]
#
# Options:
#   --version VERSION   Install specific version (default: latest)
#   --prefix PATH       Install prefix (default: /usr/local/bin)
#   --user              Install to ~/bin instead of /usr/local/bin
#   --dry-run           Show what would happen
# =============================================================================

# Configuration
GITHUB_REPO="brndnsvr/sysm"
BINARY_NAME="sysm"
DEFAULT_PREFIX="/usr/local/bin"
USER_PREFIX="${HOME}/bin"

# Runtime options
VERSION="latest"
PREFIX="$DEFAULT_PREFIX"
DRY_RUN=false

# Colors
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

log() { echo -e "${BLUE}==>${NC} ${BOLD}$*${NC}"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }
die() { log_error "$*"; exit 1; }

run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}

# Check if running on macOS
check_macos() {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        die "This script only works on macOS"
    fi
}

# Check if gh CLI is available and authenticated
check_gh_auth() {
    if ! command -v gh &> /dev/null; then
        log_warn "GitHub CLI not found. Installing..."
        if command -v brew &> /dev/null; then
            run brew install gh
        else
            die "Please install GitHub CLI: https://cli.github.com/"
        fi
    fi

    if ! gh auth status &> /dev/null 2>&1; then
        log_warn "Not authenticated with GitHub"
        log "Please authenticate to access private repository:"
        run gh auth login
    fi
}

# Get latest release version
get_latest_version() {
    if ! gh release view --repo "$GITHUB_REPO" latest &> /dev/null; then
        die "No releases found. Please create a release first with: ./scripts/release.sh github"
    fi

    gh release view --repo "$GITHUB_REPO" latest --json tagName --jq '.tagName' | sed 's/^v//'
}

# Download and install binary
install_binary() {
    local version="$1"
    local arch
    arch=$(uname -m)

    log "Installing ${BINARY_NAME} ${version}..."

    # Determine archive name
    local archive="${BINARY_NAME}-${version}-macos-${arch}.tar.gz"
    local download_url="https://github.com/${GITHUB_REPO}/releases/download/v${version}/${archive}"

    # Create temp directory
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    # Download release asset
    log "Downloading from GitHub releases..."
    if [[ "$DRY_RUN" != "true" ]]; then
        if ! gh release download "v${version}" \
            --repo "$GITHUB_REPO" \
            --pattern "$archive" \
            --dir "$tmp_dir"; then
            die "Failed to download release. Make sure you're authenticated with: gh auth login"
        fi
    else
        echo "[dry-run] Download ${archive} to ${tmp_dir}"
    fi

    # Extract
    log "Extracting..."
    run tar -xzf "${tmp_dir}/${archive}" -C "$tmp_dir"

    # Install
    log "Installing to ${PREFIX}/${BINARY_NAME}..."

    if [[ "$PREFIX" == "/usr/local/bin" ]] || [[ "$PREFIX" == "/opt/"* ]]; then
        # System location - needs sudo
        run sudo mkdir -p "$PREFIX"
        run sudo cp "${tmp_dir}/${BINARY_NAME}" "${PREFIX}/${BINARY_NAME}"
        run sudo chmod +x "${PREFIX}/${BINARY_NAME}"
    else
        # User location - no sudo needed
        run mkdir -p "$PREFIX"
        run cp "${tmp_dir}/${BINARY_NAME}" "${PREFIX}/${BINARY_NAME}"
        run chmod +x "${PREFIX}/${BINARY_NAME}"
    fi

    log_success "Installed ${BINARY_NAME} to ${PREFIX}/${BINARY_NAME}"
}

# Verify installation
verify_installation() {
    local installed_bin="${PREFIX}/${BINARY_NAME}"

    if [[ ! -f "$installed_bin" ]]; then
        die "Installation failed - binary not found at ${installed_bin}"
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        local installed_version
        installed_version=$("$installed_bin" --version 2>/dev/null | head -1 || echo "unknown")
        log_success "Verified: ${installed_version}"
    fi
}

# Print post-install instructions
print_post_install() {
    cat <<EOF

${GREEN}${BOLD}Installation Complete!${NC}

${BOLD}Test it:${NC}
  ${BLUE}${PREFIX}/${BINARY_NAME} --help${NC}

EOF

    # Check if PREFIX is in PATH
    if [[ ":$PATH:" != *":${PREFIX}:"* ]]; then
        log_warn "Warning: ${PREFIX} is not in your PATH"
        echo ""
        echo "${BOLD}Add to PATH:${NC}"
        echo "  ${BLUE}echo 'export PATH=\"${PREFIX}:\$PATH\"' >> ~/.zshrc${NC}"
        echo "  ${BLUE}source ~/.zshrc${NC}"
        echo ""
    fi

    cat <<EOF
${BOLD}Privacy Permissions:${NC}
  sysm requires macOS permissions for:
  - Calendars, Reminders, Contacts, Photos
  - Mail, Notes, Messages (AppleScript automation)

  System Settings > Privacy & Security

${BOLD}Documentation:${NC}
  https://github.com/${GITHUB_REPO}

${BOLD}Update sysm:${NC}
  ${BLUE}bash -c "\$(curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/main/scripts/install.sh)"${NC}

EOF
}

# Main
main() {
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version)
                VERSION="$2"
                shift 2
                ;;
            --prefix)
                PREFIX="$2"
                shift 2
                ;;
            --user)
                PREFIX="$USER_PREFIX"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                head -20 "$0" | tail -17 | sed 's/^# //' | sed 's/^#//'
                exit 0
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
    done

    check_macos
    check_gh_auth

    # Get version
    if [[ "$VERSION" == "latest" ]]; then
        VERSION=$(get_latest_version)
        log "Latest version: ${VERSION}"
    fi

    install_binary "$VERSION"
    verify_installation
    print_post_install
}

main "$@"
