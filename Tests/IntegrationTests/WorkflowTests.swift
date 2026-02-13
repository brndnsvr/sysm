import XCTest
@testable import IntegrationTests

/// Integration tests for multi-step workflows.
///
/// Tests complex scenarios that involve multiple commands working together,
/// simulating real user workflows.
final class WorkflowTests: IntegrationTestCase {

    // MARK: - Calendar Workflow

    func testCalendarCreateAndDeleteWorkflow() throws {
        // Note: This test requires Calendar permission to be granted
        let eventTitle = "Integration Test Event \(testIdentifier)"

        do {
            // Step 1: Create an event
            let createOutput = try runCommand([
                "calendar", "add",
                eventTitle,
                "tomorrow",
                "2pm",
                "--duration", "60"
            ])

            XCTAssertTrue(
                createOutput.contains("Created") || createOutput.contains("created"),
                "Should confirm event creation"
            )

            // Step 2: Verify event exists in list
            let listOutput = try runCommand(["calendar", "week", "--json"])
            XCTAssertTrue(listOutput.contains(eventTitle), "Event should appear in week view")

            // Step 3: Search for the event
            let searchOutput = try runCommand(["calendar", "search", eventTitle])
            XCTAssertTrue(searchOutput.contains(eventTitle), "Should find event in search")

            // Step 4: Delete the event
            let deleteOutput = try runCommand(["calendar", "delete", eventTitle])
            XCTAssertTrue(
                deleteOutput.contains("Deleted") || deleteOutput.contains("deleted"),
                "Should confirm event deletion"
            )

            // Step 5: Verify event no longer exists
            let verifyOutput = try runCommand(["calendar", "search", eventTitle])
            XCTAssertFalse(verifyOutput.contains(eventTitle), "Event should not be found after deletion")

        } catch IntegrationTestError.commandFailed(_, _, let stderr) {
            if stderr.contains("access denied") || stderr.contains("Access Denied") {
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

        // Step 1: Add tags
        let addOutput = try runCommand([
            "tags", "add",
            testFile.path,
            "--tag", "test",
            "--tag", "integration"
        ])

        XCTAssertTrue(
            addOutput.contains("Added") || addOutput.contains("tagged"),
            "Should confirm tags added"
        )

        // Step 2: List tags
        let listOutput = try runCommand(["tags", "list", testFile.path])
        XCTAssertTrue(listOutput.contains("test"), "Should list 'test' tag")
        XCTAssertTrue(listOutput.contains("integration"), "Should list 'integration' tag")

        // Step 3: Find files by tag
        let findOutput = try runCommand(["tags", "find", "test"])
        XCTAssertTrue(findOutput.contains(testFile.lastPathComponent), "Should find test file by tag")

        // Step 4: Remove tags
        let removeOutput = try runCommand([
            "tags", "remove",
            testFile.path,
            "--tag", "test",
            "--tag", "integration"
        ])

        XCTAssertTrue(
            removeOutput.contains("Removed") || removeOutput.contains("removed"),
            "Should confirm tags removed"
        )

        // Step 5: Verify tags removed
        let verifyOutput = try runCommand(["tags", "list", testFile.path])
        XCTAssertFalse(verifyOutput.contains("test"), "Tag should be removed")
        XCTAssertFalse(verifyOutput.contains("integration"), "Tag should be removed")
    }

    // MARK: - Spotlight Search Workflow

    func testSpotlightSearchWorkflow() throws {
        // Step 1: Search for a common file type
        let searchOutput = try runCommand([
            "spotlight", "kind", "folder",
            "--limit", "5"
        ])

        let lines = parseLines(searchOutput)
        XCTAssertFalse(lines.isEmpty, "Should find at least one folder")

        // Step 2: Search by modification time
        let recentOutput = try runCommand([
            "spotlight", "modified", "7",  // Last 7 days
            "--limit", "5"
        ])

        let recentLines = parseLines(recentOutput)
        XCTAssertFalse(recentLines.isEmpty, "Should find recently modified files")

        // Step 3: Get metadata for a file
        if let firstFile = lines.first {
            // Extract file path (may need parsing depending on output format)
            let metadataOutput = try runCommand([
                "spotlight", "metadata",
                firstFile
            ])

            XCTAssertTrue(
                metadataOutput.contains("kMDItem") || metadataOutput.contains("Metadata"),
                "Should show metadata attributes"
            )
        }
    }

    // MARK: - Exec Command Workflow

    func testExecAppleScriptWorkflow() throws {
        // Step 1: Run simple AppleScript
        let simpleOutput = try runCommand([
            "exec", "run",
            "--script", "return \"Hello from AppleScript\""
        ])

        XCTAssertTrue(simpleOutput.contains("Hello from AppleScript"))

        // Step 2: Run AppleScript with application interaction
        let appOutput = try runCommand([
            "exec", "run",
            "--script", """
            tell application "System Events"
                return name
            end tell
            """
        ])

        XCTAssertTrue(appOutput.contains("System Events"))
    }

    // MARK: - Error Handling

    func testGracefulErrorHandling() throws {
        // Test that errors are user-friendly and don't crash

        // Invalid date format
        try runCommandExpectingFailure([
            "calendar", "add",
            "Test Event",
            "invalid-date"
        ])

        // Non-existent file
        try runCommandExpectingFailure([
            "tags", "list",
            "/nonexistent/file/path.txt"
        ])

        // Invalid search query
        let emptySearch = try runCommand([
            "spotlight", "search", "xyznonexistentquery123"
        ])
        // Empty results should not be an error, just empty output
        XCTAssertTrue(emptySearch.isEmpty || emptySearch.contains("No results"))
    }

    // MARK: - Performance

    func testCommandPerformance() throws {
        // Verify commands complete in reasonable time
        let start = Date()
        _ = try runCommand(["--version"])
        let duration = Date().timeIntervalSince(start)

        XCTAssertLessThan(duration, 2.0, "Version command should complete quickly")
    }

    func testMultipleCommandsSequential() throws {
        // Simulate a user running multiple commands in sequence
        let commands: [[String]] = [
            ["--version"],
            ["--help"],
            ["calendar", "--help"],
            ["spotlight", "kind", "folder", "--limit", "1"]
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
