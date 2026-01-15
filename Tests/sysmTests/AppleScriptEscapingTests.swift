import XCTest

/// Tests for AppleScript escaping logic
/// Note: This duplicates the escaping logic from AppleScriptRunner.swift
/// because executable targets cannot be directly imported into tests.
/// Keep this in sync with Sources/sysm/Services/AppleScriptRunner.swift
final class AppleScriptEscapingTests: XCTestCase {

    /// The escaping function to test (mirrors AppleScriptRunner.escape)
    func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    func testEscapeQuotes() {
        let input = "Hello \"World\""
        let escaped = escape(input)
        XCTAssertEqual(escaped, "Hello \\\"World\\\"")
    }

    func testEscapeBackslash() {
        let input = "path\\to\\file"
        let escaped = escape(input)
        XCTAssertEqual(escaped, "path\\\\to\\\\file")
    }

    func testEscapeNewlines() {
        let input = "line1\nline2"
        let escaped = escape(input)
        XCTAssertEqual(escaped, "line1\\nline2")
    }

    func testEscapeCarriageReturn() {
        let input = "line1\rline2"
        let escaped = escape(input)
        XCTAssertEqual(escaped, "line1\\rline2")
    }

    func testEscapeTab() {
        let input = "col1\tcol2"
        let escaped = escape(input)
        XCTAssertEqual(escaped, "col1\\tcol2")
    }

    func testEscapeInjectionAttempt() {
        // This is a classic AppleScript injection payload
        let input = "test\" & do shell script \"echo PWNED"
        let escaped = escape(input)

        // After escaping, quotes become \" so the injection is neutralized
        // The original unescaped double-quote should not exist
        XCTAssertFalse(escaped.contains("\"\""), "Should not have double unescaped quotes")

        // Verify the escaping happened - count escaped quotes
        let escapedQuoteCount = escaped.components(separatedBy: "\\\"").count - 1
        XCTAssertEqual(escapedQuoteCount, 2, "Should have 2 escaped quotes")
    }

    func testEscapeComplexInjection() {
        // More complex injection with multiple vectors
        let input = "name\" end tell\n\ndo shell script \"rm -rf ~\" on error\ntell application \"Notes\""
        let escaped = escape(input)

        // Newlines should be escaped (converted to literal \n)
        XCTAssertFalse(escaped.contains("\n"), "Newlines should be escaped")

        // Should contain escaped newline representation
        XCTAssertTrue(escaped.contains("\\n"), "Should have escaped newline")

        // All quotes should be escaped
        let quoteCount = input.filter { $0 == "\"" }.count
        let escapedQuoteCount = escaped.components(separatedBy: "\\\"").count - 1
        XCTAssertEqual(escapedQuoteCount, quoteCount, "All quotes should be escaped")
    }

    func testEscapeEmptyString() {
        XCTAssertEqual(escape(""), "")
    }

    func testEscapeNormalString() {
        let input = "My Notes Folder"
        XCTAssertEqual(escape(input), "My Notes Folder", "Normal strings should pass through unchanged")
    }

    func testEscapeWithBackslashAndQuote() {
        // Order matters: backslash must be escaped first
        let input = "test\\\"quoted\\\""
        let escaped = escape(input)

        // Backslash becomes \\, then quote becomes \"
        // So \\" becomes \\\\\"
        XCTAssertEqual(escaped, "test\\\\\\\"quoted\\\\\\\"")
    }
}
