#!/bin/bash
set -euo pipefail

# Pre-flight permission checker for sysm
#
# Checks macOS privacy permissions for key services and provides
# guidance for granting access. Run this before using sysm to
# ensure all permissions are properly configured.
#
# Usage: ./scripts/check-permissions.sh

echo "═══════════════════════════════════════════════════════════"
echo "  sysm Permission Checker"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

MISSING_PERMISSIONS=()

# Check if we're running in a terminal app
if [[ -z "${TERM_PROGRAM:-}" ]]; then
    echo -e "${YELLOW}⚠${NC}  Unknown terminal application"
    echo "   Cannot determine which app to grant permissions to"
    echo ""
fi

echo "Terminal Application: ${TERM_PROGRAM:-Unknown}"
echo ""
echo "Checking permissions..."
echo ""

# Function to check permission status
check_permission() {
    local service="$1"
    local display_name="$2"
    local setting_path="$3"

    # Note: There's no reliable command-line way to check macOS privacy permissions
    # without using private APIs. This script provides guidance instead.

    echo -e "📋 ${display_name}"
    echo "   Privacy pane: System Settings > Privacy & Security > ${display_name}"
    echo "   Quick open: open \"x-apple.systempreferences:com.apple.preference.security?Privacy_${service}\""
    echo ""
}

echo "────────────────────────────────────────────────────────────"
echo "Framework-Based Services (require explicit permission)"
echo "────────────────────────────────────────────────────────────"
echo ""

check_permission "Calendars" "Calendars" "Privacy_Calendars"
check_permission "Reminders" "Reminders" "Privacy_Reminders"
check_permission "Contacts" "Contacts" "Privacy_Contacts"
check_permission "Photos" "Photos" "Privacy_Photos"

echo "────────────────────────────────────────────────────────────"
echo "AppleScript-Based Services (may require Automation permission)"
echo "────────────────────────────────────────────────────────────"
echo ""

echo "📋 Mail, Notes, Messages, Music, Safari"
echo "   These services use AppleScript automation"
echo "   You may be prompted for permission on first use"
echo "   Privacy pane: System Settings > Privacy & Security > Automation"
echo "   Quick open: open \"x-apple.systempreferences:com.apple.preference.security?Privacy_Automation\""
echo ""

echo "────────────────────────────────────────────────────────────"
echo "Special Services"
echo "────────────────────────────────────────────────────────────"
echo ""

echo "📋 Focus (Do Not Disturb)"
echo "   Requires Full Disk Access for reading Focus state"
echo "   Privacy pane: System Settings > Privacy & Security > Full Disk Access"
echo "   Quick open: open \"x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles\""
echo ""

echo "📋 Weather"
echo "   Requires WeatherKit entitlement and Apple Developer account"
echo "   Configure in Xcode project settings or skip weather commands"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  Testing Permissions"
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "Run these commands to test each service:"
echo ""
echo "  sysm calendar today          # Test Calendar access"
echo "  sysm reminders today         # Test Reminders access"
echo "  sysm contacts search test    # Test Contacts access"
echo "  sysm photos albums           # Test Photos access"
echo "  sysm mail inbox --limit 1    # Test Mail automation"
echo "  sysm notes list              # Test Notes automation"
echo "  sysm messages recent         # Test Messages automation"
echo "  sysm music status            # Test Music automation"
echo "  sysm safari tabs             # Test Safari automation"
echo "  sysm focus status            # Test Focus access"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  Common Issues"
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "1. 'Access Denied' Errors"
echo "   → Open the relevant Privacy & Security pane"
echo "   → Enable your terminal app (Terminal.app, iTerm2, etc.)"
echo "   → Restart sysm"
echo ""

echo "2. AppleScript Timeout Errors"
echo "   → Grant Automation permission when prompted"
echo "   → Ensure the target app (Mail, Notes, etc.) is running"
echo "   → Try the command again with --verbose for details"
echo ""

echo "3. WeatherKit Not Working"
echo "   → Weather requires Apple Developer account"
echo "   → Configure WeatherKit entitlement in Xcode"
echo "   → See CONTRIBUTING.md for setup instructions"
echo ""

echo "4. Terminal Not Listed in Privacy Panes"
echo "   → Run a sysm command that requires permission"
echo "   → macOS will prompt you and add the app automatically"
echo "   → Alternatively, manually add via '+' button in Privacy pane"
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  Ready to Use sysm"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "If you encounter permission errors:"
echo "  1. Note which service failed"
echo "  2. Open the corresponding Privacy pane above"
echo "  3. Enable access for your terminal app"
echo "  4. Restart sysm"
echo ""
echo "For detailed troubleshooting: docs/guides/troubleshooting.md"
echo "For contributing: CONTRIBUTING.md"
echo ""
