# sysm Architecture Guide

This document describes the architecture and design decisions of sysm.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Two-Layer Architecture](#two-layer-architecture)
- [Service Patterns](#service-patterns)
- [Data Flow](#data-flow)
- [Error Handling](#error-handling)
- [Dependency Injection](#dependency-injection)
- [Testing Strategy](#testing-strategy)
- [Performance Considerations](#performance-considerations)

## Overview

sysm is a unified CLI for interacting with the Apple ecosystem on macOS. It provides a consistent interface to Calendar, Reminders, Contacts, Photos, Mail, Notes, Messages, Safari, Music, and more.

**Design Principles:**
- **Protocol-oriented**: Services implement protocols for testability
- **Type-safe**: Leverage Swift's type system for safety
- **Async-first**: Modern async/await for concurrent operations
- **User-friendly**: Clear error messages with recovery suggestions
- **Extensible**: Plugin system for custom commands

## Project Structure

```
sysm/
├── Sources/
│   ├── SysmCore/           # Core library (reusable)
│   │   ├── Models/         # Data models (45+ models)
│   │   ├── Protocols/      # Service interfaces (23 protocols)
│   │   ├── Services/       # Service implementations (18 services)
│   │   └── Utilities/      # Shared utilities
│   └── sysm/               # CLI executable
│       ├── Commands/       # ArgumentParser commands (169 files)
│       └── Main.swift      # Entry point
├── Tests/
│   ├── SysmCoreTests/      # Core library tests
│   └── sysmTests/          # CLI integration tests
└── docs/
    ├── adr/                # Architecture Decision Records
    └── guides/             # User guides
```

## Two-Layer Architecture

### Layer 1: SysmCore (Library)

**Purpose**: Reusable business logic, independent of CLI concerns

**Components:**
- Services - Business logic for macOS integrations
- Models - Data structures
- Protocols - Service contracts
- Utilities - Shared helpers

**Benefits:**
- Testable in isolation
- Reusable in other projects (e.g., SwiftUI app)
- Clear separation of concerns

### Layer 2: sysm (Executable)

**Purpose**: CLI interface using ArgumentParser

**Components:**
- Commands - User-facing CLI commands
- Main.swift - Initialization and routing

**Benefits:**
- Clean command structure
- Auto-generated help
- Shell completion support

## Service Patterns

Services fall into two categories based on the underlying technology:

### Framework-Based Services (Actors)

**Used for**: Calendar, Reminders, Contacts, Photos

**Pattern:**
```swift
public actor CalendarService: CalendarServiceProtocol {
    private let store: EKEventStore

    public init() {
        self.store = EKEventStore()
    }

    public func requestAccess() async throws -> Bool {
        try await store.requestAccess(to: .event)
    }

    public func getTodayEvents() async throws -> [CalendarEvent] {
        // Use EventKit framework
    }
}
```

**Characteristics:**
- Declared as `actor` for thread-safety
- Use native Apple frameworks (EventKit, Contacts, PhotoKit)
- Require entitlements (Privacy - Calendars Usage Description, etc.)
- Require user permissions (System Settings > Privacy & Security)
- Direct framework API access
- Better performance (no IPC overhead)

**Why Actors?**
- EventKit/Contacts/PhotoKit are not thread-safe
- Actors provide automatic serialization
- Safe concurrent access

### AppleScript-Based Services (Structs)

**Used for**: Mail, Notes, Messages, Safari, Music

**Pattern:**
```swift
public struct MailService: MailServiceProtocol {
    private let scriptRunner: AppleScriptRunnerProtocol

    public init(scriptRunner: AppleScriptRunnerProtocol = AppleScriptRunner.shared) {
        self.scriptRunner = scriptRunner
    }

    public func getInboxMessages(limit: Int) throws -> [MailMessage] {
        let script = """
        tell application "Mail"
            set theMessages to messages of inbox
            -- Extract data
        end tell
        """

        let output = try scriptRunner.run(script, identifier: "mail-inbox")
        return parseMessages(output)
    }
}
```

**Characteristics:**
- Declared as `struct` (stateless)
- Use AppleScript/JXA for automation
- No special entitlements required
- User must grant Automation permissions
- AppleScript injection protection (see `AppleScriptRunner`)
- Slower (IPC overhead)

**Why Structs?**
- Stateless services don't need class/actor overhead
- Value semantics are simpler
- No shared mutable state

### Service Comparison

| Aspect | Framework-Based | AppleScript-Based |
|--------|----------------|-------------------|
| **Declaration** | `actor` | `struct` |
| **API** | Native frameworks | AppleScript/JXA |
| **Performance** | Fast | Slower (IPC) |
| **Entitlements** | Required | Not required |
| **Permissions** | System Settings | Automation |
| **Examples** | Calendar, Contacts | Mail, Notes |
| **Testing** | Integration tests | Mock scriptRunner |

## Data Flow

### Command Execution Flow

```
User Input → CLI Command → Service Protocol → Service Implementation → Framework/AppleScript
    ↓
Result ← Format Output ← Model Objects ← Parse Response ← Execute
```

**Example: `sysm calendar today`**

1. **CLI Parsing**: ArgumentParser routes to `CalendarToday` command
2. **Service Resolution**: Resolve `CalendarServiceProtocol` from `ServiceContainer`
3. **Business Logic**: `service.getTodayEvents()` calls EventKit
4. **Model Mapping**: EventKit `EKEvent` → sysm `CalendarEvent`
5. **Output Formatting**: JSON or human-readable format
6. **Display**: Print to stdout

### Data Layer

```
┌─────────────────────────────────────────┐
│   User Input (CLI Arguments)            │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│   ArgumentParser Commands                │
│   (Parsing, Validation)                  │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│   Service Layer (Protocols)              │
│   - CalendarServiceProtocol              │
│   - MailServiceProtocol                  │
│   - ...                                  │
└────────────┬────────────────────────────┘
             │
         ┌───┴───┐
         ▼       ▼
┌────────────┐ ┌────────────────┐
│  Framework │ │  AppleScript   │
│  Services  │ │  Services      │
│  (actors)  │ │  (structs)     │
└─────┬──────┘ └────────┬───────┘
      │                 │
      ▼                 ▼
┌──────────┐      ┌──────────────┐
│ EventKit │      │ AppleScript  │
│ Contacts │      │ Runtime      │
│ PhotoKit │      │              │
└──────────┘      └──────────────┘
```

## Error Handling

### Error Enum Pattern

Each service defines its own error enum:

```swift
public enum CalendarError: LocalizedError {
    case accessDenied
    case eventNotFound(String)
    case invalidInput(String)
    case operationFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied"
        case .eventNotFound(let title):
            return "Event not found: \(title)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .operationFailed(let error):
            return "Operation failed: \(error.localizedDescription)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .accessDenied:
            return """
            Grant calendar access in System Settings:
            1. Open System Settings
            2. Go to Privacy & Security > Calendars
            3. Enable access for Terminal
            4. Restart sysm
            """
        case .eventNotFound:
            return "Check event title and try again"
        case .invalidInput:
            return "Verify input format and retry"
        case .operationFailed:
            return "Check logs and try again"
        }
    }
}
```

**Benefits:**
- Type-safe error handling
- User-friendly error messages
- Recovery suggestions
- Structured error information

### Permission Errors

All framework-based services check permissions:

```swift
public func requestAccess() async throws -> Bool {
    let granted = try await store.requestAccess(to: .event)
    if !granted {
        throw CalendarError.accessDenied
    }
    return granted
}
```

## Dependency Injection

sysm uses a simple service container for dependency injection:

### ServiceContainer

```swift
public final class ServiceContainer {
    private static var factories: [String: () -> Any] = [:]

    public static func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }

    public static func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let factory = factories[key] else {
            fatalError("No factory registered for \(key)")
        }
        return factory() as! T
    }
}
```

### Registration (at startup)

```swift
// Main.swift
ServiceContainer.register(CalendarServiceProtocol.self) { CalendarService() }
ServiceContainer.register(MailServiceProtocol.self) { MailService() }
// ... all services
```

### Resolution (in commands)

```swift
struct CalendarToday: AsyncParsableCommand {
    mutating func run() async throws {
        let service = ServiceContainer.resolve(CalendarServiceProtocol.self)
        let events = try await service.getTodayEvents()
        // ...
    }
}
```

**Benefits:**
- Testable (inject mocks)
- Loose coupling
- Single source of truth
- Easy to swap implementations

## Testing Strategy

### Test Types

1. **Unit Tests** - Services and utilities in isolation
2. **Integration Tests** - End-to-end command execution
3. **Mock Tests** - AppleScript services with mock runner

### Test Utilities

Located in `Tests/SysmCoreTests/TestUtilities/`:

**MockAppleScriptRunner:**
```swift
let mock = MockAppleScriptRunner()
mock.mockResponses["mail-inbox"] = "msg1|||Subject|||sender@example.com"

ServiceContainer.register(AppleScriptRunnerProtocol.self) { mock }

let service = MailService()
let messages = try service.getInboxMessages(limit: 10)

XCTAssertEqual(mock.scriptHistory.count, 1)
XCTAssertTrue(mock.lastScript!.contains("tell application \"Mail\""))
```

**TestFixtures:**
```swift
let date = TestFixtures.todayAt2PM
let ics = TestFixtures.sampleICSContent
let mailOutput = TestFixtures.sampleMailListOutput
```

### Testing Framework Services

Framework services use integration tests with real framework objects:

```swift
func testCalendarService() async throws {
    let service = CalendarService()
    try await service.requestAccess()

    // Create test event
    let event = try await service.addEvent(
        title: "Test Event",
        startDate: Date(),
        endDate: Date().addingTimeInterval(3600),
        calendarName: nil
    )

    // Verify
    XCTAssertEqual(event.title, "Test Event")

    // Cleanup
    try await service.deleteEvent(title: "Test Event")
}
```

## Performance Considerations

### Caching

Services use `CacheService` for expensive operations:

```swift
private let cache = CacheService.shared

func listCalendars() async throws -> [String] {
    let cacheKey = "calendars-list"

    if let cached: [String] = cache.get(cacheKey) {
        return cached
    }

    let calendars = // expensive operation
    cache.set(cacheKey, value: calendars, ttl: 30) // 30 second TTL
    return calendars
}
```

### AppleScript Optimization

**Pagination**: Limit results to avoid timeouts

```swift
// Instead of fetching all messages
let messages = messages of inbox -- BAD: can timeout

// Fetch with limit
set theMessages to items 1 thru \(limit) of messages of inbox -- GOOD
```

**Selective Fields**: Only fetch needed data

```swift
// Instead of full message object
set theMessage to message 1 of inbox -- BAD: heavy

// Fetch specific fields
set theSubject to subject of message 1 of inbox -- GOOD
```

**Batch Operations**: Group operations when possible

```swift
// Instead of individual calls
repeat with msg in messages
    mark msg as read  -- BAD: N calls
end repeat

// Batch update
set read status of messages to true  -- GOOD: 1 call
```

### Framework Optimization

**Predicates**: Use EventKit predicates for filtering

```swift
// Instead of fetching all and filtering in Swift
let allEvents = store.events(matching: predicate)
let filtered = allEvents.filter { $0.title.contains("meeting") } -- BAD

// Use predicate
let predicate = store.predicateForEvents(
    withStart: startDate,
    end: endDate,
    calendars: nil
)
let events = store.events(matching: predicate) -- GOOD
```

## Architecture Decision Records

See `docs/adr/` for detailed rationale behind major decisions:

- [ADR-0001: Two-Layer Architecture](../adr/0001-two-layer-architecture.md)
- [ADR-0002: Service Protocols](../adr/0002-service-protocols.md)
- [ADR-0003: Actor vs Struct Services](../adr/0003-actor-vs-struct-services.md)
- [ADR-0004: AppleScript Injection Prevention](../adr/0004-applescript-injection-prevention.md)

## Future Considerations

### Planned Improvements

1. **Plugin System**: Allow custom services
2. **Configuration Files**: User preferences and defaults
3. **Event Streaming**: Real-time notifications
4. **Web API**: REST API for remote access
5. **GUI**: Optional SwiftUI interface

### Scalability

Current architecture supports:
- Adding new services (follow existing patterns)
- Adding new commands (ArgumentParser subcommands)
- Alternative implementations (swap via ServiceContainer)
- Multiple output formats (JSON, CSV, etc.)

## References

- [Swift Argument Parser](https://github.com/apple/swift-argument-parser)
- [EventKit Documentation](https://developer.apple.com/documentation/eventkit)
- [Contacts Framework](https://developer.apple.com/documentation/contacts)
- [PhotoKit](https://developer.apple.com/documentation/photokit)
- [AppleScript Language Guide](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/)
