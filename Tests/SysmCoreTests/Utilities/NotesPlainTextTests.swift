import XCTest
@testable import SysmCore

final class NotesPlainTextTests: XCTestCase {

    func testMarkupCharactersAreEscaped() {
        XCTAssertEqual(NotesPlainText.html("a < b & c > d"), "a &lt; b &amp; c &gt; d")
        XCTAssertEqual(NotesPlainText.html("<draft>"), "&lt;draft&gt;")
    }

    func testLineBreaksBecomeBreakTags() {
        XCTAssertEqual(NotesPlainText.html("one\ntwo\r\nthree"), "one<br>two<br>three")
    }

    func testTypedEntitiesStayVisible() {
        // "&lt;" typed literally must still read "&lt;" in the note, not "<".
        XCTAssertEqual(NotesPlainText.html("&lt;"), "&amp;lt;")
    }
}
