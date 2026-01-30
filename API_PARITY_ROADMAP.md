# Sysm API Parity Roadmap

This document tracks the gaps between sysm CLI commands and the underlying macOS system APIs. Each item represents functionality that the native API supports but is not yet exposed through sysm.

**Last Updated:** 2025-01-30

---

## Status Legend

- `[ ]` Not started
- `[~]` In progress
- `[x]` Completed
- `[-]` Won't implement (API limitation or out of scope)

## Priority Legend

- **P0** - Critical / Most requested
- **P1** - High priority
- **P2** - Medium priority
- **P3** - Low priority / Nice to have

---

## 1. Mail Service

**API:** AppleScript → Mail.app

### Implemented
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

### To Do

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

## 2. Notes Service

**API:** AppleScript → Notes.app

### Implemented
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

### To Do

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

## 3. Music Service

**API:** AppleScript → Music.app

### Implemented
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

### To Do

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

## 4. Calendar Service

**API:** EventKit Framework

### Implemented
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

### To Do

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

## 5. Reminders Service

**API:** EventKit Framework

### Implemented
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

### To Do

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

## 6. Contacts Service

**API:** Contacts Framework

### Implemented
- [x] Search by name
- [x] Get contact by identifier
- [x] Search by email
- [x] Search by phone
- [x] Get upcoming birthdays
- [x] List groups
- [x] Create contact (full properties)
- [x] Update contact
- [x] Delete contact

### To Do

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

## 7. Photos Service

**API:** Photos Framework (PHPhotoLibrary)

### Implemented
- [x] List albums (user and smart)
- [x] List photos (with album filter, limit)
- [x] Get recent photos
- [x] Search by date range
- [x] Export photo
- [x] List videos
- [x] Export video
- [x] Get full metadata (EXIF, location, camera info)

### To Do

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

## 8. Safari Service

**API:** Plist + AppleScript → Safari

### Implemented
- [x] Get reading list
- [x] Add to reading list
- [x] Get bookmarks (parsed from plist)
- [x] Get open tabs

### To Do

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

## 9. Messages Service

**API:** AppleScript → Messages.app

### Implemented
- [x] Send message (iMessage)
- [x] Get recent conversations
- [x] Get messages from conversation

### To Do

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

## 10. Focus Service

**API:** Defaults + AppleScript/Shortcuts + JSON files

### Implemented
- [x] Get focus status
- [x] Enable Do Not Disturb
- [x] Disable Do Not Disturb
- [x] List focus modes
- [x] Activate focus mode (via Shortcuts)
- [x] Deactivate focus

### To Do

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

## 11. Shortcuts Service

**API:** `/usr/bin/shortcuts` CLI

### Implemented
- [x] List shortcuts
- [x] Run shortcut (with optional input)

### To Do

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

## 12. Spotlight Service

**API:** `/usr/bin/mdfind` + `/usr/bin/mdls`

### Implemented
- [x] Search by query
- [x] Search by file kind
- [x] Search by modification date
- [x] Get file metadata
- [x] Scope to directory

### To Do

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

## 13. Tags Service

**API:** Extended attributes (xattr) + mdfind

### Implemented
- [x] Get tags from file
- [x] Set tags on file
- [x] Add single tag
- [x] Remove single tag
- [x] Find files by tag
- [x] Tag color support (0-7)
- [x] Scope search to directory

### To Do

| Priority | Feature | Description | API Notes |
|----------|---------|-------------|-----------|
| P2 | [ ] List all tags in directory | Enumerate unique tags | Scan files with mdfind |
| P2 | [ ] Batch tag files | Tag multiple files at once | Loop or parallel operation |
| P2 | [ ] Clear all tags | Remove all tags from file | Set empty tag array |
| P3 | [ ] Get system tag list | List Finder sidebar tags | Read from preferences |
| P3 | [ ] Rename tag | Change tag name across files | Find and update all |
| P3 | [ ] Tag statistics | Count files per tag | Aggregate mdfind results |

---

## Implementation Notes

### API Limitations

Some features cannot be implemented due to macOS API limitations:

1. **Messages**: No API for editing/deleting sent messages, reactions, or read receipts
2. **Focus**: No public API for configuring focus mode settings
3. **Shortcuts**: No CLI support for creating or editing shortcuts
4. **Safari Reading List**: No AppleScript support for removing items
5. **Safari Bookmarks**: Plist is read-only; no reliable write API
6. **Photos**: Deletion requires user confirmation dialog
7. **Notes**: Locked notes cannot be accessed programmatically

### Testing Considerations

- EventKit operations require appropriate entitlements and user permission
- Photos operations require Photos library permission
- AppleScript operations may trigger automation permission dialogs
- Some operations may behave differently on different macOS versions

### Breaking Changes to Watch

When implementing new features:
- Maintain backward compatibility with existing command flags
- Add new subcommands rather than changing existing behavior
- Use optional parameters with sensible defaults
- Document any required permissions

---

## Contributing

When implementing features from this roadmap:

1. Check the box and add implementation date
2. Update the corresponding command's help text
3. Add tests for new functionality
4. Update the main README if adding new commands

---

## Version History

| Date | Changes |
|------|---------|
| 2025-01-30 | Initial roadmap created from API parity review |
