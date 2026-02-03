# 0002. AppleScript vs Native Framework Selection

**Status:** Accepted
**Date:** 2025-02-02

## Context

macOS provides multiple ways to interact with system services and applications:

1. **Native Frameworks** - Apple-provided frameworks (EventKit, Contacts, Photos, etc.)
2. **AppleScript** - Scripting interface to applications that support it
3. **Private APIs** - Undocumented frameworks and methods
4. **Shell Commands** - Command-line utilities and tools

The choice affects:
- Performance and reliability
- Type safety and error handling
- Maintenance burden and fragility
- User permission requirements
- Code complexity

## Decision

**Prefer native frameworks when available; use AppleScript only when no framework exists.**

### Decision Criteria

```
┌─────────────────────────────────────┐
│ Is there a public native framework? │
└────────────┬────────────────────────┘
             │
      ┌──────┴──────┐
      │ YES         │ NO
      │             │
      ▼             ▼
┌──────────┐  ┌─────────────────┐
│ Use      │  │ AppleScript     │
│ Framework│  │ available?      │
└──────────┘  └────────┬────────┘
                       │
                ┌──────┴──────┐
                │ YES         │ NO
                │             │
                ▼             ▼
         ┌─────────────┐  ┌─────────────┐
         │ Use         │  │ Evaluate    │
         │ AppleScript │  │ shell/other │
         └─────────────┘  └─────────────┘
```

**Never use private APIs** - They can break between OS versions and may violate App Store guidelines.

### Framework-Based Services

When Apple provides a public framework, always prefer it:

```swift
// ✅ GOOD: Use EventKit for calendar/reminders
import EventKit

public actor CalendarService: CalendarServiceProtocol {
    private let store = EKEventStore()

    public func listCalendars() async throws -> [Calendar] {
        let ekCalendars = store.calendars(for: .event)
        return ekCalendars.map { Calendar(from: $0) }
    }
}
```

**Framework-based services:**
- `CalendarService` - Uses `EventKit` for calendar access
- `ReminderService` - Uses `EventKit` for reminders
- `ContactsService` - Uses `Contacts` framework
- `PhotosService` - Uses `Photos` framework
- `WeatherKitService` - Uses `WeatherKit` and `CoreLocation`

**Benefits:**
- Type-safe APIs with compiler checking
- Fast (in-process, no IPC overhead)
- Stable across OS updates
- Well-documented by Apple
- Direct access to underlying data models

### AppleScript-Based Services

When no framework exists, use AppleScript for applications that expose scripting dictionaries:

```swift
// ✅ ACCEPTABLE: Use AppleScript for Mail (no public framework)
public struct MailService: MailServiceProtocol {
    private let runner: any AppleScriptRunnerProtocol

    public func sendEmail(to: String, subject: String, body: String) throws {
        let script = """
        tell application "Mail"
            set newMessage to make new outgoing message with properties ¬
                {subject:"\(subject)", content:"\(body)"}
            tell newMessage
                make new to recipient at end of to recipients ¬
                    with properties {address:"\(to)"}
                send
            end tell
        end tell
        """
        try runner.run(script: script)
    }
}
```

**AppleScript-based services:**
- `MailService` - No public Mail framework
- `NotesService` - No public Notes framework
- `MessagesService` - No public Messages framework (iMessage API is private)
- `MusicService` - No public Music framework for scripting
- `SafariService` - Limited framework support for tabs/windows

**Trade-offs:**
- **Slower** - Spawns osascript process, IPC overhead
- **Fragile** - Can break if UI changes (when using GUI scripting)
- **String-based** - No compile-time checking
- **Error handling** - Less precise than framework errors
- **Permissions** - Requires Automation permission

### HTTP API-Based Services

For web services, use standard HTTP clients:

```swift
// ✅ GOOD: Use URLSession for web APIs
public struct WeatherService: WeatherServiceProtocol {
    public func getCurrentWeather(location: String) async throws -> CurrentWeather {
        let url = URL(string: "https://wttr.in/\(location)?format=j1")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(CurrentWeather.self, from: data)
    }
}
```

**HTTP-based services:**
- `WeatherService` - Uses wttr.in API

### What We Don't Use

**Private APIs** ❌
```swift
// ❌ NEVER: Private APIs are forbidden
import PrivateFramework  // NO
```

**Reason:** Private APIs can break without warning and may violate distribution policies.

**GUI Scripting (when avoidable)** ⚠️
```applescript
-- ⚠️ AVOID: GUI scripting is fragile
tell application "System Events"
    tell process "Mail"
        click button "Send" of window 1
    end tell
end tell
```

**Reason:** Breaks when UI changes, requires Accessibility permissions, slow and unreliable.

## Consequences

### Positive

1. **Reliability** - Framework-based code is stable across OS updates
2. **Performance** - In-process framework calls are faster than IPC
3. **Type Safety** - Compile-time checking catches errors early
4. **Maintainability** - Framework APIs have documentation and support
5. **Clear Pattern** - Developers know which approach to use

### Negative

1. **Mixed Patterns** - Some services use frameworks, others use AppleScript
2. **AppleScript Fragility** - Script-based services may break on OS updates
3. **Permission Complexity** - Different services need different permissions
4. **Performance Variance** - AppleScript services are noticeably slower
5. **Limited Features** - Some apps have incomplete scripting support

### Service Breakdown by Approach

| Approach | Services | Rationale |
|----------|----------|-----------|
| **Framework** | Calendar, Reminders, Contacts, Photos, WeatherKit | Public frameworks available |
| **AppleScript** | Mail, Notes, Messages, Music | No public frameworks |
| **HTTP API** | Weather (wttr.in) | Third-party web service |
| **Shell** | Spotlight, Focus, Tags | System utilities |

### Future Considerations

- **If Apple releases new frameworks** - Migrate AppleScript services to frameworks
- **If AppleScript breaks** - Evaluate alternative approaches (shell, private APIs as last resort)
- **If new integrations needed** - Follow this decision tree

## Related Changes

- Initial implementation - All services follow this pattern
- Task T-004 - Documentation of framework vs AppleScript approach

## References

- [AppleScript Language Guide](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/)
- [EventKit Framework](https://developer.apple.com/documentation/eventkit)
- [Contacts Framework](https://developer.apple.com/documentation/contacts)
- [Photos Framework](https://developer.apple.com/documentation/photokit)
- `Sources/SysmCore/Services/AppleScriptRunner.swift` - AppleScript execution infrastructure
