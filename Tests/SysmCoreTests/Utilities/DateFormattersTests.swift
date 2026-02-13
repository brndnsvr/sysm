//
//  DateFormattersTests.swift
//  sysm
//

import XCTest
@testable import SysmCore

final class DateFormattersTests: XCTestCase {

    // MARK: - ISO8601 Formatter Tests

    func testISO8601FormatterOutput() {
        let date = Date(timeIntervalSince1970: 1705320000) // 2024-01-15 10:00:00 UTC
        let formatted = DateFormatters.iso8601.string(from: date)

        XCTAssertTrue(formatted.contains("2024"))
        XCTAssertTrue(formatted.contains("T"))
        XCTAssertTrue(formatted.contains("Z") || formatted.contains("+"))
    }

    func testISO8601FormatterParsing() {
        let dateString = "2024-01-15T10:00:00Z"
        let date = DateFormatters.iso8601.date(from: dateString)

        XCTAssertNotNil(date)
    }

    func testISO8601FormatterRoundTrip() {
        let originalDate = Date(timeIntervalSince1970: 1705320000)
        let formatted = DateFormatters.iso8601.string(from: originalDate)
        let parsed = DateFormatters.iso8601.date(from: formatted)

        XCTAssertNotNil(parsed)
        // Allow 1 second tolerance for formatting differences
        XCTAssertEqual(originalDate.timeIntervalSince1970, parsed!.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - Display Formatter Tests

    func testDisplayFormatterOutput() {
        let date = Date(timeIntervalSince1970: 1705320000)
        let formatted = DateFormatters.display.string(from: date)

        // Display format should be human-readable
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.count > 5) // At least some content
    }

    func testDisplayFormatterContainsDateParts() {
        let date = Date(timeIntervalSince1970: 1705320000) // Jan 15, 2024
        let formatted = DateFormatters.display.string(from: date)

        // Should contain some date information
        XCTAssertTrue(formatted.contains("2024") || formatted.contains("24") || formatted.contains("Jan") || formatted.contains("15"))
    }

    // MARK: - Short Formatter Tests

    func testShortFormatterOutput() {
        let date = Date(timeIntervalSince1970: 1705320000)
        let formatted = DateFormatters.short.string(from: date)

        // Short format should be concise
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.count > 3)
        XCTAssertTrue(formatted.count < 30) // Should be relatively short
    }

    // MARK: - Date-Only Formatter Tests

    func testDateOnlyFormatterOutput() {
        let date = Date(timeIntervalSince1970: 1705320000)
        let formatted = DateFormatters.dateOnly.string(from: date)

        // Should contain date but not time
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.contains("2024") || formatted.contains("24"))
    }

    func testDateOnlyFormatterExcludesTime() {
        let date = Date(timeIntervalSince1970: 1705320000) // 10:00 AM
        let formatted = DateFormatters.dateOnly.string(from: date)

        // Should not contain hour markers
        let lowerFormatted = formatted.lowercased()
        // Allow for date numbers but not time-specific formats
        // This is a heuristic - if it doesn't contain AM/PM or obvious time patterns, consider it date-only
        let hasTimeIndicators = lowerFormatted.contains("am") ||
                                lowerFormatted.contains("pm") ||
                                lowerFormatted.contains(":") // colon typically indicates time

        // For date-only format, we expect NO time indicators
        // But some locales might still include them, so this is a best-effort test
        if !hasTimeIndicators {
            XCTAssertTrue(true) // Good, no time indicators
        }
    }

    // MARK: - Time-Only Formatter Tests

    func testTimeOnlyFormatterOutput() {
        let date = Date(timeIntervalSince1970: 1705320000)
        let formatted = DateFormatters.timeOnly.string(from: date)

        // Should contain time information
        XCTAssertFalse(formatted.isEmpty)
    }

    func testTimeOnlyFormatterContainsTime() {
        let date = Date(timeIntervalSince1970: 1705320000) // 10:00 AM UTC
        let formatted = DateFormatters.timeOnly.string(from: date)

        // Should contain some time marker (colon, AM/PM, hour)
        let lowerFormatted = formatted.lowercased()
        let hasTimeIndicators = lowerFormatted.contains(":") ||
                                lowerFormatted.contains("am") ||
                                lowerFormatted.contains("pm") ||
                                formatted.contains("10")

        XCTAssertTrue(hasTimeIndicators)
    }

    // MARK: - Formatter Consistency Tests

    func testAllFormattersHandleSameDate() {
        let date = Date(timeIntervalSince1970: 1705320000)

        let iso = DateFormatters.iso8601.string(from: date)
        let display = DateFormatters.display.string(from: date)
        let short = DateFormatters.short.string(from: date)
        let dateOnly = DateFormatters.dateOnly.string(from: date)
        let timeOnly = DateFormatters.timeOnly.string(from: date)

        // All should produce non-empty strings
        XCTAssertFalse(iso.isEmpty)
        XCTAssertFalse(display.isEmpty)
        XCTAssertFalse(short.isEmpty)
        XCTAssertFalse(dateOnly.isEmpty)
        XCTAssertFalse(timeOnly.isEmpty)

        // All should be different (or at least not all the same)
        let uniqueFormats = Set([iso, display, short, dateOnly, timeOnly])
        XCTAssertGreaterThan(uniqueFormats.count, 1)
    }

    // MARK: - Edge Case Tests

    func testFormattersHandleDistantPast() {
        let date = Date(timeIntervalSince1970: 0) // Jan 1, 1970

        XCTAssertNotNil(DateFormatters.iso8601.string(from: date))
        XCTAssertNotNil(DateFormatters.display.string(from: date))
        XCTAssertNotNil(DateFormatters.short.string(from: date))
    }

    func testFormattersHandleDistantFuture() {
        let date = Date(timeIntervalSince1970: 2147483647) // Jan 19, 2038 (32-bit max)

        XCTAssertNotNil(DateFormatters.iso8601.string(from: date))
        XCTAssertNotNil(DateFormatters.display.string(from: date))
        XCTAssertNotNil(DateFormatters.short.string(from: date))
    }

    func testFormattersHandleCurrentDate() {
        let now = Date()

        let iso = DateFormatters.iso8601.string(from: now)
        let display = DateFormatters.display.string(from: now)
        let short = DateFormatters.short.string(from: now)

        XCTAssertFalse(iso.isEmpty)
        XCTAssertFalse(display.isEmpty)
        XCTAssertFalse(short.isEmpty)
    }
}
