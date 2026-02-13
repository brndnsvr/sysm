import XCTest

/// Integration tests for multi-step workflows.
///
/// Tests complex scenarios that involve multiple commands working together,
/// simulating real user workflows.
final class WorkflowTests: IntegrationTestCase {

    // MARK: - Calendar Workflow

    func testCalendarCreateAndDeleteWorkflow() throws {
        let eventTitle = "Integration Test Event \(testIdentifier)"

        do {
            // Step 1: Create an event
            let createOutput = try runCommand([
                "calendar", "add",
                eventTitle,
                "--start", "tomorrow 2pm"
            ])

            XCTAssertTrue(
                createOutput.lowercased().contains("created") ||
                createOutput.lowercased().contains("added"),
                "Should confirm event creation, got: \(createOutput)"
            )

            // Step 2: Search for the event
            let searchOutput = try runCommand(["calendar", "search", eventTitle])
            XCTAssertTrue(searchOutput.contains(eventTitle), "Should find event in search")

            // Step 3: Delete the event
            let deleteOutput = try runCommand(["calendar", "delete", eventTitle])
            XCTAssertTrue(
                deleteOutput.lowercased().contains("deleted") ||
                deleteOutput.lowercased().contains("removed"),
                "Should confirm event deletion, got: \(deleteOutput)"
            )

        } catch IntegrationTestError.commandFailed(_, _, let stderr) {
            if stderr.localizedCaseInsensitiveContains("access denied") ||
               stderr.localizedCaseInsensitiveContains("not granted") {
                throw XCTSkip("Calendar access not granted - skipping integration test")
            }
            throw IntegrationTestError.commandFailed(command: "calendar workflow", exitCode: 1, stderr: stderr)
        }
    }

    // MARK: - Tags Workflow

    func testTagsAddListRemoveWorkflow() throws {
        // Create temporary test file
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("sysm-test-\(testIdentifier).txt")

        try "Test content".write(to: testFile, atomically: true, encoding: .utf8)
        trackResource(testFile.path)

        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        // Step 1: Add a tag (only one --tag per invocation)
        let addOutput = try runCommand([
            "tags", "add",
            testFile.path,
            "--tag", "test"
        ])
        XCTAssertTrue(
            addOutput.lowercased().contains("added"),
            "Should confirm tag added, got: \(addOutput)"
        )

        // Step 2: Add a second tag
        _ = try runCommand([
            "tags", "add",
            testFile.path,
            "--tag", "integration"
        ])

        // Step 3: List tags
        let listOutput = try runCommand(["tags", "list", testFile.path])
        XCTAssertTrue(listOutput.contains("test"), "Should list 'test' tag")
        XCTAssertTrue(listOutput.contains("integration"), "Should list 'integration' tag")

        // Step 4: Remove tags one at a time
        let removeOutput = try runCommand([
            "tags", "remove",
            testFile.path,
            "--tag", "test"
        ])
        XCTAssertTrue(
            removeOutput.lowercased().contains("removed"),
            "Should confirm tag removed, got: \(removeOutput)"
        )

        _ = try runCommand([
            "tags", "remove",
            testFile.path,
            "--tag", "integration"
        ])

        // Step 5: Verify tags removed
        let verifyOutput = try runCommand(["tags", "list", testFile.path])
        XCTAssertTrue(
            verifyOutput.contains("No tags") || !verifyOutput.contains("test"),
            "Tags should be removed, got: \(verifyOutput)"
        )
    }

    // MARK: - Exec Command Workflow

    func testExecAppleScriptWorkflow() throws {
        // Step 1: Run simple AppleScript via --code flag
        let simpleOutput = try runCommand([
            "exec", "run",
            "--applescript",
            "-c", "return \"Hello from AppleScript\""
        ])
        XCTAssertTrue(simpleOutput.contains("Hello from AppleScript"))

        // Step 2: Run AppleScript with application interaction
        let appOutput = try runCommand([
            "exec", "run",
            "--applescript",
            "-c", "tell application \"System Events\" to return name"
        ])
        XCTAssertTrue(appOutput.contains("System Events"))
    }

    // MARK: - Error Handling

    func testGracefulErrorHandling() throws {
        // Invalid command args should produce a non-zero exit with error text
        try runCommandExpectingFailure(
            ["calendar", "add", "Test Event"],
            expectedError: "Missing"
        )

        // Non-existent file for tags should produce an error
        try runCommandExpectingFailure(
            ["tags", "list", "/nonexistent/file/path.txt"]
        )
    }

    // MARK: - Performance

    func testCommandPerformance() throws {
        let start = Date()
        _ = try runCommand(["--version"])
        let duration = Date().timeIntervalSince(start)

        XCTAssertLessThan(duration, 2.0, "Version command should complete quickly")
    }

    func testMultipleHelpCommandsSequential() throws {
        // Test a sequence of fast, non-blocking commands
        let commands: [[String]] = [
            ["--version"],
            ["--help"],
            ["calendar", "--help"],
            ["tags", "--help"]
        ]

        for command in commands {
            let start = Date()
            _ = try runCommand(command)
            let duration = Date().timeIntervalSince(start)

            XCTAssertLessThan(
                duration, 5.0,
                "Command '\(command.joined(separator: " "))' took too long: \(duration)s"
            )
        }
    }
}
