//
//  XCTestCase+Extensions.swift
//  sysm
//

import XCTest
import Foundation
@testable import SysmCore

extension XCTestCase {

    // MARK: - Date Testing Helpers

    /// Asserts that two dates are equal within a tolerance.
    /// - Parameters:
    ///   - date1: First date to compare.
    ///   - date2: Second date to compare.
    ///   - tolerance: Tolerance in seconds (default: 1 second).
    ///   - message: Optional failure message.
    ///   - file: Source file.
    ///   - line: Source line.
    func assertDatesEqual(
        _ date1: Date,
        _ date2: Date,
        tolerance: TimeInterval = 1.0,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let difference = abs(date1.timeIntervalSince(date2))
        XCTAssertLessThanOrEqual(
            difference,
            tolerance,
            message.isEmpty ? "Dates differ by \(difference) seconds" : message,
            file: file,
            line: line
        )
    }

    /// Asserts that a date is today.
    /// - Parameters:
    ///   - date: The date to check.
    ///   - message: Optional failure message.
    ///   - file: Source file.
    ///   - line: Source line.
    func assertDateIsToday(
        _ date: Date,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let calendar = Calendar.current
        XCTAssertTrue(
            calendar.isDateInToday(date),
            message.isEmpty ? "Date is not today: \(date)" : message,
            file: file,
            line: line
        )
    }

    // MARK: - String Testing Helpers

    /// Asserts that a string contains a substring (case-insensitive).
    /// - Parameters:
    ///   - string: The string to search in.
    ///   - substring: The substring to find.
    ///   - message: Optional failure message.
    ///   - file: Source file.
    ///   - line: Source line.
    func assertContains(
        _ string: String,
        _ substring: String,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            string.localizedCaseInsensitiveContains(substring),
            message.isEmpty ? "'\(string)' does not contain '\(substring)'" : message,
            file: file,
            line: line
        )
    }

    /// Asserts that a string matches a regex pattern.
    /// - Parameters:
    ///   - string: The string to test.
    ///   - pattern: The regex pattern.
    ///   - message: Optional failure message.
    ///   - file: Source file.
    ///   - line: Source line.
    func assertMatches(
        _ string: String,
        pattern: String,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(string.startIndex..., in: string)
        XCTAssertTrue(
            regex.firstMatch(in: string, range: range) != nil,
            message.isEmpty ? "'\(string)' does not match pattern '\(pattern)'" : message,
            file: file,
            line: line
        )
    }

    // MARK: - Collection Testing Helpers

    /// Asserts that a collection is not empty.
    /// - Parameters:
    ///   - collection: The collection to test.
    ///   - message: Optional failure message.
    ///   - file: Source file.
    ///   - line: Source line.
    func assertNotEmpty<T: Collection>(
        _ collection: T,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            collection.isEmpty,
            message.isEmpty ? "Collection is empty" : message,
            file: file,
            line: line
        )
    }

    // MARK: - Async Testing Helpers

    /// Waits for an async condition to become true.
    /// - Parameters:
    ///   - timeout: Maximum time to wait.
    ///   - condition: The condition to check.
    /// - Returns: True if condition became true, false if timed out.
    func waitFor(
        timeout: TimeInterval = 5.0,
        condition: @escaping () async -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if await condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        return false
    }

    // MARK: - Error Testing Helpers

    /// Asserts that an async throwing expression throws a specific error.
    /// - Parameters:
    ///   - expression: The expression that should throw.
    ///   - errorType: The expected error type.
    ///   - message: Optional failure message.
    ///   - file: Source file.
    ///   - line: Source line.
    func assertThrowsError<T, E: Error>(
        _ expression: @autoclosure () async throws -> T,
        ofType errorType: E.Type,
        _ message: String = "",
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail(
                message.isEmpty ? "Expected error of type \(errorType) but no error was thrown" : message,
                file: file,
                line: line
            )
        } catch is E {
            // Expected error type
        } catch {
            XCTFail(
                message.isEmpty ? "Expected error of type \(errorType) but got \(type(of: error))" : message,
                file: file,
                line: line
            )
        }
    }

    // MARK: - Test Data Helpers

    /// Creates a temporary directory for test files.
    /// - Returns: URL to the temporary directory.
    func createTempDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sysm-tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        addTeardownBlock {
            try? FileManager.default.removeItem(at: tempDir)
        }

        return tempDir
    }

    /// Creates a temporary file with content.
    /// - Parameters:
    ///   - content: Content to write to the file.
    ///   - filename: Optional filename (defaults to UUID).
    /// - Returns: URL to the temporary file.
    func createTempFile(content: String, filename: String? = nil) throws -> URL {
        let tempDir = try createTempDirectory()
        let file = tempDir.appendingPathComponent(filename ?? UUID().uuidString)

        try content.write(to: file, atomically: true, encoding: .utf8)

        return file
    }
}

// MARK: - ServiceContainer Testing Helpers

extension ServiceContainer {
    /// Resets the service container to its default state for testing.
    public static func reset() {
        // This would need to be implemented in ServiceContainer
        // For now, just document the requirement
    }
}
