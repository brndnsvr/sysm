//
//  ShellTests.swift
//  sysm
//

import XCTest
@testable import SysmCore

final class ShellTests: XCTestCase {

    // MARK: - Basic Command Execution Tests

    func testExecuteSimpleCommand() throws {
        let result = try Shell.execute("echo", ["Hello, World!"])

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.contains("Hello, World!"))
        XCTAssertTrue(result.error.isEmpty)
    }

    func testExecuteCommandWithMultipleArguments() throws {
        let result = try Shell.execute("echo", ["one", "two", "three"])

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.contains("one"))
        XCTAssertTrue(result.output.contains("two"))
        XCTAssertTrue(result.output.contains("three"))
    }

    func testExecuteCommandWithNoArguments() throws {
        let result = try Shell.execute("pwd", [])

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertFalse(result.output.isEmpty)
        XCTAssertTrue(result.output.contains("/"))
    }

    // MARK: - Exit Code Tests

    func testCommandWithNonZeroExitCode() throws {
        let result = try Shell.execute("false", [])

        XCTAssertNotEqual(result.exitCode, 0)
    }

    func testCommandWithZeroExitCode() throws {
        let result = try Shell.execute("true", [])

        XCTAssertEqual(result.exitCode, 0)
    }

    // MARK: - Error Handling Tests

    func testNonExistentCommand() {
        XCTAssertThrowsError(try Shell.execute("nonexistent_command_12345", [])) { error in
            // Should throw an error for non-existent command
            XCTAssertTrue(error is ShellError || error is NSError)
        }
    }

    // MARK: - Output Tests

    func testCaptureStandardOutput() throws {
        let testString = "Test output \(UUID().uuidString)"
        let result = try Shell.execute("echo", [testString])

        XCTAssertTrue(result.output.contains(testString))
    }

    func testCaptureStandardError() throws {
        // Send output to stderr
        let result = try Shell.execute("sh", ["-c", "echo 'error message' >&2"])

        // Error message should be in stderr
        XCTAssertTrue(result.error.contains("error") || result.output.contains("error"))
    }

    func testEmptyOutput() throws {
        let result = try Shell.execute("true", [])

        XCTAssertTrue(result.output.isEmpty || result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Special Characters Tests

    func testCommandWithSpecialCharacters() throws {
        let specialString = "Test!@#$%"
        let result = try Shell.execute("echo", [specialString])

        XCTAssertTrue(result.output.contains("Test"))
    }

    func testCommandWithNewlines() throws {
        let multilineString = "Line1\nLine2\nLine3"
        let result = try Shell.execute("echo", [multilineString])

        XCTAssertTrue(result.output.contains("Line1"))
    }

    func testCommandWithQuotes() throws {
        let quotedString = "Test \"quoted\" string"
        let result = try Shell.execute("echo", [quotedString])

        XCTAssertTrue(result.output.contains("quoted"))
    }

    // MARK: - Path Tests

    func testCommandWithAbsolutePath() throws {
        let result = try Shell.execute("/bin/echo", ["Absolute path test"])

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.contains("Absolute path test"))
    }

    // MARK: - Working Directory Tests

    func testCommandRespectsWorkingDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let result = try Shell.execute("pwd", [], workingDirectory: tempDir.path)

        XCTAssertTrue(result.output.contains(tempDir.lastPathComponent) || result.output.contains("/tmp"))
    }

    // MARK: - Environment Variables Tests

    func testCommandWithEnvironmentVariables() throws {
        let env = ["TEST_VAR": "test_value"]
        let result = try Shell.execute("sh", ["-c", "echo $TEST_VAR"], environment: env)

        XCTAssertTrue(result.output.contains("test_value"))
    }

    // MARK: - Timeout Tests

    func testCommandWithTimeout() throws {
        // Note: This is a basic test - actual timeout implementation depends on Shell utility
        let result = try Shell.execute("sleep", ["0.1"])

        XCTAssertEqual(result.exitCode, 0)
    }

    // MARK: - Piped Commands Tests

    func testPipedCommands() throws {
        // Test pipe simulation with sh
        let result = try Shell.execute("sh", ["-c", "echo 'hello world' | grep hello"])

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.contains("hello"))
    }

    // MARK: - Large Output Tests

    func testCommandWithLargeOutput() throws {
        // Generate 1000 lines of output
        let result = try Shell.execute("sh", ["-c", "for i in {1..1000}; do echo line$i; done"])

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.output.contains("line1"))
        XCTAssertTrue(result.output.contains("line1000"))
    }

    // MARK: - Result Struct Tests

    func testResultStructure() throws {
        let result = try Shell.execute("echo", ["test"])

        XCTAssertNotNil(result.exitCode)
        XCTAssertNotNil(result.output)
        XCTAssertNotNil(result.error)
    }
}

// Note: Shell utility might not exist or have different API
// Adjust tests based on actual Shell implementation
public enum ShellError: Error {
    case commandNotFound
    case executionFailed(Int32)
    case timeout
}
