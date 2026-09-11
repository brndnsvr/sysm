import XCTest
@testable import SysmCore

final class NotesMarkdownTests: XCTestCase {
    private let parser = NotesMarkdownParser()
    private let renderer = NotesHTMLRenderer()

    func testParserMapsSupportedBlocks() throws {
        let markdown = """
        # School Supplies

        ## Classroom
        A paragraph that
        wraps across lines.

        ### Writing
        - [ ] Pencils
        - [x] Erasers
        - [X] Markers
        """

        let document = try parser.parse(markdown)

        XCTAssertEqual(
            document.blocks,
            [
                .title("School Supplies"),
                .heading("Classroom"),
                .paragraph("A paragraph that wraps across lines."),
                .subheading("Writing"),
                .checklistItem(text: "Pencils", isChecked: false),
                .checklistItem(text: "Erasers", isChecked: true),
                .checklistItem(text: "Markers", isChecked: true),
            ]
        )
    }

    func testParserTreatsUnsupportedMarkdownAsBodyText() throws {
        let document = try parser.parse("**Bold is intentionally literal**")
        XCTAssertEqual(document.blocks, [.paragraph("**Bold is intentionally literal**")])
    }

    func testParserNormalizesWindowsLineEndings() throws {
        let document = try parser.parse("## Heading\r\n\r\nBody")
        XCTAssertEqual(document.blocks, [.heading("Heading"), .paragraph("Body")])
    }

    func testParserRejectsEmptyInput() {
        XCTAssertThrowsError(try parser.parse(" \n\t\n")) { error in
            XCTAssertEqual(error as? NotesMarkdownError, .emptyDocument)
        }
    }

    func testParserRejectsEmptyStructuredBlock() {
        XCTAssertThrowsError(try parser.parse("##  \n")) { error in
            XCTAssertEqual(error as? NotesMarkdownError, .emptyBlock(line: 1, marker: "heading"))
        }
        XCTAssertThrowsError(try parser.parse("- [ ]  \n")) { error in
            XCTAssertEqual(error as? NotesMarkdownError, .emptyBlock(line: 1, marker: "checklist item"))
        }
    }

    func testRendererEscapesHTMLAndEmitsPlainBootstrapBlocks() throws {
        let document = try parser.parse("# A & B\n\n- [ ] <unsafe>\n\nIt's quoted")

        XCTAssertEqual(
            renderer.renderBootstrapHTML(document),
            """
            <div>A &amp; B</div>
            <div>&lt;unsafe&gt;</div>
            <div>It&#39;s quoted</div>
            """
        )
    }

    func testReadBackValidatorAcceptsNativeHeadingAndChecklistMarkup() throws {
        let document = try parser.parse(
            "# Supplies\n\n## Required\n\n### Writing\n\n- [ ] Pencils\n- [x] Paper"
        )
        let body = """
        <div><h1>Supplies</h1></div>
        <div><h2>Required</h2></div>
        <div><h3>Writing</h3></div>
        <ul><li>Pencils</li><li>Paper</li></ul>
        """

        XCTAssertNoThrow(
            try NotesReadBackValidator().validate(
                document: document,
                plaintext: "Supplies\nRequired\nWriting\nPencils\nPaper",
                body: body
            )
        )
    }

    func testReadBackValidatorRejectsMissingNativeChecklistStructure() throws {
        let document = try parser.parse("## Required\n\n- [ ] Pencils")

        XCTAssertThrowsError(
            try NotesReadBackValidator().validate(
                document: document,
                plaintext: "Required\nPencils",
                body: "<div><h2>Required</h2></div><div>Pencils</div>"
            )
        ) { error in
            XCTAssertTrue(error.localizedDescription.contains("checklist items"))
        }
    }
}
