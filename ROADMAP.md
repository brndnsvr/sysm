# sysm Roadmap

Unified CLI for Apple ecosystem integration on macOS.

## Phase 1 - Core PIM (Completed)

Foundation established with calendar, reminders, and notes integration.

| Subcommand | Framework | Status |
|------------|-----------|--------|
| `sysm calendar` | EventKit | Done |
| `sysm reminders` | EventKit | Done |
| `sysm notes` | AppleScript | Done |

Migrated from standalone tools: dayai-calendar, dayai-reminders, dayai-notes.

---

## Phase 2 - Extended Apple Apps (Completed)

### Phase 2a - Contacts (Done)

**Framework:** Contacts.framework (CNContactStore)

| Command | Description |
|---------|-------------|
| `search <query>` | Search contacts by name, email, phone |
| `show <id>` | Display full contact details |
| `email <query>` | Get email addresses matching query |
| `phone <query>` | Get phone numbers matching query |
| `birthdays` | List upcoming birthdays |
| `groups` | List contact groups |

**Status:** Complete
**Notes:** Requires Contacts permission. Uses actor-based ContactsService for thread safety. CNContactStore provides clean Swift API.

---

### Phase 2b - Mail (Done)

**Framework:** AppleScript (Mail.app)

| Command | Description |
|---------|-------------|
| `unread` | List unread messages |
| `inbox [--limit N]` | Show recent inbox messages |
| `read <id>` | Display message content |
| `search <query>` | Search messages |
| `accounts` | List configured accounts |
| `draft` | Create new draft (opens Mail.app) |

**Status:** Complete
**Notes:** Uses AppleScript via MailService. Supports `--json` output on all query commands.

---

### Phase 2c - Messages (Done)

**Framework:** AppleScript (Messages.app)

| Command | Description |
|---------|-------------|
| `send <recipient> <message>` | Send iMessage/SMS |
| `recent [--limit N]` | List recent conversations |
| `read <conversation>` | Show messages in conversation |

**Status:** Complete
**Notes:** Uses AppleScript via MessagesService. AppleScript access is limited on some macOS versions. Supports `--json` output.

---

### Phase 2d - Safari (Done)

**Framework:** AppleScript + plist reading

| Command | Description |
|---------|-------------|
| `rl` | List reading list items |
| `rl add <url>` | Add URL to reading list |
| `bookmarks` | List bookmarks |
| `tabs` | List open tabs across windows |

**Status:** Complete
**Notes:** Reading list and bookmarks parsed from `~/Library/Safari/Bookmarks.plist`. AppleScript for tab control and adding to reading list. Supports `--json` output.

---

### Phase 2e - Shortcuts (Done)

**Framework:** Shell wrapper around `shortcuts` CLI

| Command | Description |
|---------|-------------|
| `list` | List available shortcuts |
| `run <name>` | Execute a shortcut |

**Status:** Complete
**Notes:** Wrapper around `/usr/bin/shortcuts`. Supports `--json` output and `--input` for passing data to shortcuts.

---

### Phase 2f - Focus (Done)

**Framework:** AppleScript + defaults

| Command | Description |
|---------|-------------|
| `status` | Show current focus mode |
| `dnd on` | Enable Do Not Disturb |
| `dnd off` | Disable Do Not Disturb |
| `list` | List available focus modes |

**Status:** Complete
**Notes:** DND toggle via Shortcuts Events (falls back to Control Center scripting). Focus status read from defaults and assertion files. Supports `--json` output.

---

## Phase 3 - Extended System Integration (Completed)

### Phase 3a - Finder Tags (Done)

**Framework:** xattr (extended file attributes)

| Command | Description |
|---------|-------------|
| `list <path>` | List tags on file/folder |
| `add <path> --tag <name>` | Add tag to file |
| `remove <path> --tag <name>` | Remove tag from file |
| `find <tag>` | Find files with tag |

**Status:** Complete
**Notes:** Uses `getxattr`/`setxattr` for tag manipulation. Tag colors (0-7) supported. Search via mdfind.

---

### Phase 3b - Spotlight (Done)

**Framework:** mdfind CLI wrapper

| Command | Description |
|---------|-------------|
| `search <query>` | Search files by content/name |
| `kind <type>` | Search by file type |
| `modified <days>` | Files modified in last N days |
| `metadata <path>` | Show file metadata |

**Status:** Complete
**Notes:** Wraps `/usr/bin/mdfind` and `/usr/bin/mdls`. Supports `--json` output.

---

### Phase 3c - Music (Done)

**Framework:** AppleScript (Music.app)

| Command | Description |
|---------|-------------|
| `play` | Start/resume playback |
| `pause` | Pause playback |
| `next` / `prev` | Track navigation |
| `status` | Show now playing |
| `volume <0-100>` | Set volume |
| `playlists` | List playlists |
| `search <query>` | Search library |

**Status:** Complete
**Notes:** AppleScript-based control. MusicKit not used (playback APIs unavailable on macOS). Supports `--json` output.

---

### Phase 3d - Photos (Done)

**Framework:** PhotoKit (PHPhotoLibrary)

| Command | Description |
|---------|-------------|
| `albums` | List photo albums |
| `list <album-id>` | Photos in album |
| `recent` | Recent photos |
| `search --from/--to` | Search by date range |
| `export <asset-id>` | Export photo to file |

**Status:** Complete
**Notes:** Requires Photos permission. Actor-based service. Supports `--json` output.

---

## Phase 5 - External APIs (Completed)

### Phase 5a - Weather (Done)

**Framework:** Open-Meteo REST API (no API key required)

| Command | Description |
|---------|-------------|
| `current <location>` | Current weather conditions |
| `forecast <location>` | 7-day forecast |
| `hourly <location>` | Hourly forecast (up to 168 hours) |

**Status:** Complete
**Notes:** Uses Open-Meteo API (<10K calls/day free). Location can be city name or lat,lon coordinates. Fahrenheit default with Celsius in parentheses. Supports `--json` output.

---

## Future Possibilities

| Feature | Framework | Feasibility | Notes |
|---------|-----------|-------------|-------|
| **Keychain** | Security.framework | Medium | Security concerns. Read-only for non-sensitive items. |
| **Screen Time** | ScreenTime API | Low | Heavily restricted. Requires MDM or family sharing. |

---

## Implementation Notes

### Build System
- Swift Package Manager
- Single binary with subcommand routing via ArgumentParser
- Shared utilities for JSON output, date formatting, error handling

### Permissions
Each subcommand may require specific entitlements:
- Calendar/Reminders: `com.apple.security.personal-information.calendars`
- Contacts: `com.apple.security.personal-information.addressbook`
- Photos: `com.apple.security.personal-information.photos-library`

### Output Format
- Default: Human-readable
- `--json` flag: Machine-parseable JSON
- `--quiet` flag: Minimal output for scripting

### Error Handling
- Permission denied: Clear message with System Preferences deep link
- Not found: Exit code 1 with descriptive message
- Network errors: Retry logic where applicable
