.PHONY: build release bundle release-signed notarize release-notarized install install-signed install-notarized clean test help all-release

# Default target
all: release

# Code signing identity (set via environment or override on command line)
SIGNING_IDENTITY ?= 

# Bundle ID must match App ID registered in Apple Developer Portal
BUNDLE_ID ?= com.brndnsvr.sysm

# Keychain profile for notarization (created with: xcrun notarytool store-credentials)
NOTARY_PROFILE ?= 

# Provisioning profile UUID (from Apple Developer Portal)
PROFILE_UUID ?= <PROFILE_UUID>

# Version
VERSION ?= 1.0.0

# Debug build
build:
	swift build

# Release build
release:
	swift build -c release

# Create app bundle structure with embedded provisioning profile
bundle: release
	@echo "Creating app bundle..."
	@mkdir -p .build/sysm.app/Contents/MacOS
	@cp .build/release/sysm .build/sysm.app/Contents/MacOS/sysm
	@cp ~/Library/MobileDevice/Provisioning\ Profiles/$(PROFILE_UUID).provisionprofile .build/sysm.app/Contents/embedded.provisionprofile 2>/dev/null || \
		cp ~/Library/MobileDevice/Provisioning\ Profiles/$(PROFILE_UUID).mobileprovision .build/sysm.app/Contents/embedded.provisionprofile 2>/dev/null || \
		(echo "Error: Provisioning profile not found. Download from Apple Developer Portal." && exit 1)
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > .build/sysm.app/Contents/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> .build/sysm.app/Contents/Info.plist
	@echo '<plist version="1.0"><dict>' >> .build/sysm.app/Contents/Info.plist
	@echo '<key>CFBundleExecutable</key><string>sysm</string>' >> .build/sysm.app/Contents/Info.plist
	@echo '<key>CFBundleIdentifier</key><string>$(BUNDLE_ID)</string>' >> .build/sysm.app/Contents/Info.plist
	@echo '<key>CFBundleName</key><string>sysm</string>' >> .build/sysm.app/Contents/Info.plist
	@echo '<key>CFBundleVersion</key><string>$(VERSION)</string>' >> .build/sysm.app/Contents/Info.plist
	@echo '<key>CFBundleShortVersionString</key><string>$(VERSION)</string>' >> .build/sysm.app/Contents/Info.plist
	@echo '<key>LSMinimumSystemVersion</key><string>13.0</string>' >> .build/sysm.app/Contents/Info.plist
	@echo '</dict></plist>' >> .build/sysm.app/Contents/Info.plist
	@echo "App bundle created: .build/sysm.app"

# Signed app bundle (for WeatherKit and distribution)
release-signed: bundle
	@echo "Signing app bundle with: $(SIGNING_IDENTITY)"
	codesign -s "$(SIGNING_IDENTITY)" \
		--entitlements sysm.entitlements \
		--timestamp \
		-o runtime \
		--force \
		.build/sysm.app
	@echo "Signed. Verify with: codesign -dvv .build/sysm.app"

# Notarize a signed app bundle (requires release-signed first)
notarize:
	@echo "Creating zip for notarization..."
	@rm -f .build/sysm-notarize.zip
	cd .build && zip -r sysm-notarize.zip sysm.app
	@echo "Submitting to Apple notary service..."
	xcrun notarytool submit .build/sysm-notarize.zip \
		--keychain-profile "$(NOTARY_PROFILE)" \
		--wait
	@rm .build/sysm-notarize.zip
	@echo "Notarization complete!"

# Full pipeline: build, bundle, sign, notarize
release-notarized: release-signed notarize
	@echo "Release signed and notarized: .build/sysm.app"

PREFIX ?= $(HOME)/bin

# Install to ~/bin (or override with PREFIX=/usr/local/bin)
install: release
	@mkdir -p $(PREFIX)
	@echo "Installing sysm to $(PREFIX)..."
	cp .build/release/sysm $(PREFIX)/sysm
	@echo "Installed. Verify with: sysm --help"

# Install signed binary (without provisioning profile - no WeatherKit)
install-signed: release
	@mkdir -p $(PREFIX)
	@echo "Installing sysm to $(PREFIX)..."
	codesign -s - --force .build/release/sysm
	cp .build/release/sysm $(PREFIX)/sysm
	@echo "Installed (ad-hoc signed, no WeatherKit)"

# Full pipeline: build, bundle, sign, notarize, install to /opt/sysm
install-notarized: release-notarized
	@echo "Installing notarized sysm.app to /opt/sysm..."
	sudo rm -rf /opt/sysm/sysm.app 2>/dev/null || true
	sudo rm -f /opt/sysm/sysm 2>/dev/null || true
	sudo mkdir -p /opt/sysm
	sudo cp -R .build/sysm.app /opt/sysm/
	sudo rm -f /usr/local/bin/sysm
	sudo ln -sf /opt/sysm/sysm.app/Contents/MacOS/sysm /usr/local/bin/sysm
	@echo "Installed to /opt/sysm/sysm.app"
	@echo "Symlinked to /usr/local/bin/sysm"
	@echo ""
	@echo "Test with: sysm weather current \"New York\""

# Uninstall
uninstall:
	sudo rm -rf /opt/sysm
	sudo rm -f /usr/local/bin/sysm
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
	@echo "  make build             - Debug build"
	@echo "  make release           - Release build"
	@echo "  make bundle            - Create app bundle with provisioning profile"
	@echo "  make release-signed    - Signed app bundle for WeatherKit"
	@echo "  make release-notarized - Signed + notarized (full distribution)"
	@echo "  make install           - Build and install to ~/bin (no signing)"
	@echo "  make install-signed    - Build with ad-hoc signing (no WeatherKit)"
	@echo "  make install-notarized - Full pipeline: build, sign, notarize, install"
	@echo "  make clean             - Remove build artifacts"
	@echo "  make test              - Run tests"
	@echo ""
	@echo "For WeatherKit + distribution (recommended):"
	@echo "  make install-notarized"
	@echo ""
	@echo "Configuration (defaults set for this machine):"
	@echo "  SIGNING_IDENTITY - Code signing certificate"
	@echo "  BUNDLE_ID        - App ID (must match Apple Developer Portal)"
	@echo "  NOTARY_PROFILE   - Keychain profile for notarytool"
	@echo "  PROFILE_UUID     - Provisioning profile UUID"
