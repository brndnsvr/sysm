import XCTest

final class VisionIntegrationTests: IntegrationTestCase {

    /// Path to a known system image that exists on every Mac
    private var testImagePath: String {
        "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns"
    }

    // MARK: - Help

    func testVisionHelp() throws {
        let output = try runCommand(["vision", "--help"])

        XCTAssertTrue(output.contains("classify"))
        XCTAssertTrue(output.contains("faces"))
        XCTAssertTrue(output.contains("rectangles"))
        XCTAssertTrue(output.contains("barcode"))
    }

    // MARK: - Classify

    func testVisionClassify() throws {
        let output = try runCommand(["vision", "classify", testImagePath, "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]

        // .icns files may return empty classifications on some systems
        let _ = try XCTUnwrap(arr, "Expected JSON array of classifications")
    }

    // MARK: - Faces

    func testVisionFaces() throws {
        let output = try runCommand(["vision", "faces", testImagePath, "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))

        // Should be valid JSON (empty array is fine for a system icon)
        _ = try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - Rectangles

    func testVisionRectangles() throws {
        let output = try runCommand(["vision", "rectangles", testImagePath, "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))

        _ = try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - Barcode

    func testVisionBarcodeNoBarcode() throws {
        let output = try runCommand(["vision", "barcode", testImagePath, "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data) as? [Any]

        let results = try XCTUnwrap(arr, "Expected JSON array")
        XCTAssertTrue(results.isEmpty, "System icon should have no barcodes")
    }

    // MARK: - Error Handling

    func testVisionInvalidPath() throws {
        try runCommandExpectingFailure(["vision", "classify", "/nonexistent.png"])
    }
}
