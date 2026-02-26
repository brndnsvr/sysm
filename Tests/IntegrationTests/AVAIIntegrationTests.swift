import XCTest

final class AVAIIntegrationTests: IntegrationTestCase {

    // MARK: - AV Help

    func testAVHelp() throws {
        let output = try runCommand(["av", "--help"])
        XCTAssertTrue(output.contains("devices"))
        XCTAssertTrue(output.contains("formats"))
        XCTAssertTrue(output.contains("record"))
        XCTAssertTrue(output.contains("transcribe"))
    }

    // MARK: - AV Devices

    func testAVDevicesJSON() throws {
        let output = try runCommand(["av", "devices", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let devices = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]

        let arr = try XCTUnwrap(devices, "Expected JSON array of devices")
        XCTAssertFalse(arr.isEmpty, "Should have at least one input device")
        for device in arr {
            XCTAssertNotNil(device["name"], "Each device should have a name")
            XCTAssertNotNil(device["id"], "Each device should have an id")
        }
    }

    // MARK: - AV Formats

    func testAVFormatsJSON() throws {
        let output = try runCommand(["av", "formats", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let formats = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]

        let arr = try XCTUnwrap(formats, "Expected JSON array of formats")
        XCTAssertEqual(arr.count, 4, "Should have 4 supported formats")
    }

    func testAVFormatsContent() throws {
        let output = try runCommand(["av", "formats"])
        XCTAssertTrue(output.contains("M4A"), "Should list M4A format")
        XCTAssertTrue(output.contains("WAV"), "Should list WAV format")
        XCTAssertTrue(output.contains("AIFF"), "Should list AIFF format")
        XCTAssertTrue(output.contains("Core Audio"), "Should list CAF format")
    }

    // MARK: - AI Help

    func testAIHelp() throws {
        let output = try runCommand(["ai", "--help"])
        XCTAssertTrue(output.contains("prompt"))
        XCTAssertTrue(output.contains("summarize"))
        XCTAssertTrue(output.contains("extract-actions"))
        XCTAssertTrue(output.contains("analyze"))
    }

    // MARK: - AI Error Cases

    func testAIPromptMissingArgument() throws {
        try runCommandExpectingFailure(["ai", "prompt"])
    }

    func testAISummarizeMissingFile() throws {
        try runCommandExpectingFailure(["ai", "summarize", "/nonexistent/file.txt"],
                                       expectedError: "File not found")
    }

    func testAIAnalyzeMissingFile() throws {
        try runCommandExpectingFailure(["ai", "analyze", "/nonexistent/file.txt"],
                                       expectedError: "File not found")
    }
}
