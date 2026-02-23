import XCTest
@testable import SysmCore

final class VisionServiceTests: XCTestCase {
    private var service: VisionService!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        service = VisionService()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("VisionServiceTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func createTestImage(width: Int = 200, height: Int = 200, color: NSColor = .white) -> String {
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        color.setFill()
        NSBezierPath.fill(NSRect(origin: .zero, size: size))
        image.unlockFocus()

        let path = tempDir.appendingPathComponent("test-\(UUID().uuidString).png").path
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try? pngData.write(to: URL(fileURLWithPath: path))
        }
        return path
    }

    func testDetectBarcodesEmptyImage() throws {
        let path = createTestImage()
        let results = try service.detectBarcodes(imagePath: path)
        // Blank image should have no barcodes
        XCTAssertTrue(results.isEmpty)
    }

    func testDetectFacesEmptyImage() throws {
        let path = createTestImage()
        let results = try service.detectFaces(imagePath: path)
        XCTAssertTrue(results.isEmpty)
    }

    func testClassifyImage() throws {
        let path = createTestImage()
        let results = try service.classifyImage(imagePath: path)
        // Classification should return an array (may or may not be empty depending on image)
        XCTAssertNotNil(results)
    }

    func testDetectRectanglesEmptyImage() throws {
        let path = createTestImage()
        let results = try service.detectRectangles(imagePath: path)
        // Blank image should have no rectangles
        XCTAssertTrue(results.isEmpty)
    }

    func testInvalidImagePathThrows() {
        XCTAssertThrowsError(try service.detectBarcodes(imagePath: "/nonexistent/fake.png")) { error in
            guard case VisionError.invalidImage = error else {
                XCTFail("Expected invalidImage, got \(error)")
                return
            }
        }
    }

    func testErrorDescriptions() {
        let errors: [(VisionError, String)] = [
            (.invalidImage("/test.png"), "Cannot open image: /test.png"),
            (.analysisUnavailable("test"), "Vision analysis unavailable: test"),
            (.noResultsFound, "No results found"),
        ]
        for (error, expected) in errors {
            XCTAssertEqual(error.errorDescription, expected)
        }
    }
}
