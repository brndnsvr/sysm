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

    // MARK: - Metadata

    func testMetadataUsesTheOriginalResource() {
        // Adjustment data or a Live Photo's paired video can be listed first.
        XCTAssertEqual(PhotosService.primaryResourceType(among: [.adjustmentData, .photo, .pairedVideo]), .photo)
        XCTAssertEqual(PhotosService.primaryResourceType(among: [.fullSizeVideo, .video]), .video)
        XCTAssertNil(PhotosService.primaryResourceType(among: [.adjustmentData]))
    }
}
