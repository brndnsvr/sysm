import XCTest
@testable import IntegrationTests

/// Integration tests for basic CLI functionality.
///
/// These tests verify that core sysm commands work correctly from the user's
/// perspective, testing the full path from command-line input to output.
final class BasicCommandsTests: IntegrationTestCase {

    // MARK: - Version and Help

    func testVersionCommand() throws {
        let output = try runCommand(["--version"])

        XCTAssertTrue(output.contains("sysm"), "Version output should contain 'sysm'")
        XCTAssertTrue(output.contains("."), "Version output should contain a version number")
    }

    func testHelpCommand() throws {
        let output = try runCommand(["--help"])

        XCTAssertTrue(output.contains("unified CLI for Apple ecosystem"))
        XCTAssertTrue(output.contains("SUBCOMMANDS"))
        XCTAssertTrue(output.contains("calendar"))
        XCTAssertTrue(output.contains("reminders"))
        XCTAssertTrue(output.contains("contacts"))
    }

    func testSubcommandHelp() throws {
        let output = try runCommand(["calendar", "--help"])

        XCTAssertTrue(output.contains("calendar"))
        XCTAssertTrue(output.contains("SUBCOMMANDS"))
        XCTAssertTrue(output.contains("add"))
        XCTAssertTrue(output.contains("list"))
        XCTAssertTrue(output.contains("today"))
    }

    // MARK: - Invalid Commands

    func testInvalidCommand() throws {
        try runCommandExpectingFailure(["nonexistent-command"])
    }

    func testInvalidSubcommand() throws {
        try runCommandExpectingFailure(["calendar", "nonexistent"])
    }

    // MARK: - JSON Output

    func testJSONOutputFormat() throws {
        // Most commands support --json flag
        // Test with a read-only command that doesn't require setup
        do {
            let output = try runCommand(["calendar", "list", "--json"])

            // Verify it's valid JSON
            guard let data = output.data(using: .utf8) else {
                XCTFail("Failed to convert output to data")
                return
            }

            _ = try JSONSerialization.jsonObject(with: data)
            // If we get here, it's valid JSON
        } catch {
            // If calendar access is denied, that's OK for this test
            // We're just verifying JSON format support exists
            if let testError = error as? IntegrationTestError,
               case .commandFailed(_, _, let stderr) = testError,
               stderr.contains("access denied") || stderr.contains("Access Denied") {
                // Expected - permission not granted
                return
            }
            throw error
        }
    }

    // MARK: - Exit Codes

    func testSuccessExitCode() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.binaryPath)
        process.arguments = ["--version"]

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0, "Successful commands should exit with code 0")
    }

    func testFailureExitCode() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.binaryPath)
        process.arguments = ["nonexistent-command"]

        // Suppress output
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertNotEqual(process.terminationStatus, 0, "Failed commands should exit with non-zero code")
    }
}
