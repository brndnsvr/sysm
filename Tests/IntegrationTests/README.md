# Integration Tests

End-to-end tests that execute the sysm CLI and verify functionality from the user's perspective.

## Overview

Integration tests differ from unit tests in that they:
- Test complete command workflows from CLI input to output
- Execute the actual sysm binary (not just library code)
- Verify multi-step user scenarios
- Test CLI argument parsing and output formatting
- Validate error messages and exit codes

## Running Integration Tests

### Prerequisites

1. **Build the binary:**
   ```bash
   swift build -c release
   ```

2. **Grant permissions** (for tests that require them):
   - Calendar access (for calendar workflow tests)
   - Full Xcode installation (for XCTest support)

### Run All Integration Tests

```bash
swift test --filter IntegrationTests
```

### Run Specific Test Suites

```bash
# Basic CLI functionality
swift test --filter BasicCommandsTests

# Multi-step workflows
swift test --filter WorkflowTests
```

### Run Individual Tests

```bash
swift test --filter BasicCommandsTests.testVersionCommand
swift test --filter WorkflowTests.testCalendarCreateAndDeleteWorkflow
```

## Test Structure

### Base Class: `IntegrationTestCase`

Provides utilities for all integration tests:

- **`runCommand(_ arguments:)`** - Execute sysm with arguments
- **`parseJSON(_:as:)`** - Parse JSON output
- **`parseLines(_:)`** - Extract lines from output
- **`testIdentifier`** - Generate unique test resource names
- **`wait(for:)`** - Wait for conditions

### Test Suites

1. **BasicCommandsTests**
   - Version and help commands
   - Invalid command handling
   - JSON output format
   - Exit codes

2. **WorkflowTests**
   - Calendar create-list-delete workflow
   - Tags add-list-remove workflow
   - Spotlight search workflow
   - AppleScript exec workflow
   - Error handling
   - Performance validation

## Writing Integration Tests

### Example: Testing a New Command

```swift
final class MyFeatureTests: IntegrationTestCase {
    func testMyFeatureWorkflow() throws {
        // Step 1: Run command
        let output = try runCommand(["myfeature", "action", "arg1"])

        // Step 2: Verify output
        XCTAssertTrue(output.contains("Expected text"))

        // Step 3: Test with JSON output
        let jsonOutput = try runCommand(["myfeature", "action", "--json"])
        let result = try parseJSON(jsonOutput, as: MyResult.self)

        // Step 4: Verify data structure
        XCTAssertEqual(result.field, expectedValue)
    }
}
```

### Best Practices

1. **Use unique identifiers** for test resources:
   ```swift
   let testName = "Test Item \(testIdentifier)"
   ```

2. **Clean up resources** in test teardown:
   ```swift
   defer {
       try? runCommand(["delete", testName])
   }
   ```

3. **Handle permission errors gracefully**:
   ```swift
   catch IntegrationTestError.commandFailed(_, _, let stderr) {
       if stderr.contains("access denied") {
           throw XCTSkip("Permission not granted")
       }
       throw error
   }
   ```

4. **Test both success and failure cases**:
   ```swift
   // Success case
   let output = try runCommand(["valid", "command"])
   XCTAssertTrue(output.contains("Success"))

   // Failure case
   try runCommandExpectingFailure(["invalid", "command"])
   ```

5. **Verify JSON structure** when using --json:
   ```swift
   let json = try runCommand(["command", "--json"])
   let data = try parseJSON(json, as: [MyModel].self)
   XCTAssertFalse(data.isEmpty)
   ```

## Continuous Integration

Integration tests can be run in CI, but require:

1. **Full Xcode installation** (not Command Line Tools)
2. **Privacy permissions granted** for relevant services
3. **Longer timeout** (integration tests are slower than unit tests)

### GitHub Actions Example

```yaml
- name: Run Integration Tests
  run: |
    swift build -c release
    swift test --filter IntegrationTests
  timeout-minutes: 10
```

## Skipping Tests Without Permissions

Tests automatically skip when permissions aren't granted:

```
Test Case '-[IntegrationTests.WorkflowTests testCalendarCreateAndDeleteWorkflow]' skipped (0.001 seconds).
Reason: Calendar access not granted - skipping integration test
```

To grant permissions before running tests:
1. Run sysm manually once: `./build/release/sysm calendar today`
2. Grant permission in System Settings prompt
3. Run integration tests

## Performance Expectations

Integration tests are slower than unit tests because they:
- Launch the sysm process for each command
- Execute actual CLI logic (parsing, validation, output formatting)
- May interact with system services

**Typical durations:**
- Basic commands: < 1s per test
- Workflow tests: 1-5s per test
- Full test suite: 10-30s

## Debugging Failed Tests

### View Full Command Output

Set `XCT_SHOW_SKIPPED_TEST_OUTPUT=1`:

```bash
XCT_SHOW_SKIPPED_TEST_OUTPUT=1 swift test --filter IntegrationTests
```

### Run Command Manually

Extract the command from the test and run it:

```bash
./.build/release/sysm calendar add "Test Event" tomorrow 2pm
```

### Enable Verbose Logging

Add `--verbose` to commands in tests:

```swift
let output = try runCommand(["calendar", "add", "Test", "--verbose"])
```

### Check Binary Path

Verify the test is using the correct binary:

```swift
print("Binary path: \(IntegrationTestCase.binaryPath)")
```

## Known Limitations

1. **No sandboxing** - Integration tests modify real data (with cleanup)
2. **Permission dependent** - Some tests require macOS permissions
3. **Slower execution** - Full process launches for each command
4. **Flaky potential** - Depends on system state (free disk space, etc.)

## Future Improvements

- [ ] Dedicated test environment (test calendar, test note folder)
- [ ] Parallel test execution (currently sequential)
- [ ] Mock AppleScript responses for isolated testing
- [ ] CI-friendly permission granting mechanism
- [ ] Performance regression detection
- [ ] Test coverage reporting for CLI commands
