import XCTest

/// Integration tests for basic CLI functionality.
///
/// These tests verify that core sysm commands work correctly from the user's
/// perspective, testing the full path from command-line input to output.
final class BasicCommandsTests: IntegrationTestCase {

    // MARK: - Version and Help

    func testVersionCommand() throws {
        let output = try runCommand(["--version"])

        // Version output is just the semver string, e.g. "1.0.0"
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(
            trimmed.range(of: #"^\d+\.\d+\.\d+"#, options: .regularExpression) != nil,
            "Version output should be a semver string, got: '\(trimmed)'"
        )
    }

    func testHelpCommand() throws {
        let output = try runCommand(["--help"])

        XCTAssertTrue(output.contains("Unified Apple ecosystem CLI"))
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
        // Use `calendar calendars --json` which doesn't require a date argument
        do {
            let output = try runCommand(["calendar", "calendars", "--json"])

            guard let data = output.data(using: .utf8) else {
                XCTFail("Failed to convert output to data")
                return
            }

            _ = try JSONSerialization.jsonObject(with: data)
        } catch {
            if let testError = error as? IntegrationTestError,
               case .commandFailed(_, _, let stderr) = testError,
               stderr.localizedCaseInsensitiveContains("access denied") ||
               stderr.localizedCaseInsensitiveContains("not granted") {
                throw XCTSkip("Calendar access not granted")
            }
            throw error
        }
    }

    // MARK: - Exit Codes

    func testSuccessExitCode() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.binaryPath)
        process.arguments = ["--version"]
        process.standardOutput = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(process.terminationStatus, 0, "Successful commands should exit with code 0")
    }

    func testFailureExitCode() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.binaryPath)
        process.arguments = ["nonexistent-command"]

        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertNotEqual(process.terminationStatus, 0, "Failed commands should exit with non-zero code")
    }
}
