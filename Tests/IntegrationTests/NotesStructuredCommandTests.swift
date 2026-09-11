import Foundation
import XCTest

final class NotesStructuredCommandTests: IntegrationTestCase {
    func testCreateHelpDocumentsStructuredMarkdown() throws {
        let output = try runCommand(["notes", "create", "--help"])

        XCTAssertTrue(output.contains("--from-markdown"))
        XCTAssertTrue(output.contains("- [ ] unchecked checklist item"))
        XCTAssertTrue(output.contains("Accessibility permission"))
    }

    func testFromMarkdownRejectsLegacyBodyBeforeNotesMutation() throws {
        try runCommandExpectingFailure(
            ["notes", "create", "No Mutation", "--body", "body", "--from-markdown", "missing.md"],
            expectedError: "--from-markdown cannot be combined with --body or --stdin"
        )
    }

    func testFromMarkdownDashReadsStdinAndRejectsEmptyContentBeforeMutation() throws {
        do {
            _ = try runCommand(
                ["notes", "create", "No Mutation", "--from-markdown", "-"],
                standardInput: Data()
            )
            XCTFail("Empty Markdown should fail")
        } catch IntegrationTestError.commandFailed(_, _, let stderr) {
            XCTAssertTrue(stderr.contains("Markdown content is empty"))
        }
    }
}
