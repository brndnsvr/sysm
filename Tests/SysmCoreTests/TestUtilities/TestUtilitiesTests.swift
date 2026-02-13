//
//  TestUtilitiesTests.swift
//  sysm
//

import XCTest
@testable import SysmCore

/// Tests for the test utilities themselves to ensure they work correctly.
final class TestUtilitiesTests: XCTestCase {

    func testMockAppleScriptRunner() {
        let mock = MockAppleScriptRunner()

        // Test escape passes through to real implementation
        let escaped = mock.escape("test's \"quote\"")
        XCTAssertTrue(escaped.contains("\\"))

        // Test recording scripts
        mock.mockResponses["test"] = "success"
        let result = try? mock.run("tell application \"Mail\"", identifier: "test")
        XCTAssertEqual(result, "success")
        XCTAssertEqual(mock.scriptHistory.count, 1)
        XCTAssertEqual(mock.lastIdentifier, "test")

        // Test error throwing
        enum TestError: Error {
            case testFailure
        }
        mock.mockErrors["fail"] = TestError.testFailure
        XCTAssertThrowsError(try mock.run("script", identifier: "fail"))

        // Test reset
        mock.reset()
        XCTAssertEqual(mock.scriptHistory.count, 0)
        XCTAssertNil(mock.lastScript)
    }

    func testTestFixturesDateHelpers() {
        let todayAt2PM = TestFixtures.todayAt2PM
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: todayAt2PM)
        XCTAssertEqual(components.hour, 14)

        let tomorrowAt9AM = TestFixtures.tomorrowAt9AM
        let tomorrowComponents = calendar.dateComponents([.hour], from: tomorrowAt9AM)
        XCTAssertEqual(tomorrowComponents.hour, 9)
    }

    func testTestFixturesICSContent() {
        let ics = TestFixtures.sampleICSContent
        XCTAssertTrue(ics.contains("BEGIN:VCALENDAR"))
        XCTAssertTrue(ics.contains("BEGIN:VEVENT"))
        XCTAssertTrue(ics.contains("END:VEVENT"))
        XCTAssertTrue(ics.contains("END:VCALENDAR"))
    }

    func testTestFixturesAppleScriptOutput() {
        let mailOutput = TestFixtures.sampleMailListOutput
        XCTAssertTrue(mailOutput.contains("|||"))
        XCTAssertTrue(mailOutput.contains("Project Update"))

        let notesOutput = TestFixtures.sampleNotesListOutput
        XCTAssertTrue(notesOutput.contains("|||"))
        XCTAssertTrue(notesOutput.contains("Meeting Notes"))
    }

    func testXCTestCaseExtensions() {
        // Test assertDatesEqual
        let now = Date()
        let nowish = now.addingTimeInterval(0.5)
        assertDatesEqual(now, nowish, tolerance: 1.0)

        // Test assertDateIsToday
        assertDateIsToday(Date())

        // Test assertContains
        assertContains("Hello World", "world")

        // Test assertMatches
        assertMatches("test-123", pattern: "test-\\d+")

        // Test assertNotEmpty
        assertNotEmpty([1, 2, 3])
    }

    func testTempFileCreation() throws {
        let tempDir = try createTempDirectory()
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.path))

        let tempFile = try createTempFile(content: "test content", filename: "test.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFile.path))

        let content = try String(contentsOf: tempFile)
        XCTAssertEqual(content, "test content")

        // Teardown blocks should clean up automatically
    }
}
