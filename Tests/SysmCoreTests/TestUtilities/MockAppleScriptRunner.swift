//
//  MockAppleScriptRunner.swift
//  sysm
//

import Foundation
@testable import SysmCore

/// Mock implementation of AppleScriptRunnerProtocol for testing.
///
/// This mock allows tests to verify AppleScript generation without actually
/// executing scripts. It records all scripts run and allows configuring
/// mock responses for different script identifiers.
public final class MockAppleScriptRunner: AppleScriptRunnerProtocol, @unchecked Sendable {

    // MARK: - Recorded Data

    /// All scripts that have been run, in order.
    public private(set) var scriptHistory: [(script: String, identifier: String)] = []

    /// Mock responses keyed by identifier.
    public var mockResponses: [String: String] = [:]

    /// Mock errors keyed by identifier.
    public var mockErrors: [String: Error] = [:]

    /// Default response when no mock is configured.
    public var defaultResponse: String = ""

    // MARK: - Initialization

    public init() {}

    // MARK: - Protocol Implementation

    public func escape(_ string: String) -> String {
        // Use the real escaping logic for consistency
        AppleScriptRunner.shared.escape(string)
    }

    public func escapeMdfind(_ string: String) -> String {
        // Use the real escaping logic for consistency
        AppleScriptRunner.shared.escapeMdfind(string)
    }

    public func run(_ script: String, identifier: String) throws -> String {
        scriptHistory.append((script, identifier))

        // Check for mock error
        if let error = mockErrors[identifier] {
            throw error
        }

        // Return mock response or default
        return mockResponses[identifier] ?? defaultResponse
    }

    // MARK: - Test Helpers

    /// Clears all recorded history and mock responses.
    public func reset() {
        scriptHistory.removeAll()
        mockResponses.removeAll()
        mockErrors.removeAll()
        defaultResponse = ""
    }

    /// Returns the most recent script run.
    public var lastScript: String? {
        scriptHistory.last?.script
    }

    /// Returns the most recent script identifier.
    public var lastIdentifier: String? {
        scriptHistory.last?.identifier
    }

    /// Returns all scripts run for a specific identifier.
    public func scripts(for identifier: String) -> [String] {
        scriptHistory
            .filter { $0.identifier == identifier }
            .map { $0.script }
    }

    /// Verifies that a script containing the given substring was run.
    public func assertScriptContains(_ substring: String, file: StaticString = #file, line: UInt = #line) {
        guard let lastScript = lastScript else {
            fatalError("No scripts have been run", file: file, line: line)
        }

        guard lastScript.contains(substring) else {
            fatalError("Script does not contain '\(substring)':\n\(lastScript)", file: file, line: line)
        }
    }
}
