import XCTest
@testable import SysmCore

final class NoteModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeNote(name: String = "Test Note", body: String = "<p>Hello</p>",
                          folder: String = "Notes", id: String = "test-id") -> Note {
        Note(id: id, name: name, folder: folder, body: body,
             creationDate: Date(timeIntervalSince1970: 1700000000),
             modificationDate: Date(timeIntervalSince1970: 1700100000))
    }

    // MARK: - sanitizedName

    func testSanitizedNameNormal() {
        let note = makeNote(name: "Meeting Notes")
        XCTAssertEqual(note.sanitizedName, "Meeting Notes")
    }

    func testSanitizedNameReplacesSlash() {
        let note = makeNote(name: "2024/01/15 Notes")
        XCTAssertEqual(note.sanitizedName, "2024-01-15 Notes")
    }

    func testSanitizedNameReplacesColon() {
        let note = makeNote(name: "Time: 3:00 PM")
        XCTAssertEqual(note.sanitizedName, "Time- 3-00 PM")
    }

    func testSanitizedNameReplacesBackslash() {
        let note = makeNote(name: "path\\to\\file")
        XCTAssertEqual(note.sanitizedName, "path-to-file")
    }

    func testSanitizedNameEmpty() {
        let note = makeNote(name: "")
        XCTAssertEqual(note.sanitizedName, "Untitled")
    }

    func testSanitizedNameWhitespaceOnly() {
        let note = makeNote(name: "   ")
        XCTAssertEqual(note.sanitizedName, "Untitled")
    }

    func testSanitizedNameTruncatesLong() {
        let longName = String(repeating: "a", count: 150)
        let note = makeNote(name: longName)
        XCTAssertEqual(note.sanitizedName.count, 100)
    }

    // MARK: - toMarkdown()

    func testToMarkdownFrontmatter() {
        let note = makeNote()
        let md = note.toMarkdown()

        XCTAssertTrue(md.hasPrefix("---\n"))
        XCTAssertTrue(md.contains("source: apple-notes"))
        XCTAssertTrue(md.contains("folder: Notes"))
        XCTAssertTrue(md.contains("created:"))
        XCTAssertTrue(md.contains("modified:"))
        XCTAssertTrue(md.contains("imported:"))
    }

    // MARK: - HTML to Markdown conversion

    func testHTMLBreakToNewline() {
        let note = makeNote(body: "line1<br>line2")
        let md = note.toMarkdown()
        XCTAssertTrue(md.contains("line1\nline2"))
    }

    func testHTMLStrongToBold() {
        let note = makeNote(body: "<strong>bold</strong>")
        let md = note.toMarkdown()
        XCTAssertTrue(md.contains("**bold**"))
    }

    func testHTMLEmToItalic() {
        let note = makeNote(body: "<em>italic</em>")
        let md = note.toMarkdown()
        XCTAssertTrue(md.contains("*italic*"))
    }

    func testHTMLH1ToHeading() {
        let note = makeNote(body: "<h1>Title</h1>")
        let md = note.toMarkdown()
        XCTAssertTrue(md.contains("# Title"))
    }

    func testHTMLListItemToDash() {
        let note = makeNote(body: "<li>item</li>")
        let md = note.toMarkdown()
        XCTAssertTrue(md.contains("- item"))
    }

    func testHTMLStyleStripped() {
        let note = makeNote(body: "<style>body{color:red}</style>Content")
        let md = note.toMarkdown()
        XCTAssertFalse(md.contains("style"))
        XCTAssertFalse(md.contains("color:red"))
        XCTAssertTrue(md.contains("Content"))
    }

    func testHTMLRemainingTagsStripped() {
        let note = makeNote(body: "<span class=\"test\">text</span>")
        let md = note.toMarkdown()
        XCTAssertFalse(md.contains("<span"))
        XCTAssertTrue(md.contains("text"))
    }

    func testHTMLEntitiesDecoded() {
        let note = makeNote(body: "&amp; &lt; &gt; &quot; &#39; &nbsp;")
        let md = note.toMarkdown()
        XCTAssertTrue(md.contains("& < > \" '"))
    }

    func testTripleNewlinesCollapsed() {
        let note = makeNote(body: "a\n\n\n\n\nb")
        let md = note.toMarkdown()
        XCTAssertFalse(md.contains("\n\n\n"))
    }
}
