.PHONY: build release install clean test help all-release

# Default target
all: release

# Debug build
build:
	swift build

# Release build
release:
	swift build -c release

PREFIX ?= $(HOME)/bin

# Install to ~/bin (or override with PREFIX=/usr/local/bin)
install: release
	@mkdir -p $(PREFIX)
	@echo "Installing sysm to $(PREFIX)..."
	cp .build/release/sysm $(PREFIX)/sysm
	@echo "Installed. Verify with: sysm --help"

# Uninstall
uninstall:
	rm -f $(PREFIX)/sysm

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build

# Run tests (placeholder)
test:
	swift test

# Full release pipeline via script
all-release:
	./scripts/release.sh all

# Show help
help:
	@echo "sysm build targets:"
	@echo "  make build       - Debug build"
	@echo "  make release     - Release build"
	@echo "  make install     - Build release and install to ~/bin"
	@echo "  make clean       - Remove build artifacts"
	@echo "  make test        - Run tests"
	@echo "  make all-release - Full pipeline (clean, test, release, install)"
	@echo ""
	@echo "For more options: ./scripts/release.sh --help"
