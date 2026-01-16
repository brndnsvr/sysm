.PHONY: build release release-signed install install-signed clean test help all-release

# Default target
all: release

# Code signing identity (set via environment or override on command line)
# Example: make release-signed SIGNING_IDENTITY="Developer ID Application: Your Name (XXXXXXXXXX)"
SIGNING_IDENTITY ?=

# Debug build
build:
	swift build

# Release build
release:
	swift build -c release

# Signed release build (for WeatherKit and distribution)
release-signed: release
ifndef SIGNING_IDENTITY
	$(error SIGNING_IDENTITY is required. Set via: make release-signed SIGNING_IDENTITY="Developer ID Application: Your Name (TEAM_ID)")
endif
	@echo "Signing with: $(SIGNING_IDENTITY)"
	codesign -s "$(SIGNING_IDENTITY)" \
		--entitlements sysm.entitlements \
		--timestamp \
		-o runtime \
		--force \
		.build/release/sysm
	@echo "Signed. Verify with: codesign -dvv .build/release/sysm"

PREFIX ?= $(HOME)/bin

# Install to ~/bin (or override with PREFIX=/usr/local/bin)
install: release
	@mkdir -p $(PREFIX)
	@echo "Installing sysm to $(PREFIX)..."
	cp .build/release/sysm $(PREFIX)/sysm
	@echo "Installed. Verify with: sysm --help"

# Install signed binary
install-signed: release-signed
	@mkdir -p $(PREFIX)
	@echo "Installing signed sysm to $(PREFIX)..."
	cp .build/release/sysm $(PREFIX)/sysm
	@echo "Installed. Verify with: codesign -dvv $(PREFIX)/sysm"

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
	@echo "  make build          - Debug build"
	@echo "  make release        - Release build"
	@echo "  make release-signed - Signed release (requires SIGNING_IDENTITY)"
	@echo "  make install        - Build release and install to ~/bin"
	@echo "  make install-signed - Build, sign, and install (requires SIGNING_IDENTITY)"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make test           - Run tests"
	@echo "  make all-release    - Full pipeline (clean, test, release, install)"
	@echo ""
	@echo "Code signing (for WeatherKit and distribution):"
	@echo "  make release-signed SIGNING_IDENTITY=\"Developer ID Application: Name (TEAM_ID)\""
	@echo ""
	@echo "For more options: ./scripts/release.sh --help"
