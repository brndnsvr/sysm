# sysm

Unified CLI for the Apple ecosystem on macOS. Interact with Calendar, Reminders, Notes, Contacts, Mail, Messages, Safari, Music, Photos, Finder tags, Spotlight, Shortcuts, Focus modes, and Weather from the terminal.

## Installation

### Homebrew (Recommended)

```bash
# Add tap
brew tap brndnsvr/tap

# Install sysm
brew install sysm

# Verify installation
sysm --version
```

Shell completions are automatically installed for bash, zsh, and fish.

### From Source

```bash
# Clone the repository
git clone https://github.com/brndnsvr/sysm.git
cd sysm

# Build and install to ~/bin
make install
```

### Requirements

- macOS 13.0+
- Xcode 15+ or Swift 5.9+ toolchain

## Commands

| Command | Description |
|---------|-------------|
| `calendar` | Manage calendar events |
| `reminders` | Manage reminders and lists |
| `notes` | Access Notes app |
| `contacts` | Search and view contacts |
| `mail` | Read and compose emails |
| `messages` | Send iMessages/SMS |
| `safari` | Reading list, bookmarks, tabs |
| `shortcuts` | Run Shortcuts |
| `focus` | Manage Focus/DND modes |
| `tags` | Finder tags on files |
| `spotlight` | Search files and metadata |
| `music` | Control Music.app playback |
| `photos` | Access photo library |
| `exec` | Run AppleScript/JXA |
| `workflow` | Multi-step automation |
| `schedule` | Cron-like task scheduling |
| `plugin` | Extend with custom plugins |
| `weather` | Current conditions and forecasts |

## Quick Examples

```bash
# Calendar
sysm calendar today
sysm calendar add "Meeting" --start "2024-01-15 14:00" --calendar "Work"

# Reminders
sysm reminders today
sysm reminders add "Buy groceries" --list "Shopping"

# Contacts
sysm contacts search "John"
sysm contacts birthdays

# Mail
sysm mail accounts             # List accounts
sysm mail unread
sysm mail inbox --limit 10
sysm mail inbox --account "Work" --limit 20  # Filter by account

# Messages
sysm messages send "+15551234567" "Hello!"

# Safari
sysm safari rl              # Reading list
sysm safari tabs            # Open tabs
sysm safari bookmarks

# Music
sysm music status
sysm music play
sysm music next

# Tags
sysm tags list ~/Documents/report.pdf
sysm tags add ~/file.txt --tag "work" --color 4
sysm tags set ~/file.txt --tags "urgent,review"
sysm tags find "work"

# Spotlight
sysm spotlight search "quarterly report"
sysm spotlight kind pdf
sysm spotlight modified 7

# Photos
sysm photos albums
sysm photos recent --limit 10

# Weather
sysm weather current "San Francisco"
sysm weather forecast "New York"

# Focus
sysm focus status
sysm focus dnd on

# Shortcuts
sysm shortcuts list
sysm shortcuts run "My Shortcut"
```

## Output Formats

Most commands support `--json` for machine-readable output:

```bash
sysm calendar today --json
sysm contacts search "Smith" --json
sysm weather current "London" --json
```

## Permissions

sysm requires macOS permissions for each service it accesses. Grant these in System Settings > Privacy & Security:

| Permission | Commands |
|------------|----------|
| Calendar | `calendar`, `reminders` |
| Contacts | `contacts` |
| Full Disk Access | `mail`, `safari` (for reading plist files) |
| Photos | `photos` |
| Automation | `notes`, `music`, `messages`, `shortcuts` |

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SYSM_TRIGGER_PATH` | Override trigger file path for reminder tracking | `~/dayai/_dayai/TRIGGER.md` |

### Weather Backends

The weather command supports two backends:

- **WeatherKit** (default): Apple's weather service. Requires code signing with WeatherKit entitlement.
- **Open-Meteo**: Free API, no authentication required.

```bash
# Use WeatherKit (default, requires signed binary)
sysm weather current "Paris"

# Use Open-Meteo (no signing required)
sysm weather current "Paris" --backend open-meteo
```

## Code Signing

Code signing is only needed for WeatherKit support. All other commands work without signing. Use `--backend open-meteo` as an alternative that requires no signing.

To build with WeatherKit, you need your own Apple Developer credentials. Create a `Makefile.local` in the project root:

```makefile
SIGNING_IDENTITY = Developer ID Application: Your Name (YOUR_TEAM_ID)
BUNDLE_ID = com.yourorg.sysm
NOTARY_PROFILE = your-notary-profile
PROFILE_UUID = your-provisioning-profile-uuid
```

Then build and install:

```bash
make install-notarized
```

This creates a signed and notarized app bundle at `/opt/sysm/sysm.app` with a symlink at `/usr/local/bin/sysm`.

Prerequisites:
- Apple Developer Program membership
- Developer ID Application certificate
- App ID registered with WeatherKit capability
- Provisioning profile for the App ID
- Notary credentials stored in keychain (`xcrun notarytool store-credentials`)

See `make help` for all build options.

## Architecture

sysm is organized as a modular Swift Package with two targets:

- **SysmCore**: Library containing all services, models, protocols, and utilities. Can be imported independently for programmatic access to macOS services.
- **sysm**: Command-line executable providing the CLI interface.

```swift
// Example: Using SysmCore directly
import SysmCore

let calendar = Services.calendar()
let events = try await calendar.getTodayEvents()
```

The `ServiceContainer` provides dependency injection, allowing test mocking and customization.

## Development

### Version Management

Version is managed through the `VERSION` file in the project root. The version is automatically embedded into the binary during builds.

```bash
# Bump patch version (1.0.0 -> 1.0.1)
./scripts/bump-version.sh patch

# Bump minor version (1.0.0 -> 1.1.0)
./scripts/bump-version.sh minor

# Bump major version (1.0.0 -> 2.0.0)
./scripts/bump-version.sh major

# Set specific version
./scripts/bump-version.sh 2.1.3
```

After bumping the version:
1. Review: `git diff VERSION`
2. Test: `./scripts/release.sh test`
3. Commit: `git add VERSION && git commit -m 'chore: bump version to X.Y.Z'`
4. Tag: `git tag vX.Y.Z`
5. Push: `git push && git push --tags`

## Documentation

- [Architecture Decision Records](docs/adr/README.md) - Key architectural decisions and rationale
- [ROADMAP.md](ROADMAP.md) - Detailed feature documentation and implementation notes

## License

MIT
