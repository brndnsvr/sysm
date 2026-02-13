# Error Handling Guide

This guide documents the standardized error handling patterns used across sysm.

## Error Enum Pattern

All services define domain-specific error enums following this standard pattern:

```swift
public enum ServiceNameError: LocalizedError {
    case accessDenied
    case itemNotFound(String)
    case invalidInput(String)
    case operationFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Service access denied"
        case .itemNotFound(let identifier):
            return "Item '\(identifier)' not found"
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
            Grant permission in System Settings:
            1. Open System Settings
            2. Navigate to Privacy & Security > [Service]
            3. Enable access for Terminal
            4. Restart sysm

            Quick: open "x-apple.systempreferences:com.apple.preference.security?Privacy_[Service]"
            """
        case .itemNotFound:
            return "Verify the item exists and try again"
        case .invalidInput:
            return "Check the input format and retry"
        case .operationFailed:
            return "Check the underlying error and try again"
        }
    }
}
```

## Common Error Cases

All service error enums should include these standard cases:

### 1. Access Denied
```swift
case accessDenied
```
- **When**: Permission denied by system
- **Recovery**: Guide user to System Settings with one-command shortcut

### 2. Item Not Found
```swift
case itemNotFound(String)  // identifier
case eventNotFound(String) // service-specific variant
```
- **When**: Requested item doesn't exist
- **Recovery**: Verify identifier, suggest search/list commands

### 3. Invalid Input
```swift
case invalidInput(String)  // description
case invalidDateFormat(String)  // service-specific variant
```
- **When**: User provides malformed input
- **Recovery**: Explain expected format, provide example

### 4. Operation Failed
```swift
case operationFailed(underlying: Error)
```
- **When**: Underlying framework/API call fails
- **Recovery**: Show underlying error, suggest retry or alternative approach

## Service-Specific Error Patterns

### Framework-Based Services (Calendar, Reminders, Contacts, Photos)

**Common cases:**
```swift
public enum ServiceError: LocalizedError {
    // Standard
    case accessDenied
    case itemNotFound(String)
    case invalidInput(String)
    case operationFailed(underlying: Error)

    // Service-specific
    case readOnly(String)  // Item cannot be modified
    case invalidFormat(String)  // Specific format error
    case quotaExceeded  // Service limits reached
}
```

**Permission URLs:**
- Calendar: `x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars`
- Reminders: `x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders`
- Contacts: `x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts`
- Photos: `x-apple.systempreferences:com.apple.preference.security?Privacy_Photos`

### AppleScript-Based Services (Mail, Notes, Messages, Safari, Music)

**Common cases:**
```swift
public enum ServiceError: LocalizedError {
    // Standard
    case accessDenied  // Automation permission
    case itemNotFound(String)
    case invalidInput(String)
    case scriptExecutionFailed(String)

    // AppleScript-specific
    case applicationNotRunning
    case timeout
    case malformedOutput(String)
}
```

**Permission guidance:**
```
Grant automation permission:
1. Open System Settings
2. Navigate to Privacy & Security > Automation
3. Find Terminal
4. Enable [Target App] (Mail, Notes, etc.)
```

## Recovery Suggestion Best Practices

### 1. Be Specific
❌ Bad: `"Check permissions"`
✅ Good: `"Grant Calendar access in System Settings > Privacy & Security > Calendars"`

### 2. Provide Steps
```swift
return """
To resolve this issue:
1. First specific step
2. Second specific step
3. Third specific step

Quick command: [one-liner to open settings]
"""
```

### 3. Include Quick Commands
```swift
return """
Grant permission in System Settings.

Quick: open "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
"""
```

### 4. Suggest Alternatives
```swift
case .eventNotFound(let title):
    return """
    Event '\(title)' not found.

    Try:
    - List all events: sysm calendar today
    - Search events: sysm calendar search '\(title)'
    - Check different calendar: sysm calendar list --calendar "Other"
    """
```

## Error Handling in Services

### Throwing Errors

```swift
public func getEvent(title: String) async throws -> Event {
    try await ensureAccess()  // Throws .accessDenied

    guard let event = findEvent(title: title) else {
        throw CalendarError.eventNotFound(title)
    }

    return event
}
```

### Wrapping Framework Errors

```swift
public func createEvent(...) async throws -> Event {
    do {
        try store.save(event, span: .thisEvent)
        return CalendarEvent(from: event)
    } catch {
        throw CalendarError.operationFailed(underlying: error)
    }
}
```

### Validating Input

```swift
public func setColor(hexColor: String) async throws {
    guard hexColor.hasPrefix("#"), hexColor.count == 7 else {
        throw CalendarError.invalidInput("Hex color must be in format #RRGGBB (e.g., #FF5733)")
    }

    // ... rest of implementation
}
```

## Error Handling in Commands

Commands should catch and display errors user-friendly:

```swift
struct MyCommand: AsyncParsableCommand {
    mutating func run() async throws {
        let service = ServiceContainer.resolve(MyServiceProtocol.self)

        do {
            let result = try await service.doSomething()
            print(result)
        } catch let error as MyServiceError {
            // Service-specific error with helpful messages
            print("Error: \(error.localizedDescription)")
            if let suggestion = error.recoverySuggestion {
                print("\n\(suggestion)")
            }
            throw ExitCode.failure
        } catch {
            // Unexpected error
            print("Unexpected error: \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}
```

## Testing Error Handling

### Unit Tests

```swift
func testAccessDenied() async throws {
    // Mock to deny access
    let mockStore = MockEventStore()
    mockStore.shouldGrantAccess = false

    let service = CalendarService(store: mockStore)

    do {
        _ = try await service.getTodayEvents()
        XCTFail("Should have thrown accessDenied")
    } catch CalendarError.accessDenied {
        // Expected
    } catch {
        XCTFail("Wrong error type: \(error)")
    }
}

func testErrorMessages() {
    let error = CalendarError.eventNotFound("Meeting")

    XCTAssertEqual(error.errorDescription, "Event 'Meeting' not found")
    XCTAssertNotNil(error.recoverySuggestion)
    XCTAssertTrue(error.recoverySuggestion!.contains("sysm calendar"))
}
```

## Service Error Checklist

When creating or updating a service error enum:

- [ ] Conforms to `LocalizedError`
- [ ] Includes standard cases: `accessDenied`, `itemNotFound`, `invalidInput`, `operationFailed`
- [ ] All cases have `errorDescription`
- [ ] All cases have `recoverySuggestion`
- [ ] Permission errors include System Settings path
- [ ] Permission errors include one-command shortcut
- [ ] Recovery suggestions are specific and actionable
- [ ] Recovery suggestions suggest alternative commands
- [ ] Error messages are user-friendly (no technical jargon)
- [ ] Tests verify error messages and recovery suggestions

## Examples by Service

### CalendarError (Framework-Based)
```swift
public enum CalendarError: LocalizedError {
    case accessDenied
    case calendarNotFound(String)
    case eventNotFound(String)
    case invalidDateFormat(String)
    case calendarReadOnly(String)
    case invalidColor(String)

    public var errorDescription: String? { /* ... */ }
    public var recoverySuggestion: String? { /* ... */ }
}
```

### MailError (AppleScript-Based)
```swift
public enum MailError: LocalizedError {
    case accessDenied
    case applicationNotRunning
    case messageNotFound(String)
    case invalidInput(String)
    case scriptExecutionFailed(String)
    case timeout

    public var errorDescription: String? { /* ... */ }
    public var recoverySuggestion: String? { /* ... */ }
}
```

## References

- [LocalizedError Protocol](https://developer.apple.com/documentation/foundation/localizederror)
- [Error Handling in Swift](https://docs.swift.org/swift-book/LanguageGuide/ErrorHandling.html)
- System Settings URL schemes (internal documentation)
