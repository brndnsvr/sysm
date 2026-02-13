# Installing sysm

Quick installation guide for sysm on other systems.

## For End Users

### Method 1: Homebrew (Recommended)

```bash
# Authenticate with GitHub (one-time)
gh auth login

# Install sysm
brew tap brndnsvr/tap
brew install sysm

# Verify
sysm --version
```

**Update:**
```bash
brew update
brew upgrade sysm
```

---

### Method 2: Direct Install Script

```bash
# Install latest version
bash -c "$(curl -fsSL https://raw.githubusercontent.com/brndnsvr/sysm/main/scripts/install.sh)"

# Or to ~/bin (no sudo needed)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/brndnsvr/sysm/main/scripts/install.sh)" -- --user
```

**Update:**
```bash
# Run the same install command again
bash -c "$(curl -fsSL https://raw.githubusercontent.com/brndnsvr/sysm/main/scripts/install.sh)"
```

---

## For Maintainers

### Initial Setup (One-Time)

```bash
# Set up private Homebrew tap
./scripts/setup-homebrew-tap.sh
```

### Publishing Releases

```bash
# 1. Update version
echo "1.0.1" > VERSION

# 2. Create release (builds, packages, uploads)
./scripts/release.sh github

# That's it! The Homebrew tap updates automatically.
```

---

## Requirements

- **macOS:** Ventura (13.0) or later
- **GitHub Access:** Private repo requires authentication
- **Permissions:** System Settings > Privacy & Security

---

## Getting Help

- **Documentation:** [README.md](README.md)
- **Distribution Guide:** [docs/DISTRIBUTION.md](docs/DISTRIBUTION.md)
- **Issues:** https://github.com/brndnsvr/sysm/issues
