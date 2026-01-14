# Handoff: sysm - Unified Apple Ecosystem CLI

## CONTEXT

**What is sysm?**
A Swift CLI tool providing terminal/AI-friendly access to Apple ecosystem services on macOS. Single binary with subcommand structure: `sysm <service> <action> [args]`

**Current State:** Phase 1 complete. Phase 2e (Shortcuts) complete. Calendar, Reminders, Notes, and Shortcuts are fully functional.

**Owner:** Brandon Seaver (network engineer, prefers Go/Python, learning Swift)

**Tech Stack:**
- Swift 5.9+ with Swift Package Manager
- swift-argument-parser for CLI structure
- EventKit framework for Calendar/Reminders
- AppleScript (via Process) for Notes
- Actor-based services for thread safety

**Project Location:** `~/code/sysm/`

**Binary Install:** `swift build -c release && cp .build/release/sysm ~/bin/`

---

## WHAT'S COMPLETE (Phase 1)

### sysm calendar
EventKit-based. 9 subcommands.
```
calendars    - List all calendars
today        - Show today's events
week         - Show this week's events
list         - List events for date/range
search       - Search by title/location/notes
add          - Create event (natural language dates)
edit         - Modify existing event
delete       - Remove event
validate     - Find events with invalid dates
```

### sysm reminders
EventKit-based. 13 subcommands.
```
lists        - List reminder lists
list         - List incomplete reminders
today        - Due today
add          - Create reminder
complete     - Mark complete in Apple Reminders
validate     - Find invalid dates
track        - Add to local tracking (for reporting)
dismiss      - Mark seen, don't track
tracked      - Show tracked reminders
done         - Mark tracked item done
untrack      - Remove from tracking
new          - Show reminders not yet seen
sync         - Write tracked reminders to external file
```

### sysm notes
AppleScript-based. 4 subcommands.
```
check        - Check for new notes
list         - List notes in folder
folders      - List all folders
import       - Export to markdown files
```

### sysm shortcuts
Shell wrapper around /usr/bin/shortcuts. 2 subcommands.
```
list         - List available shortcuts (supports --json)
run <name>   - Execute a shortcut (supports --input)
```

---

## ARCHITECTURE

```
sysm/
├── Package.swift
├── ROADMAP.md
└── Sources/sysm/
    ├── Sysm.swift                    # @main entry point
    ├── Commands/
    │   ├── Calendar/
    │   │   ├── CalendarCommand.swift # Subcommand group
    │   │   ├── CalendarToday.swift
    │   │   └── ... (9 files)
    │   ├── Reminders/
    │   │   ├── RemindersCommand.swift
    │   │   └── ... (13 files)
    │   ├── Notes/
    │   │   ├── NotesCommand.swift
    │   │   └── ... (4 files)
    │   └── Shortcuts/
    │       ├── ShortcutsCommand.swift
    │       └── ... (2 files)
    ├── Models/
    │   ├── CalendarEvent.swift
    │   ├── Reminder.swift
    │   ├── TrackedReminder.swift     # + SysmCache
    │   └── Note.swift
    └── Services/
        ├── CalendarService.swift     # actor, EventKit
        ├── ReminderService.swift     # actor, EventKit
        ├── NotesService.swift        # AppleScript via Process
        ├── ShortcutsService.swift    # /usr/bin/shortcuts wrapper
        ├── CacheService.swift        # ~/.sysm_cache.json
        ├── TriggerService.swift      # Writes to external MD file
        ├── DateParser.swift          # Natural language dates
        └── MarkdownExporter.swift    # Notes → .md conversion
```

### Key Patterns

**Naming Convention:** Commands prefixed with service name to avoid Swift conflicts.
- `CalendarToday`, `CalendarList` (not `TodayCommand`, `ListCommand`)
- Avoids collision with `Foundation.Calendar`

**Service Pattern:** Actor-based for EventKit thread safety.
```swift
actor CalendarService {
    private let store = EKEventStore()
    func ensureAccess() async throws { ... }
}
```

**Output Modes:** Most commands support:
- Default: Human-readable
- `--json`: Machine-parseable
- `--quiet` (some): Minimal output

**Date Handling:** Use `Foundation.Calendar.current` explicitly (not just `Calendar.current`) to avoid naming conflicts.

---

## EXTERNAL DEPENDENCIES

**Runtime only - no code dependencies:**

1. **Cache file:** `~/.sysm_cache.json`
   - Stores tracked reminders state
   - Created automatically by CacheService

2. **TRIGGER.md sync** (optional):
   - `TriggerService.swift` line 8: `~/dayai/_dayai/TRIGGER.md`
   - Only used by `sysm reminders sync`
   - Can be made configurable or removed for standalone use

---

## WHAT'S NEXT (Phase 2)

See `ROADMAP.md` for full details. Priority order:

| Phase | Subcommand | Complexity | Framework |
|-------|------------|------------|-----------|
| 2e | `sysm shortcuts` | Low | Wrapper around `/usr/bin/shortcuts` |
| 2d | `sysm safari` | Low-Medium | AppleScript + plist |
| 2a | `sysm contacts` | Medium | Contacts.framework |
| 2f | `sysm focus` | Low-Medium | defaults + AppleScript |
| 2b | `sysm mail` | Medium | AppleScript |
| 2c | `sysm messages` | Medium-High | AppleScript (limited) |

### Quick Win: sysm shortcuts

Simplest addition - wrapper around existing macOS CLI:
```swift
// Just shell out to /usr/bin/shortcuts
// Parse JSON output
// Commands: list, run <name>
```

### Quick Win: sysm safari

Reading list from plist + AppleScript for tabs:
```swift
// ~/Library/Safari/Bookmarks.plist for reading list
// AppleScript for open tabs
// Commands: rl, rl add <url>, bookmarks, tabs
```

---

## SESSION BOUNDARIES

**Start:** Pick a Phase 2 item from ROADMAP.md and implement it.

**End:** When the new subcommand is complete and tested:
1. Update ROADMAP.md (mark complete)
2. Run `swift build -c release` to verify
3. Test the new commands manually
4. Summarize what was built

---

## GUARDRAILS

**In Scope:**
- Adding new subcommand groups (contacts, mail, safari, etc.)
- Creating new Services for Apple frameworks
- Adding models as needed
- Updating ROADMAP.md

**Out of Scope:**
- Modifying the TriggerService TRIGGER.md path (that's dayai-specific)
- Any changes outside ~/code/sysm/
- Breaking existing calendar/reminders/notes functionality

**Code Style:**
- Prefix all command structs with service name
- Use `Foundation.Calendar.current` not `Calendar.current`
- Actor pattern for framework services
- Support `--json` flag on list/query commands
- Match existing patterns in the codebase

**If Uncertain:**
- Check how existing services handle similar problems
- Prefer AppleScript via Process for apps without public frameworks
- Ask before architectural changes

---

## BUILD & TEST

```bash
cd ~/code/sysm

# Build
swift build

# Build release
swift build -c release

# Run directly
.build/debug/sysm --help
.build/debug/sysm calendar today

# Install
cp .build/release/sysm ~/bin/

# Test installed
sysm --help
```

---

## OUTPUT FORMAT

When adding a new service, create:
1. `Commands/<Service>/<Service>Command.swift` - subcommand group
2. `Commands/<Service>/<Service><Action>.swift` - each subcommand
3. `Services/<Service>Service.swift` - business logic
4. `Models/<Model>.swift` - data structures (if needed)
5. Update `Sysm.swift` to register the new command group

---

## START

Review ROADMAP.md, pick a Phase 2 item, and implement it following the patterns established in the Calendar/Reminders/Notes modules. Start with `sysm shortcuts` or `sysm safari` for quick wins.
