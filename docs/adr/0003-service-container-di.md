# 0003. ServiceContainer Dependency Injection Pattern

**Status:** Accepted
**Date:** 2025-02-02

## Context

sysm has 24+ services (calendar, contacts, photos, mail, etc.) that need to be accessed throughout the codebase, particularly in CLI commands. The service instantiation and dependency management strategy affects:

- **Testability** - Can services be mocked/stubbed for unit tests?
- **Coupling** - How tightly are commands coupled to service implementations?
- **Performance** - How expensive is service instantiation?
- **Thread Safety** - Can services be safely shared across concurrent contexts?
- **Developer Experience** - How easy is it to access services?

Common DI patterns considered:
1. **Direct instantiation** - `let service = CalendarService()` in each command
2. **Singleton services** - `CalendarService.shared`
3. **Factory pattern** - Container with factory closures
4. **Protocol-based DI** - Inject protocols, not concrete types
5. **Service locator** - Global registry of services

## Decision

**Use a singleton ServiceContainer with factory-based dependency injection and lazy caching.**

### Architecture

```swift
public final class ServiceContainer: @unchecked Sendable {
    public static let shared = ServiceContainer()

    // MARK: - Factory Closures (swappable for tests)
    public var calendarFactory: () -> any CalendarServiceProtocol = { CalendarService() }
    public var contactsFactory: () -> any ContactsServiceProtocol = { ContactsService() }
    // ... 24+ factories

    // MARK: - Cached Instances (lazy loaded, thread-safe)
    private var _calendar: (any CalendarServiceProtocol)?
    private var _contacts: (any ContactsServiceProtocol)?
    // ... 24+ cache slots

    private let lock = NSLock()

    // MARK: - Accessors (lazy + cached)
    public func calendar() -> any CalendarServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if let cached = _calendar { return cached }
        let instance = calendarFactory()
        _calendar = instance
        return instance
    }
}
```

### Usage Pattern

Commands access services through a convenience API:

```swift
struct CalendarListCommand: AsyncParsableCommand {
    func run() async throws {
        let service = Services.calendar()  // Uses ServiceContainer.shared
        let calendars = try await service.listCalendars()
        // ...
    }
}
```

The `Services` enum provides static accessors:

```swift
public enum Services {
    public static func calendar() -> any CalendarServiceProtocol {
        ServiceContainer.shared.calendar()
    }

    public static func contacts() -> any ContactsServiceProtocol {
        ServiceContainer.shared.contacts()
    }
    // ... 24+ accessors
}
```

### Test Substitution

Tests swap factories to inject mocks:

```swift
final class CalendarCommandTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ServiceContainer.shared.calendarFactory = { MockCalendarService() }
    }

    override func tearDown() {
        ServiceContainer.shared.reset()  // Restore defaults
        super.tearDown()
    }

    func testListCalendars() async throws {
        // Command uses MockCalendarService via factory
        let command = CalendarListCommand()
        try await command.run()
    }
}
```

### Registered Services

The container manages 24+ services:

**Framework-based (Actors):**
- `CalendarService` - EventKit calendar access
- `ReminderService` - EventKit reminders access
- `ContactsService` - Contacts framework
- `PhotosService` - Photos framework
- `WeatherKitService` - WeatherKit + CoreLocation

**AppleScript-based (Structs):**
- `MailService` - Mail.app scripting
- `NotesService` - Notes.app scripting
- `MessagesService` - Messages.app scripting
- `MusicService` - Music.app scripting
- `FocusService` - Focus mode control
- `SafariService` - Safari tab management

**Utilities (Structs):**
- `SpotlightService` - macOS Spotlight search
- `TagsService` - Finder tags management
- `ShortcutsService` - Shortcuts.app integration
- `WorkflowEngine` - Multi-service workflows
- `PluginManager` - Plugin system
- `WeatherService` - HTTP weather API
- `ScriptRunner` - Shell script execution
- `AppleScriptRunner` - AppleScript execution
- `LaunchdService` - launchd integration
- `CacheService` - Response caching
- `MarkdownExporter` - Export to markdown
- `TriggerService` - Event-based triggers
- `DateParser` - Natural language date parsing

## Consequences

### Positive

1. **Testability** - Factory pattern enables easy mocking
2. **Decoupling** - Commands depend on protocols, not implementations
3. **Performance** - Lazy initialization + caching avoids redundant instantiation
4. **Thread Safety** - NSLock ensures safe concurrent access
5. **Centralized Control** - All service instantiation in one place
6. **Type Safety** - Protocols ensure correct service contracts

### Negative

1. **Global State** - Singleton makes testing harder (must reset state)
2. **Boilerplate** - Each service needs factory + cache + accessor
3. **Implicit Dependencies** - Commands don't declare dependencies explicitly
4. **Service Locator Smell** - Some consider service locator an anti-pattern
5. **@unchecked Sendable** - Required for global mutable state, must be manually verified

### Why This Pattern?

**Alternative: Direct Instantiation**
```swift
// ❌ Rejected: Not testable
struct CalendarListCommand: AsyncParsableCommand {
    func run() async throws {
        let service = CalendarService()  // Can't mock
        // ...
    }
}
```

**Alternative: Constructor Injection**
```swift
// ❌ Rejected: Doesn't work with ArgumentParser
struct CalendarListCommand: AsyncParsableCommand {
    let service: any CalendarServiceProtocol

    init(service: any CalendarServiceProtocol) {
        self.service = service
    }
    // ArgumentParser requires init() with no parameters!
}
```

**Alternative: Environment Objects**
```swift
// ❌ Rejected: SwiftUI-specific, not suitable for CLI
```

**Alternative: Property Wrappers**
```swift
// ❌ Rejected: Complex, reduces clarity
@Injected var service: CalendarServiceProtocol
```

### Factory + Lazy Caching Rationale

**Why factories?**
- Enables test substitution (`calendarFactory = { MockCalendarService() }`)
- Allows runtime configuration
- Keeps instantiation logic flexible

**Why caching?**
- Some services are expensive to instantiate (framework stores)
- Avoids creating duplicate instances within a command execution
- Improves performance for commands that access services multiple times

**Why lazy?**
- Only instantiate services that are actually used
- Reduces startup time
- Defers permission requests until needed

**Why NSLock?**
- Ensures thread-safe cache access
- Simple and performant for this use case
- Avoids data races in concurrent command execution

### Thread Safety Details

The container is marked `@unchecked Sendable` because:
1. Mutable state (`_calendar`, etc.) is protected by `NSLock`
2. Factory closures are only mutated in tests (single-threaded setup)
3. Manual verification confirms no data races

```swift
public final class ServiceContainer: @unchecked Sendable {
    private let lock = NSLock()  // Protects cached instances

    public func calendar() -> any CalendarServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        // Safe: lock ensures exclusive access
        if let cached = _calendar { return cached }
        let instance = calendarFactory()
        _calendar = instance
        return instance
    }
}
```

## Related Changes

- Commit `2a59b5d` - Register utility services in ServiceContainer
- Task T-004 - Documentation of DI pattern

## References

- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-using-factories-in-swift/)
- [Swift Concurrency and Sendable](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- `Sources/SysmCore/Services/ServiceContainer.swift:1-314` - Full implementation
- `Sources/SysmCore/Protocols/` - Service protocol definitions
