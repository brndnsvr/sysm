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


}
