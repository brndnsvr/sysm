#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Setup Private Homebrew Tap
# =============================================================================
# Creates a separate private repository for Homebrew formula distribution
#
# Usage: ./scripts/setup-homebrew-tap.sh [options]
#
# This script:
# 1. Creates homebrew-tap repository on GitHub (if it doesn't exist)
# 2. Copies the formula
# 3. Sets up GitHub Actions for auto-updates
# 4. Provides installation instructions
#
# Options:
#   --dry-run       Show what would happen
#   --skip-github   Don't create GitHub repo (manual setup)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
GITHUB_USER="brndnsvr"
TAP_REPO="homebrew-tap"
TAP_FULL="${GITHUB_USER}/${TAP_REPO}"
FORMULA_NAME="sysm"

# Runtime options
DRY_RUN=false
SKIP_GITHUB=false

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

# Check prerequisites
check_prerequisites() {
    if ! command -v gh &> /dev/null; then
        die "GitHub CLI (gh) required. Install with: brew install gh"
    fi

    if ! gh auth status &> /dev/null; then
        die "Not authenticated with GitHub. Run: gh auth login"
    fi
}

# Create GitHub repository for tap
create_tap_repo() {
    log "Creating GitHub repository: ${TAP_FULL}..."

    if gh repo view "$TAP_FULL" &> /dev/null; then
        log_warn "Repository ${TAP_FULL} already exists"
        return 0
    fi

    if [[ "$DRY_RUN" != "true" ]]; then
        gh repo create "$TAP_FULL" \
            --private \
            --description "Private Homebrew tap for sysm CLI" \
            --clone

        log_success "Created ${TAP_FULL}"
    else
        echo "[dry-run] gh repo create ${TAP_FULL} --private"
    fi
}

# Initialize tap repository structure
setup_tap_structure() {
    local tap_dir="/tmp/${TAP_REPO}-$$"

    log "Setting up tap repository structure..."

    if [[ "$DRY_RUN" != "true" ]]; then
        # Clone if exists, or use existing
        if [[ -d "${HOME}/.homebrew-tap-setup" ]]; then
            tap_dir="${HOME}/.homebrew-tap-setup"
            cd "$tap_dir"
            git pull origin main || true
        else
            tap_dir="${HOME}/.homebrew-tap-setup"
            gh repo clone "$TAP_FULL" "$tap_dir" || true
            cd "$tap_dir"
        fi

        # Copy formula
        mkdir -p Formula
        cp "${PROJECT_ROOT}/Formula/${FORMULA_NAME}.rb" "Formula/${FORMULA_NAME}.rb"

        # Create README
        cat > README.md <<EOF
# Homebrew Tap for sysm

Private Homebrew tap for [sysm](https://github.com/${GITHUB_USER}/sysm) - unified CLI for Apple ecosystem on macOS.

## Installation

\`\`\`bash
# Authenticate with GitHub (if not already)
gh auth login

# Tap the repository
brew tap ${TAP_FULL}

# Install sysm
brew install ${FORMULA_NAME}
\`\`\`

## Update

\`\`\`bash
brew update
brew upgrade ${FORMULA_NAME}
\`\`\`

## Uninstall

\`\`\`bash
brew uninstall ${FORMULA_NAME}
brew untap ${TAP_FULL}
\`\`\`

## Formula

The formula is automatically updated when new releases are published to the main repository.
EOF

        # Commit and push
        git add -A
        git commit -m "Initial tap setup with ${FORMULA_NAME} formula" || true
        git push -u origin main || git push

        log_success "Tap repository structure created at: $tap_dir"
    else
        echo "[dry-run] Set up tap structure in ${tap_dir}"
    fi
}

# Create GitHub Actions workflow for auto-updates
create_update_workflow() {
    local tap_dir="${HOME}/.homebrew-tap-setup"

    log "Creating auto-update workflow..."

    if [[ "$DRY_RUN" != "true" ]]; then
        mkdir -p "${tap_dir}/.github/workflows"

        cat > "${tap_dir}/.github/workflows/update-formula.yml" <<'EOF'
name: Update Formula

on:
  repository_dispatch:
    types: [new-release]
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to update to (e.g., 1.0.1)'
        required: true
      sha256:
        description: 'SHA256 of the release tarball'
        required: true

jobs:
  update:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Update formula
        run: |
          VERSION="${{ github.event.inputs.version || github.event.client_payload.version }}"
          SHA256="${{ github.event.inputs.sha256 || github.event.client_payload.sha256 }}"

          sed -i '' "s|url \".*\"|url \"https://github.com/brndnsvr/sysm/archive/v${VERSION}.tar.gz\"|" Formula/sysm.rb
          sed -i '' "s|sha256 \".*\"|sha256 \"${SHA256}\"|" Formula/sysm.rb

      - name: Commit and push
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add Formula/sysm.rb
          git commit -m "Update sysm to ${VERSION}" || exit 0
          git push
EOF

        cd "$tap_dir"
        git add .github/workflows/update-formula.yml
        git commit -m "Add auto-update workflow" || true
        git push

        log_success "Auto-update workflow created"
    else
        echo "[dry-run] Create auto-update workflow"
    fi
}

# Print installation instructions
print_instructions() {
    cat <<EOF

${GREEN}${BOLD}Homebrew Tap Setup Complete!${NC}

${BOLD}For other systems to install sysm:${NC}

1. ${BOLD}Install via Homebrew (recommended):${NC}
   ${BLUE}gh auth login${NC}  # Authenticate with GitHub (one-time)
   ${BLUE}brew tap ${TAP_FULL}${NC}
   ${BLUE}brew install ${FORMULA_NAME}${NC}

2. ${BOLD}Or use the install script:${NC}
   ${BLUE}bash -c "\$(curl -fsSL https://raw.githubusercontent.com/${GITHUB_USER}/sysm/main/scripts/install.sh)"${NC}

${BOLD}To publish a new release:${NC}
   ${BLUE}./scripts/release.sh github${NC}

   This will:
   - Build the release binary
   - Create GitHub release with tarball
   - Trigger tap formula update automatically

${BOLD}Manual formula update:${NC}
   ${BLUE}cd ~/.homebrew-tap-setup${NC}
   ${BLUE}# Edit Formula/sysm.rb (update version and sha256)${NC}
   ${BLUE}git add Formula/sysm.rb${NC}
   ${BLUE}git commit -m "Update sysm to vX.Y.Z"${NC}
   ${BLUE}git push${NC}

${BOLD}Tap repository:${NC} https://github.com/${TAP_FULL}
${BOLD}Main repository:${NC} https://github.com/${GITHUB_USER}/sysm

EOF
}

# Main
main() {
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-github)
                SKIP_GITHUB=true
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

    check_prerequisites

    if [[ "$SKIP_GITHUB" != "true" ]]; then
        create_tap_repo
    fi

    setup_tap_structure
    create_update_workflow
    print_instructions
}

main "$@"
