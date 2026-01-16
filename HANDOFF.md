# Handoff: sysm - Unified Apple Ecosystem CLI

## CONTEXT

**What is sysm?**
A Swift CLI tool providing terminal/AI-friendly access to Apple ecosystem services on macOS. Single binary with subcommand structure: `sysm <service> <action> [args]`

**Current State:** Phase 1-3 complete. All Apple app integrations functional. Code review remediation in progress (Critical/High complete, Medium 10/12 done).

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

## WHAT'S COMPLETE (Phases 1-3)

| Service | Framework | Commands |
|---------|-----------|----------|
| `calendar` | EventKit | calendars, today, week, list, search, add, edit, delete, validate |
| `reminders` | EventKit | lists, list, today, add, complete, validate, track, dismiss, tracked, done, untrack, new, sync |
| `notes` | AppleScript | check, list, folders, import |
| `contacts` | Contacts.framework | search, show, email, phone, birthdays, groups |
| `mail` | AppleScript | unread, inbox, read, search, accounts, draft |
| `messages` | AppleScript | send, recent, read |
| `safari` | AppleScript+plist | rl, bookmarks, tabs |
| `shortcuts` | CLI wrapper | list, run |
| `focus` | AppleScript+defaults | status, dnd, list |
| `tags` | xattr | list, add, remove, find |
| `spotlight` | mdfind wrapper | search, kind, modified, metadata |
| `music` | AppleScript | play, pause, next, prev, status, volume, playlists, search |
| `photos` | PhotoKit | albums, list, recent, search, export |
| `schedule` | launchd | add, list, show, remove, enable, disable, run, logs |
| `plugin` | Custom | list, info, create, install, remove, run |
| `workflow` | YAML engine | list, new, run, validate |
| `exec` | Shell | run |
| `weather` | Open-Meteo API | current, forecast, hourly |

---

## ARCHITECTURE

```
sysm/
├── Package.swift
├── ROADMAP.md
└── Sources/sysm/
    ├── Sysm.swift                    # @main entry point
    ├── Commands/                     # 18 service command groups
    │   ├── Calendar/                 # 10 files
    │   ├── Reminders/                # 14 files
    │   ├── Notes/                    # 5 files
    │   ├── Contacts/                 # 6 files
    │   ├── Mail/                     # 7 files
    │   ├── Messages/                 # 4 files
    │   ├── Safari/                   # 4 files
    │   ├── Shortcuts/                # 3 files
    │   ├── Focus/                    # 4 files
    │   ├── Tags/                     # 5 files
    │   ├── Spotlight/                # 5 files
    │   ├── Music/                    # 10 files
    │   ├── Photos/                   # 6 files
    │   ├── Schedule/                 # 10 files
    │   ├── Plugin/                   # 7 files
    │   ├── Workflow/                 # 5 files
    │   └── Exec/                     # 2 files
    ├── Models/
    │   ├── CalendarEvent.swift
    │   ├── Reminder.swift
    │   ├── TrackedReminder.swift
    │   ├── SysmCache.swift
    │   └── Note.swift
    ├── Services/
    │   ├── ServiceContainer.swift    # DI container
    │   ├── CalendarService.swift     # actor, EventKit
    │   ├── ReminderService.swift     # actor, EventKit
    │   ├── NotesService.swift        # AppleScript via Process
    │   └── ... (15 services total)
    ├── Protocols/                    # Service abstractions
    │   ├── CalendarServiceProtocol.swift
    │   └── ... (15 protocols)
    └── Utilities/
        ├── OutputFormatter.swift     # JSON output helper
        ├── AppleScriptRunner.swift   # Shared AS execution
        └── AnyCodable.swift          # Type-erased wrapper
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

## WHAT'S NEXT

See `ROADMAP.md` and `TODO-REVIEW20260115.md` for details.

**Feature Ideas:**
- Configuration system (`~/.sysm/config.yaml`)
- Better DateParser (natural language: "in 2 hours", "next week")
- Weather alerts integration

**Remaining Code Review Items:**
- Low priority: 6 items (access control, validation, caching)
- Missing documentation: DocC comments for public APIs

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
