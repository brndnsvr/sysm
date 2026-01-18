# sysm

Unified CLI for the Apple ecosystem on macOS. Interact with Calendar, Reminders, Notes, Contacts, Mail, Messages, Safari, Music, Photos, Finder tags, Spotlight, Shortcuts, Focus modes, and Weather from the terminal.

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/brndnsvr/sysm.git
cd sysm

# Build and install to ~/bin
make install

# Or with code signing (required for WeatherKit)
make install-notarized
```

### Requirements

- macOS 13.0+
- Xcode 15+ or Swift 5.9+ toolchain
- Apple Developer account (for WeatherKit support)

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
sysm mail unread
sysm mail inbox --limit 10

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

## Weather Backends

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

For full functionality including WeatherKit:

```bash
make install-notarized
```

This creates a signed and notarized app bundle at `/opt/sysm/sysm.app` with a symlink at `/usr/local/bin/sysm`.

Requirements:
- Apple Developer Program membership
- Developer ID Application certificate
- App ID with WeatherKit capability
- Provisioning profile

See `make help` for all build options.

## Documentation

- [ROADMAP.md](ROADMAP.md) - Detailed feature documentation and implementation notes

## License

MIT
