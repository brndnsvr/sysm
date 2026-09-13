import Photos
import XCTest
@testable import SysmCore

final class PhotosServiceTests: XCTestCase {

    func testLookupsByIdentifierIncludeHiddenAssets() {
        // PhotoKit omits hidden assets by default, which made a hidden photo impossible to unhide by ID.
        XCTAssertTrue(PhotosService.byIdentifierOptions().includeHiddenAssets)
    }

    // MARK: - Video export

    func testVideoExportPrefersTheEditedRendition() {
        XCTAssertEqual(PhotosService.preferredVideoResourceType(among: [.video, .fullSizeVideo]), .fullSizeVideo)
        XCTAssertEqual(PhotosService.preferredVideoResourceType(among: [.adjustmentData, .video]), .video)
        XCTAssertNil(PhotosService.preferredVideoResourceType(among: [.photo]))
    }


}
