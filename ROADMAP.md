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
| `unread [--account NAME]` | List unread messages |
| `inbox [--account NAME] [--limit N]` | Show recent inbox messages |
| `read <id>` | Display message content |
| `search <query> [--account NAME]` | Search messages |
| `accounts` | List configured accounts |
| `draft` | Create new draft (opens Mail.app) |

**Status:** Complete
**Notes:** Uses AppleScript via MailService. Supports `--json` output on all query commands. Use `--account` to filter by account name (as shown in `sysm mail accounts`).

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
| `set <path> --tags <list>` | Replace all tags atomically |
| `find <tag>` | Find files with tag |

**Status:** Complete
**Notes:** Uses `getxattr`/`setxattr` for tag manipulation. Tag colors (0-7) supported. The `set` command replaces all existing tags with the specified list. Search via mdfind.

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

## Phase 4 - Automation (Completed)

### Phase 4a - Script Execution (Done)

**Framework:** Shell/AppleScript/Python execution

| Command | Description |
|---------|-------------|
| `exec <script>` | Run a script file |
| `exec -c <cmd>` | Run inline command |
| `exec --shell <type>` | Specify shell (bash, zsh, sh) |
| `exec --python` | Run Python script |
| `exec --applescript` | Run AppleScript |

**Status:** Complete
**Notes:** Supports shell scripts, Python, AppleScript, and Swift code execution with timeout and error handling.

---

### Phase 4b - Workflows (Done)

**Framework:** YAML-based workflow engine

| Command | Description |
|---------|-------------|
| `workflow run <file>` | Execute a workflow |
| `workflow validate <file>` | Validate workflow syntax |
| `workflow list` | List available workflows |
| `workflow new <name>` | Create workflow scaffold |

**Status:** Complete
**Notes:** YAML-based multi-step automations. Supports variable passing between steps, conditional execution, error handling with retries, and template expansion. Workflows stored in `~/.sysm/workflows/`. Supports `--dry-run` and `--verbose` flags.

---

### Phase 4c - Scheduling (Done)

**Framework:** macOS launchd

| Command | Description |
|---------|-------------|
| `schedule add <name>` | Create scheduled job |
| `schedule list` | List all scheduled jobs |
| `schedule show <name>` | Show job details |
| `schedule remove <name>` | Delete scheduled job |
| `schedule enable <name>` | Enable a job |
| `schedule disable <name>` | Disable a job |
| `schedule run <name>` | Run job immediately |
| `schedule logs <name>` | View job logs |

**Status:** Complete
**Notes:** Uses macOS launchd for persistent scheduling. Supports cron syntax (`--cron "M H D Mo W"`) or interval-based (`--every N` seconds). Jobs persist across reboots.

---

### Phase 4d - Plugins (Done)

**Framework:** Shell script plugins

| Command | Description |
|---------|-------------|
| `plugin list` | List installed plugins |
| `plugin create <name>` | Create plugin scaffold |
| `plugin install <path>` | Install from directory |
| `plugin remove <name>` | Uninstall plugin |
| `plugin run <plugin> <cmd>` | Execute plugin command |
| `plugin info <name>` | Show plugin details |

**Status:** Complete
**Notes:** Extend sysm with custom shell script commands. Plugins stored in `~/.sysm/plugins/` with `plugin.yaml` manifest defining commands and arguments. Supports timeout configuration and argument passing.

---

## Phase 5 - External APIs (Completed)

### Phase 5a - Weather (Done)

**Backends:**
- WeatherKit (default, requires code signing with entitlement)
- Open-Meteo REST API (no API key required)

| Command | Description |
|---------|-------------|
| `current <location>` | Current weather conditions |
| `forecast <location>` | 7-day forecast |
| `hourly <location>` | Hourly forecast (up to 168 hours) |

**Options:**
- `--backend weatherkit` - Use Apple WeatherKit (default)
- `--backend open-meteo` - Use Open-Meteo API

**Status:** Complete
**Notes:** Default uses WeatherKit with signed binary. Open-Meteo available as fallback (<10K calls/day free). Location can be city name or lat,lon coordinates. Fahrenheit default with Celsius in parentheses. Supports `--json` output.

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

### Code Signing
For distribution and WeatherKit support:
```bash
make release-signed SIGNING_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
```

Requirements for WeatherKit:
1. Apple Developer Program membership
2. Developer ID Application certificate
3. App ID registered with WeatherKit capability
4. Provisioning profile with `com.apple.developer.weatherkit` entitlement

### Permissions
Each subcommand may require specific entitlements:
- Calendar/Reminders: `com.apple.security.personal-information.calendars`
- Contacts: `com.apple.security.personal-information.addressbook`
- Photos: `com.apple.security.personal-information.photos-library`
- Weather (WeatherKit): `com.apple.developer.weatherkit`

### Output Format
- Default: Human-readable
- `--json` flag: Machine-parseable JSON
- `--quiet` flag: Minimal output for scripting

### Error Handling
- Permission denied: Clear message with System Preferences deep link
- Not found: Exit code 1 with descriptive message
- Network errors: Retry logic where applicable
