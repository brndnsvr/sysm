import XCTest
@testable import SysmCore

final class ShellTests: XCTestCase {

    // MARK: - Shell.run()

    func testRunSimpleCommand() throws {
        let output = try Shell.run("/bin/echo", args: ["hello world"])
        XCTAssertEqual(output, "hello world")
    }

    func testRunCapturesStdout() throws {
        let output = try Shell.run("/usr/bin/printf", args: ["line1\\nline2"])
        XCTAssertTrue(output.contains("line1"))
        XCTAssertTrue(output.contains("line2"))
    }

    func testRunThrowsOnNonZeroExit() {
        XCTAssertThrowsError(try Shell.run("/usr/bin/false")) { error in
            if case Shell.Error.executionFailed(let exitCode, _) = error {
                XCTAssertEqual(exitCode, 1)
            } else {
                XCTFail("Expected Shell.Error.executionFailed, got \(error)")
            }
        }
    }

    func testRunThrowsOnCommandNotFound() {
        XCTAssertThrowsError(try Shell.run("/nonexistent/binary")) { error in
            if case Shell.Error.launchFailed = error {
                // Expected
            } else if case Shell.Error.commandNotFound = error {
                // Also acceptable
            } else {
                XCTFail("Expected launch/not-found error, got \(error)")
            }
        }
    }

    // MARK: - Shell.execute()

    func testExecuteReturnsResult() throws {
        let result = try Shell.execute("/bin/echo", args: ["test output"])
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "test output")
    }

    func testExecuteNonZeroExitDoesNotThrow() throws {
        let result = try Shell.execute("/usr/bin/false")
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertFalse(result.succeeded)
    }

    func testExecuteCapturesStderr() throws {
        let result = try Shell.execute("/bin/sh", args: ["-c", "echo error >&2; exit 1"])
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.stderr.contains("error"))
    }

    // MARK: - Environment Variables

    func testRunWithEnvVariable() throws {
        let output = try Shell.run("/bin/sh", args: ["-c", "echo $TEST_VAR"], environment: ["TEST_VAR": "hello"])
        XCTAssertEqual(output, "hello")
    }

    // MARK: - Stdin

    func testExecuteWithStdin() throws {
        let result = try Shell.execute("/usr/bin/wc", args: ["-w"], stdin: "one two three")
        let wordCount = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(wordCount, "3")
    }

    // MARK: - Timeout

    func testExecuteTimeout() {
        XCTAssertThrowsError(try Shell.execute("/bin/sleep", args: ["10"], timeout: 0.5)) { error in
            if case Shell.Error.timeout = error {
                // Expected
            } else {
                XCTFail("Expected Shell.Error.timeout, got \(error)")
            }
        }
    }

    // MARK: - Error descriptions

    func testErrorDescriptions() {
        let notFound = Shell.Error.commandNotFound("/foo")
        XCTAssertNotNil(notFound.errorDescription)

        let failed = Shell.Error.executionFailed(exitCode: 42, stderr: "oops")
        XCTAssertNotNil(failed.errorDescription)

        let timeout = Shell.Error.timeout(5.0)
        XCTAssertNotNil(timeout.errorDescription)

        let launch = Shell.Error.launchFailed("bad binary")
        XCTAssertNotNil(launch.errorDescription)
    }
}
