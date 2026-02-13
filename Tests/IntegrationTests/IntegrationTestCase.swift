import XCTest
import Foundation

/// Base class for integration tests that execute the sysm CLI.
///
/// Provides utilities for running commands, parsing output, and cleanup.
/// Integration tests verify end-to-end functionality from the user's perspective.
///
/// ## Usage
///
/// ```swift
/// final class CalendarIntegrationTests: IntegrationTestCase {
///     func testCalendarAddAndList() throws {
///         // Add event
///         let output = try runCommand(["calendar", "add", "Test Event", "tomorrow", "2pm"])
///         XCTAssertTrue(output.contains("Created event"))
///
///         // Verify in list
///         let list = try runCommand(["calendar", "today", "--json"])
///         let events = try parseJSON(list, as: [CalendarEvent].self)
///         XCTAssertTrue(events.contains { $0.title == "Test Event" })
///     }
/// }
/// ```
open class IntegrationTestCase: XCTestCase {
    /// Path to the sysm binary
    static var binaryPath: String {
        // Try release build first, fallback to debug
        let releasePath = "\(projectRoot)/.build/release/sysm"
        let debugPath = "\(projectRoot)/.build/debug/sysm"

        if FileManager.default.fileExists(atPath: releasePath) {
            return releasePath
        }
        return debugPath
    }

    /// Project root directory
    static var projectRoot: String {
        // Walk up from current file until we find Package.swift
        var current = URL(fileURLWithPath: #file)
        while current.path != "/" {
            current = current.deletingLastPathComponent()
            let packagePath = current.appendingPathComponent("Package.swift")
            if FileManager.default.fileExists(atPath: packagePath.path) {
                return current.path
            }
        }
        return FileManager.default.currentDirectoryPath
    }

    /// Resources created during tests (for cleanup)
    var createdResources: [String] = []

    override open func setUp() {
        super.setUp()
        createdResources = []
    }

    override open func tearDown() {
        // Cleanup will be handled by individual tests
        // (e.g., delete created events, notes, etc.)
        createdResources.removeAll()
        super.tearDown()
    }

    // MARK: - Command Execution

    /// Runs a sysm command and returns output.
    ///
    /// - Parameters:
    ///   - arguments: Command arguments (e.g., ["calendar", "today"])
    ///   - timeout: Maximum execution time in seconds
    /// - Returns: Command output (stdout)
    /// - Throws: If command fails or times out
    func runCommand(_ arguments: [String], timeout: TimeInterval = 30) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.binaryPath)
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()

        // Wait with timeout
        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }

        if process.isRunning {
            process.terminate()
            throw IntegrationTestError.timeout(command: arguments.joined(separator: " "))
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let error = String(data: errorData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw IntegrationTestError.commandFailed(
                command: arguments.joined(separator: " "),
                exitCode: Int(process.terminationStatus),
                stderr: error
            )
        }

        return output
    }

    /// Runs a command expecting it to fail.
    ///
    /// - Parameters:
    ///   - arguments: Command arguments
    ///   - expectedError: Expected error message substring
    func runCommandExpectingFailure(_ arguments: [String], expectedError: String? = nil) throws {
        do {
            _ = try runCommand(arguments)
            XCTFail("Command should have failed: \(arguments.joined(separator: " "))")
        } catch IntegrationTestError.commandFailed(_, _, let stderr) {
            if let expectedError = expectedError {
                XCTAssertTrue(
                    stderr.contains(expectedError),
                    "Expected error '\(expectedError)' not found in: \(stderr)"
                )
            }
        }
    }

    // MARK: - Output Parsing

    /// Parses JSON output from a command.
    ///
    /// - Parameters:
    ///   - output: Command output string
    ///   - type: Type to decode
    /// - Returns: Decoded object
    func parseJSON<T: Decodable>(_ output: String, as type: T.Type) throws -> T {
        guard let data = output.data(using: .utf8) else {
            throw IntegrationTestError.parseError("Failed to convert output to data")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw IntegrationTestError.parseError("Failed to decode JSON: \(error.localizedDescription)")
        }
    }

    /// Extracts lines from command output.
    func parseLines(_ output: String) -> [String] {
        return output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Test Utilities

    /// Generates a unique test identifier for resource naming.
    var testIdentifier: String {
        let timestamp = Date().timeIntervalSince1970
        return "test-\(Int(timestamp))-\(UUID().uuidString.prefix(8))"
    }

    /// Marks a resource for potential cleanup.
    func trackResource(_ identifier: String) {
        createdResources.append(identifier)
    }

    /// Waits for a condition to be true.
    ///
    /// - Parameters:
    ///   - timeout: Maximum wait time
    ///   - condition: Condition closure to check
    func wait(timeout: TimeInterval = 5, for condition: () throws -> Bool) throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if try condition() {
                return
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        throw IntegrationTestError.timeout(command: "wait for condition")
    }
}

// MARK: - Errors

enum IntegrationTestError: LocalizedError {
    case commandFailed(command: String, exitCode: Int, stderr: String)
    case timeout(command: String)
    case parseError(String)
    case setupFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let exitCode, let stderr):
            return "Command failed: \(command) (exit code: \(exitCode))\n\(stderr)"
        case .timeout(let command):
            return "Command timed out: \(command)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .setupFailed(let message):
            return "Setup failed: \(message)"
        }
    }
}
