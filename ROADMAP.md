# sysm Roadmap

Unified CLI for Apple ecosystem integration on macOS.

**Last Updated:** 2025-01-30

---

## Status Legend

- `[x]` Completed
- `[ ]` Planned
- `[~]` In progress
- `[-]` Won't implement (API limitation)

## Priority Legend

- **P0** - Critical / Most requested
- **P1** - High priority
- **P2** - Medium priority
- **P3** - Low priority / Nice to have

---

## Phase 1 - Core PIM (Completed)

Foundation established with calendar, reminders, and notes integration.

| Subcommand | Framework | Status |
|------------|-----------|--------|
| `sysm calendar` | EventKit | Done |
| `sysm reminders` | EventKit | Done |
| `sysm notes` | AppleScript | Done |

Migrated from standalone tools: dayai-calendar, dayai-reminders, dayai-notes.

### Calendar (EventKit)

**Implemented:**
- [x] List calendars
- [x] Get events by date range
- [x] Get today's events
- [x] Get this week's events
- [x] Search events
- [x] Add event (title, dates, calendar, location, notes, all-day, recurrence, alarms, URL, availability)
- [x] Get event by ID
- [x] Delete event by title
- [x] Edit event (title, start date, end date)
- [x] Validate events (find invalid dates)
- [x] Read attendees (read-only)
- [x] Read alarms

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P0 | [ ] Edit event: location | Update event location | `event.location = "..."` |
| P0 | [ ] Edit event: notes | Update event notes | `event.notes = "..."` |
| P0 | [ ] Edit event: calendar | Move event to different calendar | `event.calendar = newCalendar` |
| P0 | [ ] Edit event: all-day | Toggle all-day status | `event.isAllDay = true/false` |
| P1 | [ ] Edit event: alarms | Add/remove/modify alarms | `event.addAlarm()`, `event.removeAlarm()` |
| P1 | [ ] Edit event: recurrence | Modify repeat rules | `event.addRecurrenceRule()` |
| P1 | [ ] Edit event: URL | Update event URL | `event.url = URL(...)` |
| P1 | [ ] Edit event: availability | Change busy/free status | `event.availability = .busy` |
| P1 | [ ] Delete event by ID | Delete using event identifier | `store.remove(event, span:)` |
| P2 | [ ] Create calendar | Create new calendar | `EKCalendar(for: .event, eventStore:)` |
| P2 | [ ] Delete calendar | Remove calendar | `store.removeCalendar(_:commit:)` |
| P2 | [ ] Set calendar color | Change calendar display color | `calendar.cgColor` |
| P2 | [ ] Get calendar details | Source, type, subscription status | Various `EKCalendar` properties |
| P3 | [ ] Travel time | Event travel time settings | `event.travelTime` |
| P3 | [ ] Structured location | Location with coordinates | `EKStructuredLocation` |

---

### Reminders (EventKit)

**Implemented:**
- [x] List reminder lists
- [x] Get reminders (by list, include completed option)
- [x] Get today's reminders
- [x] Add reminder (title, list, due date, priority, notes, URL, recurrence)
- [x] Edit reminder (title, due date, priority, notes)
- [x] Delete reminder by ID
- [x] Create reminder list
- [x] Delete reminder list
- [x] Complete reminder by name
- [x] Validate reminders (find invalid dates)

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P0 | [ ] Start date | Set reminder start date (not just due) | `reminder.startDateComponents` |
| P0 | [ ] Complete reminder by ID | More reliable than by name | Use `calendarItemIdentifier` |
| P1 | [ ] Location-based reminder | Trigger on arrive/leave location | `EKStructuredLocation`, geofence |
| P1 | [ ] Edit reminder: list | Move reminder to different list | `reminder.calendar = newList` |
| P1 | [ ] Flagged status | Mark reminder as flagged | Available in newer EventKit |
| P2 | [ ] Alarm management | Add/remove reminder alarms | `reminder.addAlarm()` |
| P2 | [ ] Search reminders | Find reminders by text content | Custom predicate filtering |
| P2 | [ ] Get overdue reminders | Reminders past due date | Filter by `dueDateComponents` |
| P3 | [ ] Subtasks | Nested reminders (if API supports) | Limited EventKit support |
| P3 | [ ] Images/attachments | Reminder attachments | Very limited support |

---

### Notes (AppleScript)

**Implemented:**
- [x] List folders
- [x] List notes (by folder)
- [x] Get note by ID
- [x] Get all notes from folder
- [x] Count notes in folder
- [x] Create note
- [x] Update note (name, body)
- [x] Delete note
- [x] Create folder
- [x] Delete folder

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P0 | [ ] Move note to folder | Relocate note between folders | `move note to folder "name"` |
| P0 | [ ] Search notes by content | Find notes containing specific text | `notes whose body contains "query"` |
| P1 | [ ] Get note attachments | List attachments in a note | `attachments of note` |
| P2 | [ ] Add attachment to note | Attach file to existing note | Limited support via `make new attachment` |
| P2 | [ ] Show note in UI | Open note in Notes.app | `show note` |
| P3 | [ ] Get shared status | Check if note is shared | `shared` property |
| P3 | [ ] Get note password status | Check if note is locked | `password protected` property |

---

## Phase 2 - Extended Apple Apps (Completed)

### Contacts (Contacts.framework)

| Command | Description |
|---------|-------------|
| `search <query>` | Search contacts by name, email, phone |
| `show <id>` | Display full contact details |
| `email <query>` | Get email addresses matching query |
| `phone <query>` | Get phone numbers matching query |
| `birthdays` | List upcoming birthdays |
| `groups` | List contact groups |

**Status:** Complete. Requires Contacts permission. Uses actor-based ContactsService for thread safety.

**Implemented:**
- [x] Search by name
- [x] Get contact by identifier
- [x] Search by email
- [x] Search by phone
- [x] Get upcoming birthdays
- [x] List groups
- [x] Create contact (full properties)
- [x] Update contact
- [x] Delete contact

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P0 | [ ] Create group | Create new contact group | `CNSaveRequest.add(group, toContainerWithIdentifier:)` |
| P0 | [ ] Delete group | Remove contact group | `CNSaveRequest.delete(group)` |
| P0 | [ ] Add contact to group | Associate contact with group | `CNSaveRequest.addMember(_:to:)` |
| P0 | [ ] Remove contact from group | Disassociate contact from group | `CNSaveRequest.removeMember(_:from:)` |
| P1 | [ ] Get contacts in group | List all members of a group | `predicateForContactsInGroup(withIdentifier:)` |
| P1 | [ ] List all contacts | Paginated list of all contacts | `enumerateContacts(with:)` |
| P2 | [ ] Get contact image | Retrieve contact photo | `imageData`, `thumbnailImageData` |
| P2 | [ ] Set contact image | Update contact photo | `CNMutableContact.imageData` |
| P2 | [ ] Search by organization | Find contacts by company name | `predicateForContacts(matchingName:)` with org |
| P3 | [ ] Linked contacts | Handle unified/linked contacts | `CNContact.isUnifiedWithContact` |
| P3 | [ ] Container management | Work with different accounts | `CNContainer` operations |
| P3 | [ ] Recent contacts | Get recently used contacts | Not directly available |

---

### Mail (AppleScript)

| Command | Description |
|---------|-------------|
| `unread [--account NAME]` | List unread messages |
| `inbox [--account NAME] [--limit N]` | Show recent inbox messages |
| `read <id>` | Display message content |
| `search <query> [--account NAME]` | Search messages |
| `accounts` | List configured accounts |
| `draft` | Create new draft (opens Mail.app) |

**Status:** Complete. Supports `--json` output. Use `--account` to filter by account name.

**Implemented:**
- [x] Get accounts
- [x] Get inbox messages (with account filter)
- [x] Get unread messages (with account filter)
- [x] Get message details (subject, from, to, cc, reply-to, dates, content, attachments)
- [x] Create draft
- [x] Mark read/unread
- [x] Delete message
- [x] List mailboxes
- [x] Move message to mailbox
- [x] Flag/unflag message
- [x] Search (query, body, date range)
- [x] Send message

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P0 | [ ] Get messages from any mailbox | Currently only reads inbox; should support Sent, Drafts, Archive, etc. | `messages of mailbox "name"` |
| P1 | [ ] Reply to message | Create draft with quoted original content and proper headers | Build reply draft with `make new outgoing message` |
| P1 | [ ] Forward message | Forward with original content and attachments | Similar to reply |
| P2 | [ ] List drafts | Get messages from Drafts mailbox | `messages of drafts mailbox` |
| P2 | [ ] Edit draft | Modify existing draft before sending | Access draft, modify properties |
| P2 | [ ] Delete draft | Remove unsent draft | `delete message` on draft |
| P3 | [ ] Archive message | Move to Archive mailbox | `move message to mailbox "Archive"` |
| P3 | [ ] Get message headers | Access raw email headers | Limited AppleScript support |

---

### Messages (AppleScript)

| Command | Description |
|---------|-------------|
| `send <recipient> <message>` | Send iMessage/SMS |
| `recent [--limit N]` | List recent conversations |
| `read <conversation>` | Show messages in conversation |

**Status:** Complete. Uses AppleScript via MessagesService. Supports `--json` output.

**Implemented:**
- [x] Send message (iMessage)
- [x] Get recent conversations
- [x] Get messages from conversation

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P1 | [ ] Send to phone number | Send via SMS (if available) | Service type handling |
| P1 | [ ] Get unread count | Number of unread messages | Not directly available; workaround needed |
| P2 | [ ] Search messages | Find messages by content | `messages whose text contains` |
| P2 | [ ] Send to group | Send to group chat | Group chat participant handling |
| P2 | [ ] Get conversation by participant | Find chat by phone/email | `chat whose participants contains` |
| P3 | [ ] Send attachment | Send image/file | Very limited AppleScript support |
| P3 | [ ] Get attachments | List message attachments | `attachments of message` |
| P3 | [ ] Start new conversation | Create chat with new participant | `make new chat` |
| [-] | Delete message | Remove sent message | Not supported via AppleScript |
| [-] | Edit message | Modify sent message | Not supported via AppleScript |
| [-] | Reactions | Add/view tapback reactions | Not supported via AppleScript |

---

### Safari (AppleScript + plist)

| Command | Description |
|---------|-------------|
| `rl` | List reading list items |
| `rl add <url>` | Add URL to reading list |
| `bookmarks` | List bookmarks |
| `tabs` | List open tabs across windows |

**Status:** Complete. Reading list and bookmarks parsed from `~/Library/Safari/Bookmarks.plist`. Supports `--json` output.

**Implemented:**
- [x] Get reading list
- [x] Add to reading list
- [x] Get bookmarks (parsed from plist)
- [x] Get open tabs

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P0 | [ ] Open URL in tab | Navigate to URL | `tell Safari to open location "url"` |
| P0 | [ ] Open URL in new tab | Open in new tab | `make new tab with properties {URL:"..."}` |
| P1 | [ ] Close tab | Close specific tab | `close tab N of window M` |
| P1 | [ ] New window | Open new Safari window | `make new document` |
| P1 | [ ] Reload tab | Refresh current page | `do JavaScript "location.reload()"` or URL reassign |
| P2 | [ ] Get current URL | URL of frontmost tab | `URL of current tab of window 1` |
| P2 | [ ] Get page title | Title of current page | `name of current tab` |
| P2 | [ ] Go back/forward | Navigate history | Limited support |
| P3 | [ ] Remove from reading list | Delete reading list item | No AppleScript support |
| P3 | [ ] Mark reading list read | Toggle read status | No AppleScript support |
| P3 | [ ] Create bookmark | Add new bookmark | Plist is read-only; limited AppleScript |
| P3 | [ ] Delete bookmark | Remove bookmark | No reliable API |
| P3 | [ ] Execute JavaScript | Run JS in page | `do JavaScript` (requires permissions) |

---

### Shortcuts (CLI wrapper)

| Command | Description |
|---------|-------------|
| `list` | List available shortcuts |
| `run <name>` | Execute a shortcut |

**Status:** Complete. Wrapper around `/usr/bin/shortcuts`. Supports `--json` and `--input`.

**Implemented:**
- [x] List shortcuts
- [x] Run shortcut (with optional input)

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P2 | [ ] Get shortcut details | Show shortcut info/actions | `shortcuts view` (limited) |
| P2 | [ ] Run with file input | Pass file path as input | `--input-path` flag |
| P2 | [ ] Get output | Capture shortcut output | Already works with stdout |
| P3 | [ ] List by folder | Filter shortcuts by folder | `shortcuts list --folder` |
| P3 | [ ] Sign shortcut | Code sign for sharing | `shortcuts sign` |
| [-] | Create shortcut | Programmatic creation | No CLI support |
| [-] | Edit shortcut | Modify existing shortcut | No CLI support |
| [-] | Export shortcut | Export to file | Limited support |

---

### Focus (AppleScript + defaults)

| Command | Description |
|---------|-------------|
| `status` | Show current focus mode |
| `dnd on` | Enable Do Not Disturb |
| `dnd off` | Disable Do Not Disturb |
| `list` | List available focus modes |

**Status:** Complete. Supports `--json` output.

**Implemented:**
- [x] Get focus status
- [x] Enable Do Not Disturb
- [x] Disable Do Not Disturb
- [x] List focus modes
- [x] Activate focus mode (via Shortcuts)
- [x] Deactivate focus

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P1 | [ ] Set focus duration | Enable for specific time period | Requires Shortcuts |
| P1 | [ ] Set focus until time | Enable until specific time | Requires Shortcuts |
| P2 | [ ] Schedule focus | Set automatic schedule | No public API |
| P3 | [ ] Get focus schedule | Read configured schedules | Parse ModeConfigurations.json |
| [-] | Configure focus mode | Set allowed apps/people | No public API |
| [-] | Create focus mode | Define new focus mode | No public API |
| [-] | Focus filters | Configure app-specific behavior | No public API |

---

## Phase 3 - Extended System Integration (Completed)

### Finder Tags (xattr)

| Command | Description |
|---------|-------------|
| `list <path>` | List tags on file/folder |
| `add <path> --tag <name>` | Add tag to file |
| `remove <path> --tag <name>` | Remove tag from file |
| `set <path> --tags <list>` | Replace all tags atomically |
| `find <tag>` | Find files with tag |

**Status:** Complete. Uses `getxattr`/`setxattr`. Tag colors (0-7) supported.

**Implemented:**
- [x] Get tags from file
- [x] Set tags on file
- [x] Add single tag
- [x] Remove single tag
- [x] Find files by tag
- [x] Tag color support (0-7)
- [x] Scope search to directory

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P2 | [ ] List all tags in directory | Enumerate unique tags | Scan files with mdfind |
| P2 | [ ] Batch tag files | Tag multiple files at once | Loop or parallel operation |
| P2 | [ ] Clear all tags | Remove all tags from file | Set empty tag array |
| P3 | [ ] Get system tag list | List Finder sidebar tags | Read from preferences |
| P3 | [ ] Rename tag | Change tag name across files | Find and update all |
| P3 | [ ] Tag statistics | Count files per tag | Aggregate mdfind results |

---

### Spotlight (mdfind wrapper)

| Command | Description |
|---------|-------------|
| `search <query>` | Search files by content/name |
| `kind <type>` | Search by file type |
| `modified <days>` | Files modified in last N days |
| `metadata <path>` | Show file metadata |

**Status:** Complete. Wraps `/usr/bin/mdfind` and `/usr/bin/mdls`. Supports `--json` output.

**Implemented:**
- [x] Search by query
- [x] Search by file kind
- [x] Search by modification date
- [x] Get file metadata
- [x] Scope to directory

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P1 | [ ] Search by name | Find files by filename | `-name` flag or `kMDItemFSName` |
| P1 | [ ] Search by extension | Find by file extension | `kMDItemFSName == "*.ext"` |
| P2 | [ ] Search by content | Full-text content search | `kMDItemTextContent` |
| P2 | [ ] Search by author | Find by document author | `kMDItemAuthors` |
| P2 | [ ] Search by creation date | Find by creation time | `kMDItemContentCreationDate` |
| P2 | [ ] Combined queries | Boolean AND/OR searches | Query syntax already supported |
| P2 | [ ] Search by size | Find files by size range | `kMDItemFSSize` |
| P3 | [ ] Live query | Watch for changes | `-live` flag |
| P3 | [ ] Count results | Get result count only | `-count` flag |
| P3 | [ ] Interpret query | Natural language search | `-interpret` flag |

---

### Music (AppleScript)

| Command | Description |
|---------|-------------|
| `play` | Start/resume playback |
| `pause` | Pause playback |
| `next` / `prev` | Track navigation |
| `status` | Show now playing |
| `volume <0-100>` | Set volume |
| `playlists` | List playlists |
| `search <query>` | Search library |

**Status:** Complete. AppleScript-based control. Supports `--json` output.

**Implemented:**
- [x] Play / Pause
- [x] Next / Previous track
- [x] Volume control (0-100)
- [x] Get now playing status
- [x] List playlists
- [x] Search library
- [x] Get/set shuffle mode
- [x] Get/set repeat mode
- [x] Play playlist by name
- [x] Play track by search query

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P0 | [ ] Create playlist | Create new user playlist | `make new user playlist with properties {name:"..."}` |
| P0 | [ ] Delete playlist | Remove user playlist | `delete playlist "name"` |
| P0 | [ ] Add track to playlist | Add song to existing playlist | `duplicate track to playlist` |
| P1 | [ ] Remove track from playlist | Remove song from playlist | `delete track of playlist` |
| P1 | [ ] Rate track | Set 1-5 star rating | `set rating of track to N` (0-100 scale) |
| P1 | [ ] Love/dislike track | Mark track as loved or disliked | `set loved of track to true/false` |
| P2 | [ ] Get track details | Full track metadata | Multiple properties available |
| P2 | [ ] Get album artwork | Extract album art image | `raw data of artwork 1 of track` |
| P2 | [ ] Seek to position | Jump to specific time in track | `set player position to N` |
| P2 | [ ] Get current volume | Read current volume level | `sound volume` |
| P3 | [ ] Add to Up Next | Queue track to play next | Limited support |
| P3 | [ ] Clear Up Next | Clear play queue | Limited support |
| P3 | [ ] Get lyrics | Access track lyrics | `lyrics of track` |
| P3 | [ ] AirPlay control | Select AirPlay speakers | Very limited API |

---

### Photos (PhotoKit)

| Command | Description |
|---------|-------------|
| `albums` | List photo albums |
| `list <album-id>` | Photos in album |
| `recent` | Recent photos |
| `search --from/--to` | Search by date range |
| `export <asset-id>` | Export photo to file |

**Status:** Complete. Requires Photos permission. Actor-based service. Supports `--json` output.

**Implemented:**
- [x] List albums (user and smart)
- [x] List photos (with album filter, limit)
- [x] Get recent photos
- [x] Search by date range
- [x] Export photo
- [x] List videos
- [x] Export video
- [x] Get full metadata (EXIF, location, camera info)

**To Do:**

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P0 | [ ] Create album | Create new photo album | `PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle:)` |
| P0 | [ ] Delete album | Remove photo album | `PHAssetCollectionChangeRequest.deleteAssetCollections()` |
| P0 | [ ] Add photos to album | Add assets to album | `PHAssetCollectionChangeRequest.addAssets()` |
| P0 | [ ] Remove photos from album | Remove assets from album | `PHAssetCollectionChangeRequest.removeAssets()` |
| P1 | [ ] Favorite photo | Mark as favorite | `PHAssetChangeRequest.isFavorite = true` |
| P1 | [ ] Unfavorite photo | Remove favorite status | `PHAssetChangeRequest.isFavorite = false` |
| P1 | [ ] Get favorites | List all favorited photos | Predicate `isFavorite == true` |
| P2 | [ ] Delete photo | Remove photo from library | `PHAssetChangeRequest.deleteAssets()` (requires user confirmation) |
| P2 | [ ] Search by filename | Find by original filename | `PHAssetResource.originalFilename` filtering |
| P2 | [ ] Search by location | Find photos near coordinates | `CLLocation` based predicate |
| P2 | [ ] Get hidden photos | Access hidden album | `PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumAllHidden)` |
| P3 | [ ] Import photo | Add new photo to library | `PHAssetCreationRequest` |
| P3 | [ ] Get People albums | Face recognition albums | `PHCollectionList` for People |
| P3 | [ ] Live Photo components | Access photo + video | `PHLivePhoto` |
| P3 | [ ] RAW + JPEG pairs | Handle RAW photo pairs | `PHAssetResource` analysis |

---

## Phase 4 - Automation (Completed)

### Script Execution

| Command | Description |
|---------|-------------|
| `exec <script>` | Run a script file |
| `exec -c <cmd>` | Run inline command |
| `exec --shell <type>` | Specify shell (bash, zsh, sh) |
| `exec --python` | Run Python script |
| `exec --applescript` | Run AppleScript |

**Status:** Complete. Supports shell scripts, Python, AppleScript, and Swift with timeout and error handling.

---

### Workflows (YAML engine)

| Command | Description |
|---------|-------------|
| `workflow run <file>` | Execute a workflow |
| `workflow validate <file>` | Validate workflow syntax |
| `workflow list` | List available workflows |
| `workflow new <name>` | Create workflow scaffold |

**Status:** Complete. YAML-based multi-step automations with variable passing, conditionals, retries, and templates. Stored in `~/.sysm/workflows/`. Supports `--dry-run` and `--verbose`.

---

### Scheduling (launchd)

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

**Status:** Complete. Uses macOS launchd for persistent scheduling. Supports cron syntax and interval-based triggers.

---

### Plugins (Shell scripts)

| Command | Description |
|---------|-------------|
| `plugin list` | List installed plugins |
| `plugin create <name>` | Create plugin scaffold |
| `plugin install <path>` | Install from directory |
| `plugin remove <name>` | Uninstall plugin |
| `plugin run <plugin> <cmd>` | Execute plugin command |
| `plugin info <name>` | Show plugin details |

**Status:** Complete. Extend sysm with custom commands. Plugins stored in `~/.sysm/plugins/` with `plugin.yaml` manifest.

---

## Phase 5 - External APIs (Completed)

### Weather

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

**Status:** Complete. Location can be city name or lat,lon coordinates. Fahrenheit default with Celsius in parentheses. Supports `--json` output.

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

---

## API Limitations

Some features cannot be implemented due to macOS API restrictions:

1. **Messages**: No API for editing/deleting sent messages, reactions, or read receipts
2. **Focus**: No public API for configuring focus mode settings
3. **Shortcuts**: No CLI support for creating or editing shortcuts
4. **Safari Reading List**: No AppleScript support for removing items
5. **Safari Bookmarks**: Plist is read-only; no reliable write API
6. **Photos**: Deletion requires user confirmation dialog
7. **Notes**: Locked notes cannot be accessed programmatically

---

## Testing Considerations

- EventKit operations require appropriate entitlements and user permission
- Photos operations require Photos library permission
- AppleScript operations may trigger automation permission dialogs
- Some operations may behave differently on different macOS versions

---

## Contributing

When implementing features from this roadmap:

1. Check the box and add implementation date
2. Update the corresponding command's help text
3. Add tests for new functionality
4. Update the main README if adding new commands

### Breaking Changes

When implementing new features:
- Maintain backward compatibility with existing command flags
- Add new subcommands rather than changing existing behavior
- Use optional parameters with sensible defaults
- Document any required permissions
