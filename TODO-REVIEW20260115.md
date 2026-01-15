# TODO: Code Review 2026-01-15

Actionable items from REVIEW20260115.md

---

## Critical

- [ ] **AppleScript injection: NotesService ID** - `Services/NotesService.swift:57-61` - escape `id` parameter
- [ ] **AppleScript injection: NotesService folder** - `Services/NotesService.swift:22-23` - escape folder name
- [ ] **Add test target to Package.swift** - `Package.swift` - add `sysmTests` target

---

## High

- [ ] **AppleScript injection: MusicService search** - `Services/MusicService.swift:195-199` - comprehensive escaping
- [ ] **mdfind injection: TagsService** - `Services/TagsService.swift:111-112` - escape single quotes
- [ ] **mdfind injection: SpotlightService** - `Services/SpotlightService.swift:84` - escape single quotes
- [ ] **Command injection: LaunchdService** - `Services/LaunchdService.swift:309-310` - validate shell metacharacters
- [ ] **Inconsistent async/sync** - `Commands/**/*.swift` - standardize on `AsyncParsableCommand`
- [ ] **Service instantiation anti-pattern** - all command files - implement DI or service container
- [ ] **Silent error swallowing: PluginManager** - `Services/PluginManager.swift:99-101` - log warnings
- [ ] **Silent error swallowing: WorkflowEngine** - `Services/WorkflowEngine.swift:591-596` - log warnings
- [ ] **Services not mockable** - all service files - add protocol abstractions

---

## Medium

- [ ] **Force unwrapping** - `Commands/Calendar/CalendarAdd.swift:47-49` - use guard statements
- [ ] **Mixed concerns in TrackedReminder.swift** - `Models/TrackedReminder.swift` - split into separate files
- [ ] **TriggerService hardcoded path** - `Services/TriggerService.swift:7-8` - make configurable
- [ ] **Inconsistent error handling** - `Commands/Reminders/RemindersAdd.swift:37-39` - standardize across commands
- [ ] **N+1 query pattern: NotesService** - `Services/NotesService.swift:90-101` - batch AppleScript calls
- [ ] **Regex compilation in hot paths** - `Models/Note.swift:56-98` - cache as static constants
- [ ] **Regex compilation: DateParser** - `Services/DateParser.swift:83-85` - cache patterns
- [ ] **Path traversal validation** - `Commands/Exec/ExecRun.swift:90-91` - validate paths
- [ ] **Missing documentation** - all public APIs - add DocC comments
- [ ] **Extract AppleScript runner** - 7+ services - create shared `AppleScriptRunner` utility
- [ ] **Extract JSON output pattern** - 15+ commands - create `OutputFormatter` utility
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
| Critical | 3 | 0 |
| High | 12 | 0 |
| Medium | 12 | 0 |
| Low | 6 | 0 |
