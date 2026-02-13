# Homebrew Distribution Guide

This guide explains how to distribute sysm via Homebrew tap.

## Overview

sysm is distributed through a Homebrew tap at `brndnsvr/homebrew-tap`. This allows users to install sysm with:

```bash
brew tap brndnsvr/tap
brew install sysm
```

## Tap Repository Structure

The tap repository (`homebrew-tap`) should have this structure:

```
homebrew-tap/
├── README.md
└── Formula/
    └── sysm.rb
```

## Setting Up the Tap Repository

### 1. Create Tap Repository

```bash
# Create new repository on GitHub
gh repo create brndnsvr/homebrew-tap --public --description "Homebrew tap for sysm"

# Clone locally
git clone https://github.com/brndnsvr/homebrew-tap.git
cd homebrew-tap

# Create Formula directory
mkdir -p Formula
```

### 2. Copy Formula

```bash
# Copy formula from sysm repository
cp /path/to/sysm/Formula/sysm.rb Formula/

# Commit and push
git add Formula/sysm.rb
git commit -m "Add sysm formula"
git push origin main
```

### 3. Initial Formula Setup

The formula needs to be updated with the correct version and SHA256:

```ruby
url "https://github.com/brndnsvr/sysm/archive/v1.0.0.tar.gz"
sha256 "..." # Fill in during first release
```

## Release Process

When releasing a new version of sysm:

### 1. Create GitHub Release

```bash
cd /path/to/sysm

# Update VERSION file
echo "1.0.0" > VERSION

# Run release script
./scripts/release.sh github
```

This creates a GitHub release with a tarball at:
```
https://github.com/brndnsvr/sysm/archive/v1.0.0.tar.gz
```

### 2. Get SHA256

```bash
# Download the tarball
curl -L -o sysm-1.0.0.tar.gz https://github.com/brndnsvr/sysm/archive/v1.0.0.tar.gz

# Calculate SHA256
shasum -a 256 sysm-1.0.0.tar.gz
```

### 3. Update Homebrew Formula

```bash
cd /path/to/homebrew-tap

# Edit Formula/sysm.rb
# Update url and sha256 with new version and hash

vim Formula/sysm.rb
```

Example update:
```ruby
url "https://github.com/brndnsvr/sysm/archive/v1.0.1.tar.gz"
sha256 "abc123def456..." # New SHA from step 2
```

### 4. Test Formula

```bash
# Test installation from local formula
brew install --build-from-source ./Formula/sysm.rb

# Test basic functionality
sysm --version
sysm --help

# Uninstall test version
brew uninstall sysm
```

### 5. Publish Update

```bash
# Commit and push updated formula
git add Formula/sysm.rb
git commit -m "Update sysm to v1.0.1"
git push origin main
```

### 6. Verify User Installation

```bash
# Test as a user would install
brew tap brndnsvr/tap
brew install sysm

# Or upgrade existing installation
brew upgrade sysm
```

## Automated Release (Future)

The `cmd_homebrew` function in `scripts/release.sh` can be enhanced to automate this:

```bash
cmd_homebrew() {
    # 1. Create GitHub release
    cmd_github

    # 2. Calculate SHA256 from release tarball
    local version tag archive sha
    version=$(get_version)
    tag="v${version}"
    archive="${BINARY_NAME}-${version}-macos-$(uname -m).tar.gz"
    sha=$(shasum -a 256 "$archive" | cut -d' ' -f1)

    # 3. Clone tap repository
    git clone "https://github.com/${HOMEBREW_TAP}.git" /tmp/homebrew-tap
    cd /tmp/homebrew-tap

    # 4. Update formula
    sed -i '' "s|url \".*\"|url \"https://github.com/${GITHUB_REPO}/archive/${tag}.tar.gz\"|" Formula/sysm.rb
    sed -i '' "s|sha256 \".*\"|sha256 \"${sha}\"|" Formula/sysm.rb

    # 5. Commit and push
    git add Formula/sysm.rb
    git commit -m "Update sysm to ${tag}"
    git push origin main

    # Cleanup
    rm -rf /tmp/homebrew-tap
}
```

## Troubleshooting

### Formula Audit

Run Homebrew's audit tool to catch issues:

```bash
brew audit --strict --online ./Formula/sysm.rb
```

Common issues:
- Missing or incorrect SHA256
- Invalid homepage URL
- License not specified
- Missing dependencies

### Installation Failures

If users report installation failures:

1. Check the GitHub release tarball is accessible
2. Verify SHA256 matches the tarball
3. Test `swift build` manually from the tarball source
4. Check macOS version requirements (minimum: Ventura)
5. Check Xcode version requirements (minimum: 15.0)

### Caveats Not Showing

The formula's `caveats` section shows permission requirements. If users don't see it:

```bash
# Show formula caveats manually
brew info sysm
```

Or direct them to the permission checker:

```bash
curl -fsSL https://raw.githubusercontent.com/brndnsvr/sysm/main/scripts/check-permissions.sh | bash
```

## Resources

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Homebrew Taps](https://docs.brew.sh/Taps)
- [Homebrew Ruby Style Guide](https://docs.brew.sh/Ruby-Style-Guide)

## Support

For Homebrew-related issues, users should:

1. Check `brew doctor` output
2. Review formula caveats with `brew info sysm`
3. Report issues to the main sysm repository with `[homebrew]` tag
