# 0001. Actor vs Struct for Service Concurrency

**Status:** Accepted
**Date:** 2025-02-02

## Context

sysm integrates with various macOS frameworks and services, each with different concurrency requirements. Some services manage mutable state through framework objects (like `EKEventStore`, `CNContactStore`, `PHPhotoLibrary`), while others are stateless wrappers around AppleScript or HTTP APIs.

Swift provides two primary concurrency models:
- **Actors** - Provide actor isolation, ensuring safe access to mutable state across concurrent contexts
- **Structs** - Value types with no built-in concurrency protection, suitable for stateless or immutable designs

The decision impacts:
- Thread safety and data race prevention
- Command implementation (`AsyncParsableCommand` vs `ParsableCommand`)
- API ergonomics and developer experience
- Type system clarity about service behavior

## Decision

**Use actors for framework-based services that hold mutable state; use structs for stateless services.**

### Actor-Based Services (Framework Integration)

Services that interact with macOS frameworks use actors because they manage mutable state through framework objects:

```swift
/// WeatherKit-based weather service
///
/// Uses actor isolation to safely manage the CLGeocoder instance which has internal state.
/// This follows the same pattern as CalendarService and ContactsService which also
/// use actors for framework-based services with stateful components.
public actor WeatherKitService: WeatherServiceProtocol {
    private let geocoder = CLGeocoder()
    // ...
}
```

**Examples:**
- `CalendarService` (actor) - Manages `EKEventStore` with mutable calendar state
- `ContactsService` (actor) - Manages `CNContactStore` with contact database access
- `PhotosService` (actor) - Manages `PHPhotoLibrary` with photo library state
- `WeatherKitService` (actor) - Manages `CLGeocoder` with location services state
- `ReminderService` (actor) - Manages `EKEventStore` for reminders

### Struct-Based Services (AppleScript/Stateless)

Services that execute AppleScript or make stateless API calls use structs because they don't maintain state:

```swift
/// Mail service using AppleScript
public struct MailService: MailServiceProtocol {
    private let runner: any AppleScriptRunnerProtocol

    public init(runner: any AppleScriptRunnerProtocol = AppleScriptRunner()) {
        self.runner = runner
    }
    // ...
}
```

**Examples:**
- `MailService` (struct) - AppleScript-based, no internal state
- `NotesService` (struct) - AppleScript-based, no internal state
- `MessagesService` (struct) - AppleScript-based, no internal state
- `MusicService` (struct) - AppleScript-based, no internal state
- `WeatherService` (struct) - HTTP API, stateless
- `ScriptRunner` (struct) - Process execution, stateless
- `AppleScriptRunner` (struct) - AppleScript execution, stateless

### Command Implementation Pattern

The service type determines the command type:

```swift
// Actor service → AsyncParsableCommand
struct CalendarListCommand: AsyncParsableCommand {
    func run() async throws {
        let service = Services.calendar()
        let calendars = try await service.listCalendars()
        // ...
    }
}

// Struct service → ParsableCommand
struct MailSendCommand: ParsableCommand {
    func run() throws {
        let service = Services.mail()
        try service.sendEmail(...)
        // ...
    }
}
```

## Consequences

### Positive

1. **Type Safety** - The type system enforces correct concurrency patterns
2. **Clear Semantics** - Actor vs struct signals whether the service is stateful
3. **Data Race Prevention** - Actors eliminate data races for framework-based services
4. **Performance** - Structs avoid actor overhead for stateless operations
5. **Consistency** - Pattern is applied uniformly across all services

### Negative

1. **Mixed Command Types** - Commands use either `AsyncParsableCommand` or `ParsableCommand`, requiring developers to know which pattern each service uses
2. **Async Propagation** - Actor services force async/await throughout the call chain
3. **Learning Curve** - Developers must understand when to use each pattern

### Trade-offs Considered

**Alternative: Use actors everywhere**
- Rejected: Unnecessary overhead for stateless services
- Rejected: Forces async/await on operations that don't need it

**Alternative: Use structs everywhere**
- Rejected: Would require manual synchronization for framework objects
- Rejected: Loses compile-time data race safety

**Alternative: Use classes with locks**
- Rejected: More error-prone than actor isolation
- Rejected: Doesn't leverage Swift's concurrency type system

## Related Changes

- Commit `0007bbb` - Refactored `WeatherKitService` from struct to actor
- Commit `ab1764b` - Decoupled nested types from service protocols to support both patterns
- Task T-004 - Documentation of this architectural pattern

## References

- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- `Sources/SysmCore/Services/WeatherKitService.swift:5-9` - Actor justification comment
- `Sources/SysmCore/Services/ServiceContainer.swift` - Service registration patterns
