# TODO: Code Review 2026-01-15

Actionable items from REVIEW20260115.md

---

## Critical

- [x] **AppleScript injection: NotesService ID** - `Services/NotesService.swift:57-61` - escape `id` parameter ✓
- [x] **AppleScript injection: NotesService folder** - `Services/NotesService.swift:22-23` - escape folder name ✓
- [x] **Add test target to Package.swift** - `Package.swift` - add `sysmTests` target ✓

---

## High

- [x] **AppleScript injection: MusicService search** - `Services/MusicService.swift:195-199` - comprehensive escaping ✓
- [x] **mdfind injection: TagsService** - `Services/TagsService.swift:111-112` - escape single quotes ✓
- [x] **mdfind injection: SpotlightService** - `Services/SpotlightService.swift:84` - escape single quotes ✓
- [x] **Command injection: LaunchdService** - `Services/LaunchdService.swift:309-310` - N/A: intentional design (user provides shell commands) ✓
- [x] **Inconsistent async/sync** - `Commands/**/*.swift` - N/A: intentional design (EventKit=async, AppleScript=sync) ✓
- [x] **Service instantiation anti-pattern** - all command files - implement DI via ServiceContainer ✓
- [x] **Silent error swallowing: PluginManager** - `Services/PluginManager.swift:99-101` - log warnings ✓
- [x] **Silent error swallowing: WorkflowEngine** - `Services/WorkflowEngine.swift:591-596` - log warnings ✓
- [x] **Services not mockable** - all service files - add protocol abstractions (15 protocols) ✓

---

## Medium

- [x] **Force unwrapping** - `Commands/Calendar/CalendarAdd.swift:47-49` - use guard statements ✓
- [x] **Mixed concerns in TrackedReminder.swift** - `Models/TrackedReminder.swift` - split into separate files ✓
- [x] **TriggerService hardcoded path** - `Services/TriggerService.swift:7-8` - make configurable ✓
- [x] **Inconsistent error handling** - `Commands/Reminders/RemindersAdd.swift:37-39` - standardize across commands ✓
- [x] **N+1 query pattern: NotesService** - `Services/NotesService.swift:90-101` - batch AppleScript calls ✓
- [x] **Regex compilation in hot paths** - `Models/Note.swift:56-98` - cache as static constants ✓
- [x] **Regex compilation: DateParser** - `Services/DateParser.swift:83-85` - cache patterns ✓
- [x] **Path traversal validation** - `Commands/Exec/ExecRun.swift:90-91` - validate paths ✓
- [ ] **Missing documentation** - all public APIs - add DocC comments
- [x] **Extract AppleScript runner** - 7+ services - create shared `AppleScriptRunner` utility ✓
- [x] **Extract JSON output pattern** - 15+ commands - create `OutputFormatter` utility ✓
- [ ] **Extract Process execution pattern** - 4+ services - create shared utility

---

## Low

- [ ] **Missing access control modifiers** - most service files - add `private`/`fileprivate`
- [ ] **Missing timeout error context** - `Services/PluginManager.swift:356-358` - include plugin name
- [ ] **Unnecessary full calendar scan** - `Services/CalendarService.swift:126-135` - accept event ID
- [ ] **Missing email/phone validation** - `Commands/Messages/MessagesSend.swift` - validate recipient format
- [ ] **Magic numbers** - various files - extract to named constants
- [ ] **Date formatting duplication** - various files - cache DateFormatter instances

---

## Feature Requests

- [x] Weather integration - `sysm weather` with Open-Meteo API ✓
- [ ] Configuration system (`~/.sysm/config.yaml`)
- [ ] Logging framework with debug mode
- [ ] Better DateParser (natural language: "in 2 hours", "next week")
- [ ] Additional output formats (CSV, plist, markdown table)
- [ ] Batch operations (multiple reminders/events in one command)

---

## Over-Engineered (Consider Simplifying)

- [ ] **AnyCodable** - `Models/TrackedReminder.swift:69-114` - consider using library or simplifying
- [ ] **WorkflowEngine template filters** - `Services/WorkflowEngine.swift:504-537` - YAGNI assessment

---

## Progress

| Priority | Total | Done |
|----------|-------|------|
| Critical | 3 | 3 |
| High | 9 | 9 |
| Medium | 12 | 10 |
| Low | 6 | 0 |
