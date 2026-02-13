# Troubleshooting Guide

Common issues and solutions for sysm.

## Table of Contents

- [Permission Issues](#permission-issues)
- [Build and Installation Issues](#build-and-installation-issues)
- [AppleScript Issues](#applescript-issues)
- [WeatherKit Issues](#weatherkit-issues)
- [Performance Issues](#performance-issues)
- [Testing Issues](#testing-issues)

## Permission Issues

### Calendar/Reminders Access Denied

**Error:**
```
Calendar access denied
```

**Solution:**

1. Open **System Settings**
2. Navigate to **Privacy & Security** → **Calendars** (or **Reminders**)
3. Enable access for **Terminal** (or your terminal app: iTerm2, Warp, etc.)
4. Restart sysm

**Quick command to open settings:**
```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
```

**Notes:**
- First run will prompt for permission
- If denied, must be granted manually in System Settings
- Separate permissions for Calendar and Reminders

### Contacts Access Denied

**Error:**
```
Contacts access denied
```

**Solution:**

1. Open **System Settings**
2. Navigate to **Privacy & Security** → **Contacts**
3. Enable access for **Terminal**
4. Restart sysm

**Quick command:**
```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts"
```

### Photos Access Denied

**Error:**
```
Photos access denied
```

**Solution:**

1. Open **System Settings**
2. Navigate to **Privacy & Security** → **Photos**
3. Enable access for **Terminal**
4. Restart sysm

**Quick command:**
```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos"
```

### Automation/AppleScript Permission Denied

**Error:**
```
System Events got an error: osascript is not allowed to send keystrokes
```

**Solution:**

1. Open **System Settings**
2. Navigate to **Privacy & Security** → **Automation**
3. Find **Terminal** (or your terminal app)
4. Enable the target app (Mail, Notes, Messages, etc.)

**Notes:**
- Required for AppleScript-based services (Mail, Notes, Messages, Safari, Music)
- May need to enable multiple apps depending on what you're using
- Prompts appear on first use per app

### Full Disk Access (Advanced)

Some operations may require Full Disk Access:

1. Open **System Settings**
2. Navigate to **Privacy & Security** → **Full Disk Access**
3. Enable **Terminal**
4. Restart Terminal completely

**⚠️ Warning**: Only grant if needed. Not required for basic sysm operations.

## Build and Installation Issues

### "No such module 'SysmCore'"

**Symptom**: Build fails with missing module error

**Solutions:**

1. **Clean build:**
   ```bash
   swift package clean
   swift build
   ```

2. **Reset package cache:**
   ```bash
   rm -rf .build
   swift package reset
   swift build
   ```

3. **Check Swift version:**
   ```bash
   swift --version  # Should be 5.9+
   ```

### Code Signing Issues

**Symptom**: "Code signature invalid" or similar

**For Development (No WeatherKit):**
```bash
make install  # No signing, works for most features
```

**For WeatherKit Support:**

1. Get Apple Developer account
2. Create App ID in [Apple Developer Portal](https://developer.apple.com/account)
3. Create provisioning profile with WeatherKit capability
4. Download provisioning profile to `~/Library/MobileDevice/Provisioning Profiles/`
5. Build with signing:
   ```bash
   make install-notarized
   ```

**Common signing errors:**

**"No matching provisioning profiles found"**
- Download provisioning profile from Apple Developer Portal
- Ensure profile UUID in `Makefile` matches downloaded file

**"Code signing identity not found"**
```bash
# List available signing identities
security find-identity -v -p codesigning

# Update SIGNING_IDENTITY in Makefile if needed
```

### Xcode Version Mismatch

**Symptom**: Build errors with Xcode version

**Solution:**

1. **Check Xcode version:**
   ```bash
   xcodebuild -version  # Should be 15.0+
   ```

2. **Switch Xcode version:**
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

3. **Or use Command Line Tools:**
   ```bash
   sudo xcode-select -s /Library/Developer/CommandLineTools
   ```

### Missing Dependencies

**Symptom**: Build fails with missing dependencies

**Solution:**
```bash
# SwiftPM handles dependencies automatically
# But if issues persist:
swift package update
swift build
```

## AppleScript Issues

### AppleScript Timeout

**Error:**
```
AppleScript execution timed out
```

**Common Causes:**
- Mail app not running
- Large mailbox (1000+ messages)
- App is busy/unresponsive

**Solutions:**

1. **Start the target app first:**
   ```bash
   open -a Mail  # For Mail-related commands
   sysm mail inbox
   ```

2. **Use limits to reduce data:**
   ```bash
   # Instead of all messages
   sysm mail inbox --limit 50

   # Instead of all notes
   sysm notes list | head -20
   ```

3. **Increase timeout** (requires code change):
   ```swift
   // In AppleScriptRunner.swift
   let timeout: TimeInterval = 30  // Increase from default
   ```

### AppleScript Permission Prompt Loops

**Symptom**: Repeated permission prompts

**Solution:**

1. Reset automation permissions:
   ```bash
   tccutil reset AppleEvents
   ```

2. Grant permissions in System Settings → Privacy & Security → Automation

3. Restart Terminal completely (not just new window)

### "Application Not Running"

**Error:**
```
Application "Mail" isn't running
```

**Solution:**

1. **Start the app:**
   ```bash
   open -a Mail
   # Wait a few seconds
   sysm mail inbox
   ```

2. **Check if app is installed:**
   ```bash
   ls /Applications/ | grep -i mail
   ```

3. **For Notes/Music/etc**, same pattern:
   ```bash
   open -a Notes
   sysm notes list
   ```

### Script Injection Attempts Fail

**This is intentional and secure!**

AppleScript input is escaped to prevent injection:

```bash
# These are safely escaped:
sysm notes create "Test'; do shell script 'rm -rf ~'"
sysm mail search "\" & do shell script \"echo pwned\""
```

## WeatherKit Issues

### "WeatherKit Not Available"

**Symptom**: Weather commands fail

**Required Steps:**

1. **Apple Developer Account** ($99/year)
2. **App ID** with WeatherKit capability
3. **Provisioning Profile** downloaded
4. **Code signing** with profile:
   ```bash
   make install-notarized
   ```

**Verify signing:**
```bash
codesign -dvv ~/bin/sysm
# Should show: "Provisioning Profile: ..."
```

### Weather API Rate Limits

**Error:**
```
Weather API rate limit exceeded
```

**WeatherKit Limits:**
- 500,000 calls/month (free tier)
- After limit: service unavailable

**Solutions:**
- Wait for next month
- Cache results locally
- Reduce query frequency

### Location Not Found

**Error:**
```
Location not found: "Xyz"
```

**Solutions:**

1. **Be more specific:**
   ```bash
   # Instead of ambiguous:
   sysm weather current "Springfield"

   # Use full name with state:
   sysm weather current "Springfield, IL"
   ```

2. **Use coordinates:**
   ```bash
   sysm weather current --lat 37.7749 --lon -122.4194
   ```

## Performance Issues

### Slow Mail Commands

**Symptom**: `sysm mail inbox` takes 30+ seconds

**Cause**: Large mailbox with 1000+ messages

**Solutions:**

1. **Use limits:**
   ```bash
   sysm mail inbox --limit 20  # Much faster
   ```

2. **Filter by account:**
   ```bash
   sysm mail inbox --account "Work" --limit 10
   ```

3. **Use unread filter:**
   ```bash
   sysm mail unread --limit 10  # Fewer messages = faster
   ```

### Slow Calendar Queries

**Symptom**: Calendar commands slow with many events

**Solutions:**

1. **Use specific date ranges:**
   ```bash
   # Instead of:
   sysm calendar list

   # Use:
   sysm calendar today
   sysm calendar week
   ```

2. **Filter by calendar:**
   ```bash
   sysm calendar today --calendar "Work"
   ```

### Slow Contact Searches

**Symptom**: Contact search takes long time

**Solution**: Use advanced search with specific fields:

```bash
# Instead of:
sysm contacts search "John"  # Searches all fields

# Use:
sysm contacts search-email "john@"  # Searches email only
sysm contacts search-phone "555"    # Searches phone only
```

## Testing Issues

### "no such module 'XCTest'"

**Symptom**: Tests fail to build with XCTest not found

**Cause**: Swift 6.2 Command Line Tools issue (known issue)

**Solutions:**

1. **Use Xcode** (recommended):
   ```bash
   # Install Xcode from App Store
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   swift test
   ```

2. **Run tests in CI**:
   - GitHub Actions runs tests automatically
   - Tests work fine in CI with Xcode runner

3. **See detailed info:**
   - Read `KNOWN_ISSUES.md` for full details
   - This is a toolchain issue, not a project issue

### Tests Pass Locally but Fail in CI

**Causes:**
- Different macOS version
- Missing permissions in CI
- Time-sensitive tests

**Solutions:**

1. **Check CI logs** for specific errors
2. **Use test fixtures** instead of real data
3. **Mock external dependencies**

## Still Having Issues?

### Gather Diagnostic Info

```bash
# System info
sw_vers

# Swift version
swift --version

# Xcode path
xcode-select -p

# Build sysm with verbose output
swift build -v 2>&1 | tee build.log

# Check permissions
tccutil reset All
```

### Get Help

1. **Check Known Issues**: See `KNOWN_ISSUES.md`
2. **Search Issues**: [GitHub Issues](https://github.com/brndnsvr/sysm/issues)
3. **Ask Community**: [GitHub Discussions](https://github.com/brndnsvr/sysm/discussions)
4. **File Bug Report**: Use bug report template

### Bug Report Checklist

Include:
- [ ] macOS version (`sw_vers`)
- [ ] sysm version (`sysm --version`)
- [ ] Swift version (`swift --version`)
- [ ] Xcode version (`xcodebuild -version`)
- [ ] Full error message
- [ ] Steps to reproduce
- [ ] Expected vs actual behavior

### Contributing Fixes

Found a solution? Help others by:
1. Updating this troubleshooting guide
2. Submitting a PR with the fix
3. Documenting in GitHub Discussions

See `CONTRIBUTING.md` for details.
