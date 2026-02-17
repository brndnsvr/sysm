import XCTest
@testable import SysmCore

final class AppleScriptRunnerTests: XCTestCase {

    var runner: AppleScriptRunner!

    override func setUp() {
        super.setUp()
        runner = AppleScriptRunner()
    }

    override func tearDown() {
        runner = nil
        super.tearDown()
    }

    // MARK: - escape() Tests

    func testEscape_BasicString() {
        let result = runner.escape("hello world")
        XCTAssertEqual(result, "hello world")
    }

    func testEscape_DoubleQuotes() {
        let result = runner.escape("test\"string")
        XCTAssertEqual(result, "test\\\"string")
    }

    func testEscape_Backslash() {
        let result = runner.escape("path\\to\\file")
        XCTAssertEqual(result, "path\\\\to\\\\file")
    }

    func testEscape_Newline() {
        let result = runner.escape("line1\nline2")
        XCTAssertEqual(result, "line1\\nline2")
    }

    func testEscape_CarriageReturn() {
        let result = runner.escape("line1\rline2")
        XCTAssertEqual(result, "line1\\rline2")
    }

    func testEscape_Tab() {
        let result = runner.escape("col1\tcol2")
        XCTAssertEqual(result, "col1\\tcol2")
    }

    func testEscape_MultipleSpecialChars() {
        let result = runner.escape("test\"with\nnew\\line")
        XCTAssertEqual(result, "test\\\"with\\nnew\\\\line")
    }

    func testEscape_EmptyString() {
        let result = runner.escape("")
        XCTAssertEqual(result, "")
    }

    // MARK: - escapeMdfind() Tests

    func testEscapeMdfind_BasicString() {
        let result = runner.escapeMdfind("test string")
        XCTAssertEqual(result, "test string")
    }

    func testEscapeMdfind_SingleQuote() {
        let result = runner.escapeMdfind("test's string")
        XCTAssertEqual(result, "test\\'s string")
    }

    func testEscapeMdfind_Backslash() {
        let result = runner.escapeMdfind("path\\to\\file")
        XCTAssertEqual(result, "path\\\\to\\\\file")
    }

    func testEscapeMdfind_BackslashAndQuote() {
        let result = runner.escapeMdfind("it's a\\path")
        XCTAssertEqual(result, "it\\'s a\\\\path")
    }

    func testEscapeMdfind_EmptyString() {
        let result = runner.escapeMdfind("")
        XCTAssertEqual(result, "")
    }

    // MARK: - run() Tests

    func testRun_SimpleReturn() throws {
        let script = "return \"hello\""
        let result = try runner.run(script, identifier: "test")
        XCTAssertEqual(result, "hello")
    }

    func testRun_Arithmetic() throws {
        let script = "return 2 + 2"
        let result = try runner.run(script, identifier: "test")
        XCTAssertEqual(result, "4")
    }

    func testRun_WithWhitespace() throws {
        let script = "return \"  test  \""
        let result = try runner.run(script, identifier: "test")
        XCTAssertEqual(result, "test")
    }

    func testRun_InvalidSyntax() {
        let script = "return 'invalid syntax"
        XCTAssertThrowsError(try runner.run(script, identifier: "test")) { error in
            guard let appleScriptError = error as? AppleScriptError else {
                XCTFail("Expected AppleScriptError")
                return
            }
            if case .executionFailed = appleScriptError {
                // Expected error type
            } else {
                XCTFail("Expected executionFailed error")
            }
        }
    }

    func testRun_EmptyScript() throws {
        let script = ""
        // Empty scripts should run without error (no-op)
        let result = try runner.run(script, identifier: "test")
        XCTAssertEqual(result, "")
    }

    func testRun_CustomIdentifier() throws {
        let script = "return \"test\""
        let result = try runner.run(script, identifier: "custom-id")
        XCTAssertEqual(result, "test")
    }

    func testRun_MultilineScript() throws {
        let script = """
        set x to 5
        set y to 10
        return x + y
        """
        let result = try runner.run(script, identifier: "test")
        XCTAssertEqual(result, "15")
    }

    // MARK: - Pipe Buffer Tests

    func testRun_LargeOutput_DoesNotDeadlock() throws {
        // Generate output exceeding the ~64KB pipe buffer to verify
        // concurrent pipe draining prevents deadlock.
        // Each iteration produces ~80 chars, 1000 iterations ≈ 80KB.
        let script = """
        set output to ""
        repeat 1000 times
            set output to output & "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz0123456789-pad" & linefeed
        end repeat
        return output
        """
        let result = try runner.run(script, identifier: "large-output-test")
        // Verify we got substantial output (at least 64KB)
        XCTAssertGreaterThan(result.count, 64 * 1024, "Output should exceed 64KB pipe buffer")
    }
}
