import XCTest

final class FileServicesIntegrationTests: IntegrationTestCase {

    /// Path to a known system image for testing
    private var testImagePath: String {
        "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns"
    }

    private var tempDir: URL {
        FileManager.default.temporaryDirectory
    }

    // MARK: - Tags (JSON variants)

    func testTagsAddListRemoveJSON() throws {
        let testFile = tempDir.appendingPathComponent("sysm-tag-test-\(testIdentifier).txt")
        try "Test content".write(to: testFile, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        // Add tag
        let addOutput = try runCommand(["tags", "add", testFile.path, "--tag", "integrationtest"])
        XCTAssertTrue(
            addOutput.lowercased().contains("added"),
            "Should confirm tag added, got: \(addOutput)"
        )

        // List tags
        let listOutput = try runCommand(["tags", "list", testFile.path])
        XCTAssertTrue(listOutput.contains("integrationtest"), "Should list the tag")

        // Remove tag
        let removeOutput = try runCommand(["tags", "remove", testFile.path, "--tag", "integrationtest"])
        XCTAssertTrue(
            removeOutput.lowercased().contains("removed"),
            "Should confirm tag removed, got: \(removeOutput)"
        )
    }

    // MARK: - Image

    func testImageMetadata() throws {
        let output = try runCommand(["image", "metadata", testImagePath, "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    func testImageOCR() throws {
        let output = try runCommand(["image", "ocr", testImagePath, "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - PDF

    func testPDFInfo() throws {
        // Create a temp PDF from the test image
        let pdfPath = tempDir.appendingPathComponent("sysm-pdf-test-\(testIdentifier).pdf")

        defer {
            try? FileManager.default.removeItem(at: pdfPath)
        }

        _ = try runCommand(["pdf", "image-to-pdf", testImagePath, "--output", pdfPath.path])

        // PDF info
        let infoOutput = try runCommand(["pdf", "info", pdfPath.path, "--json"])
        let infoData = try XCTUnwrap(infoOutput.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: infoData)
    }

    func testPDFText() throws {
        // Create a temp PDF from the test image
        let pdfPath = tempDir.appendingPathComponent("sysm-pdf-text-\(testIdentifier).pdf")

        defer {
            try? FileManager.default.removeItem(at: pdfPath)
        }

        _ = try runCommand(["pdf", "image-to-pdf", testImagePath, "--output", pdfPath.path])

        // Image-only PDFs have no text, so pdf text may fail
        do {
            let textOutput = try runCommand(["pdf", "text", pdfPath.path, "--json"])
            let textData = try XCTUnwrap(textOutput.data(using: .utf8))
            _ = try JSONSerialization.jsonObject(with: textData)
        } catch IntegrationTestError.commandFailed(_, _, let stderr) {
            // "No text found" is expected for image-only PDFs
            XCTAssertTrue(
                stderr.localizedCaseInsensitiveContains("no text"),
                "Expected 'no text' error for image PDF, got: \(stderr)"
            )
        }
    }

    // MARK: - Geo

    func testGeoLookup() throws {
        let output = try runCommand(["geo", "lookup", "New York", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let obj = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "Expected JSON object"
        )

        XCTAssertNotNil(obj["latitude"] ?? obj["lat"], "Should have latitude")
        XCTAssertNotNil(obj["longitude"] ?? obj["lon"] ?? obj["lng"], "Should have longitude")
    }

    func testGeoReverse() throws {
        // Use -- to prevent negative longitude from being parsed as a flag
        let output = try runCommand(["geo", "reverse", "--json", "--", "40.7128", "-74.0060"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(trimmed.isEmpty, "Reverse geocode should return data")
    }

    func testGeoDistance() throws {
        let output = try runCommand([
            "geo", "distance",
            "40.7128,-74.0060",
            "34.0522,-118.2437",
            "--json",
        ])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - Weather

    func testWeatherCurrent() throws {
        do {
            let output = try runCommand(["weather", "current", "New York", "--json"])
            let data = try XCTUnwrap(output.data(using: .utf8))
            _ = try JSONSerialization.jsonObject(with: data)
        } catch IntegrationTestError.commandFailed(_, _, let stderr) {
            if stderr.localizedCaseInsensitiveContains("location") ||
               stderr.localizedCaseInsensitiveContains("not available") ||
               stderr.localizedCaseInsensitiveContains("weather") {
                throw XCTSkip("Weather service not available")
            }
            throw IntegrationTestError.commandFailed(
                command: "weather current", exitCode: 1, stderr: stderr
            )
        }
    }

    // MARK: - Finder

    func testFinderInfo() throws {
        let output = try runCommand(["finder", "info", "/tmp", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let obj = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "Expected JSON object"
        )

        XCTAssertFalse(obj.isEmpty, "Finder info should have fields")
    }
}
