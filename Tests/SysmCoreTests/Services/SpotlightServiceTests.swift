import XCTest
@testable import SysmCore

final class SpotlightServiceTests: XCTestCase {

    // MARK: - contentType(forKind:)

    func testKindNamesMapToContentTypes() {
        XCTAssertEqual(SpotlightService.contentType(forKind: "pdf"), "com.adobe.pdf")
        XCTAssertEqual(SpotlightService.contentType(forKind: "Image"), "public.image")
        XCTAssertEqual(SpotlightService.contentType(forKind: "document"), "public.composite-content")
        XCTAssertEqual(SpotlightService.contentType(forKind: "text"), "public.text")
    }

    func testTypeIdentifiersAndExtensionsAreAccepted() {
        XCTAssertEqual(SpotlightService.contentType(forKind: "public.heic"), "public.heic")
        XCTAssertEqual(SpotlightService.contentType(forKind: "docx"), "org.openxmlformats.wordprocessingml.document")
    }

    func testUnknownKindsAreRejected() {
        // Localized kind text is no longer matched; it found nothing even in English.
        XCTAssertNil(SpotlightService.contentType(forKind: "PDF Document"))
        XCTAssertNil(SpotlightService.contentType(forKind: "notatype"))
    }

    // MARK: - metadataAttributes(fromMdls:)

    func testMultiLineArraysAreJoined() {
        let output = """
        kMDItemContentTypeTree = (
            "com.adobe.pdf",
            "public.data",
            "public.item"
        )
        kMDItemDisplayName     = "report.pdf"
        kMDItemTitle           = "a = b"
        kMDItemAuthors         = (null)
        """
        let attributes = SpotlightService.metadataAttributes(fromMdls: output)

        XCTAssertEqual(attributes["kMDItemContentTypeTree"], "com.adobe.pdf, public.data, public.item")
        XCTAssertEqual(attributes["kMDItemDisplayName"], "report.pdf")
        XCTAssertEqual(attributes["kMDItemTitle"], "a = b")
        XCTAssertNil(attributes["kMDItemAuthors"])
    }

    // MARK: - queryArguments(query:scope:)

    func testQueriesStartingWithADashStayQueries() {
        // mdfind reads "-draft" as an option ("Unknown option") and rejects "--".
        XCTAssertEqual(SpotlightService.queryArguments(query: "-draft", scope: nil), [" -draft"])
        XCTAssertEqual(SpotlightService.queryArguments(query: "report", scope: "/tmp"), ["-onlyin", "/tmp", "report"])
    }
}
