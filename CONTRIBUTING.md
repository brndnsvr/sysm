# Contributing to sysm

Thank you for your interest in contributing to sysm! This guide will help you get started.

## Table of Contents

- [Quick Start](#quick-start)
- [Development Setup](#development-setup)
- [Project Architecture](#project-architecture)
- [Code Style](#code-style)
- [Testing](#testing)
- [Adding a New Service](#adding-a-new-service)
- [Adding a New Command](#adding-a-new-command)
- [Pull Request Process](#pull-request-process)
- [Common Issues](#common-issues)

## Quick Start

```bash
# Clone and build
git clone https://github.com/brndnsvr/sysm.git
cd sysm
make build

# Run tests (requires Xcode or CI environment)
swift test

# Lint and format
make format
make lint

# Install pre-commit hooks (optional but recommended)
./scripts/install-hooks.sh
```

**Setup time: ~5-10 minutes** (first build takes longer)

## Development Setup

### Requirements

- **macOS 13.0+** (macOS 15+ recommended for all features)
- **Xcode 15+** or Swift 5.9+ toolchain
- **Homebrew** (for optional tools)

### Optional Tools

```bash
# Code quality tools (highly recommended)
brew install swiftlint swiftformat

# For building documentation
brew install swift-docc-plugin
```

### IDE Setup

**Xcode:**
```bash
xed .  # Opens Package.swift in Xcode
```

**VS Code/Cursor:**
- Install Swift extension
- Use provided tasks and launch configurations

**Command Line:**
```bash
swift build          # Debug build
swift build -c release  # Release build
swift test           # Run tests
```

## Project Architecture

sysm uses a two-layer architecture:

### Layer 1: SysmCore (Library)

Located in `Sources/SysmCore/`, this is the core library containing:

- **Services/** - Business logic for each macOS integration
- **Protocols/** - Service interfaces (23 protocols)
- **Models/** - Data structures for events, contacts, photos, etc.
- **Utilities/** - Shared helpers (DateParser, OutputFormatter, AppleScriptRunner, etc.)

Services fall into two categories:

1. **Framework-based (actors)**: Calendar, Reminders, Contacts, Photos
   - Use native Apple frameworks (EventKit, Contacts, PhotoKit)
   - Declared as `actor` for thread-safety
   - Require entitlements and user permissions

2. **AppleScript-based (structs)**: Mail, Notes, Messages, Safari, Music
   - Use AppleScript/JXA for automation
   - Declared as `struct` (stateless)
   - Use `AppleScriptRunner` for safe script execution

### Layer 2: sysm (Executable)

Located in `Sources/sysm/`, this is the CLI executable containing:

- **Commands/** - ArgumentParser commands (169 files)
- **Main.swift** - Entry point

### Key Design Patterns

**Service Container (Dependency Injection):**
```swift
// Register services at startup
ServiceContainer.register(CalendarService.self) { CalendarService() }

// Resolve in commands
let service = ServiceContainer.resolve(CalendarServiceProtocol.self)
```

**Protocol-Oriented:**
- All services conform to protocols
- Enables mocking in tests
- See `Tests/SysmCoreTests/TestUtilities/MockAppleScriptRunner.swift`

**Error Handling:**
- Domain-specific error enums (e.g., `CalendarError`, `MailError`)
- Conform to `LocalizedError` for user-friendly messages
- Include recovery suggestions where possible

## Code Style

### Swift Style Guidelines

- **Indentation**: 4 spaces (configured in `.swiftformat`)
- **Line length**: 120 characters max
- **Naming**:
  - Types: `PascalCase`
  - Functions/variables: `camelCase`
  - Constants: `camelCase` (not SCREAMING_SNAKE)
- **Self**: Omit `self.` except where required

### SwiftLint & SwiftFormat

We use SwiftLint (linting) and SwiftFormat (formatting):

```bash
# Format code before committing
make format

# Check for linting issues
make lint

# Or use pre-commit hooks (auto-formats on commit)
./scripts/install-hooks.sh
```

**Configuration:**
- `.swiftlint.yml` - Moderate rules, 50+ opt-in rules
- `.swiftformat` - 4 spaces, 120 char lines

### Documentation Style

Use DocC format for all public APIs:

```swift
/// Brief one-line summary.
///
/// Detailed description with important behavior notes.
///
/// ## Example
/// ```swift
/// let service = CalendarService()
/// let events = try await service.getTodayEvents()
/// ```
///
/// - Parameters:
///   - param1: Description
///   - param2: Description
/// - Returns: Description
/// - Throws: `CalendarError.accessDenied` if permission denied
public func someMethod(param1: String, param2: Int) async throws -> Result {
    // Implementation
}
```

## Testing

### Test Structure

Tests are organized in two targets:

- **SysmCoreTests** - Unit tests for services and utilities
- **sysmTests** - Integration tests for CLI commands

### Test Utilities

Located in `Tests/SysmCoreTests/TestUtilities/`:

- `MockAppleScriptRunner` - Mock for AppleScript services
- `TestFixtures` - Sample data and date helpers
- `XCTestCase+Extensions` - Custom assertions and helpers

### Writing Tests

**For Framework-Based Services:**
```swift
final class CalendarServiceTests: XCTestCase {
    var service: CalendarService!

    override func setUp() async throws {
        service = CalendarService()
        try await service.requestAccess()
    }

    func testGetTodayEvents() async throws {
        let events = try await service.getTodayEvents()
        XCTAssertNotNil(events)
    }
}
```

**For AppleScript-Based Services:**
```swift
final class MailServiceTests: XCTestCase {
    var mockRunner: MockAppleScriptRunner!
    var service: MailService!

    override func setUp() {
        mockRunner = MockAppleScriptRunner()
        ServiceContainer.register(AppleScriptRunnerProtocol.self) { mockRunner }
        service = MailService()
    }

    func testGetAccounts() throws {
        mockRunner.mockResponses["mail-accounts"] = "Work|||iCloud|||Personal"

        let accounts = try service.getAccounts()

        XCTAssertEqual(accounts.count, 3)
        XCTAssertTrue(mockRunner.lastScript!.contains("tell application \"Mail\""))
    }
}
```

### Running Tests

```bash
# All tests
swift test

# Specific test
swift test --filter CalendarServiceTests

# With coverage (requires Xcode)
swift test --enable-code-coverage
```

**Note**: Local test execution requires Xcode due to Swift 6.2 Command Line Tools XCTest issue. See `KNOWN_ISSUES.md` for details. Tests run successfully in CI.

## Adding a New Service

Follow these steps to add a new service:

### 1. Create the Protocol

```swift
// Sources/SysmCore/Protocols/MyServiceProtocol.swift
import Foundation

/// Protocol defining my service operations.
///
/// Brief description of what this service does.
public protocol MyServiceProtocol: Sendable {
    /// Does something useful.
    func doSomething() async throws -> Result
}
```

### 2. Create the Service

**For framework-based services:**
```swift
// Sources/SysmCore/Services/MyService.swift
import Foundation

/// Service for interacting with XYZ framework.
public actor MyService: MyServiceProtocol {
    public init() {}

    public func doSomething() async throws -> Result {
        // Implementation
    }
}
```

**For AppleScript-based services:**
```swift
// Sources/SysmCore/Services/MyService.swift
import Foundation

/// Service for interacting with XYZ app via AppleScript.
public struct MyService: MyServiceProtocol {
    private let scriptRunner: AppleScriptRunnerProtocol

    public init(scriptRunner: AppleScriptRunnerProtocol = AppleScriptRunner.shared) {
        self.scriptRunner = scriptRunner
    }

    public func doSomething() throws -> Result {
        let script = """
        tell application "MyApp"
            -- AppleScript here
        end tell
        """
        let output = try scriptRunner.run(script, identifier: "my-service-action")
        return parseOutput(output)
    }
}
```

### 3. Register in ServiceContainer

```swift
// Sources/sysm/Main.swift or appropriate location
ServiceContainer.register(MyServiceProtocol.self) { MyService() }
```

### 4. Create Models (if needed)

```swift
// Sources/SysmCore/Models/MyModel.swift
import Foundation

/// Represents data from my service.
public struct MyModel: Codable {
    public let id: String
    public let name: String
}
```

### 5. Add Commands

```swift
// Sources/sysm/Commands/MyCommand.swift
import ArgumentParser
import SysmCore

struct MyCommand: AsyncParsableCommand {  // or ParsableCommand for non-async
    static let configuration = CommandConfiguration(
        commandName: "mycommand",
        abstract: "Brief description",
        discussion: "Detailed description"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    mutating func run() async throws {
        let service = ServiceContainer.resolve(MyServiceProtocol.self)
        let result = try await service.doSomething()

        if json {
            try OutputFormatter.printJSON(result)
        } else {
            print(result)
        }
    }
}
```

### 6. Add Tests

```swift
// Tests/SysmCoreTests/Services/MyServiceTests.swift
import XCTest
@testable import SysmCore

final class MyServiceTests: XCTestCase {
    func testDoSomething() async throws {
        let service = MyService()
        let result = try await service.doSomething()
        XCTAssertNotNil(result)
    }
}
```

### 7. Update Documentation

- Add examples to `README.md`
- Update `ROADMAP.md` if relevant
- Document in protocol with DocC comments

## Adding a New Command

Commands use Swift ArgumentParser. Example:

```swift
import ArgumentParser
import SysmCore

struct MySubcommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "subcommand",
        abstract: "What this command does"
    )

    @Argument(help: "Required argument")
    var requiredArg: String

    @Option(name: .shortAndLong, help: "Optional parameter")
    var optional: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    mutating func run() async throws {
        // 1. Resolve service
        let service = ServiceContainer.resolve(MyServiceProtocol.self)

        // 2. Call service method
        let result = try await service.doSomething(arg: requiredArg)

        // 3. Format output
        if json {
            try OutputFormatter.printJSON(result)
        } else {
            print("Result: \(result)")
        }
    }
}
```

Then register in parent command:

```swift
struct MyCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mycommand",
        abstract: "Main command",
        subcommands: [
            MySubcommand.self,
            AnotherSubcommand.self
        ]
    )
}
```

## Pull Request Process

### Before Submitting

1. **Format and lint your code:**
   ```bash
   make format
   make lint
   ```

2. **Run tests:**
   ```bash
   swift test
   ```

3. **Update documentation:**
   - Add/update DocC comments
   - Update README if adding user-facing features
   - Update ROADMAP if implementing roadmap items

4. **Write a clear commit message:**
   ```
   Add support for XYZ feature

   - Implement XYZ service protocol
   - Add tests for new functionality
   - Update documentation
   ```

### PR Checklist

Use the PR template (`.github/PULL_REQUEST_TEMPLATE.md`):

- [ ] Code follows Swift style guidelines
- [ ] SwiftLint passes (`make lint`)
- [ ] SwiftFormat applied (`make format`)
- [ ] Tests added for new functionality
- [ ] All tests pass (`swift test`)
- [ ] Documentation updated
- [ ] No compiler warnings

### Review Process

1. Automated checks run (CI/CD via GitHub Actions)
2. Code review by maintainers
3. Address feedback
4. Merge when approved

## Common Issues

### Build Errors

**"No such module 'SysmCore'"**
- Solution: `swift package clean && swift build`

**Signing issues**
- For development: `make install` (no signing)
- For WeatherKit: `make install-notarized` (requires Apple Developer account)

### Test Issues

**"no such module 'XCTest'"**
- See `KNOWN_ISSUES.md` - use Xcode or run tests in CI
- Solution: Install full Xcode and `sudo xcode-select -s /Applications/Xcode.app`

### Permission Issues

**"Access denied" errors**
- Grant permissions in System Settings > Privacy & Security
- See `docs/guides/troubleshooting.md` for detailed steps

### AppleScript Timeouts

- Increase timeout in `AppleScriptRunner` if needed
- Check that target app is installed and accessible
- See `docs/guides/troubleshooting.md`

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/brndnsvr/sysm/issues)
- **Discussions**: [GitHub Discussions](https://github.com/brndnsvr/sysm/discussions)
- **Architecture**: See `docs/guides/architecture.md`
- **Troubleshooting**: See `docs/guides/troubleshooting.md`

## Code of Conduct

Be respectful, constructive, and collaborative. We're all here to build something useful together.

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
