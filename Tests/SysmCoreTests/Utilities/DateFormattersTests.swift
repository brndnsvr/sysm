import XCTest
@testable import SysmCore

final class DateFormattersTests: XCTestCase {

    // MARK: - iso8601

    func testIso8601FormatAndParse() {
        let date = Date(timeIntervalSince1970: 1705312800) // Jan 15, 2024 10:00 UTC
        let formatted = DateFormatters.iso8601.string(from: date)
        XCTAssertTrue(formatted.contains("2024-01-15"))
        XCTAssertTrue(formatted.contains("T"))

        let parsed = DateFormatters.iso8601.date(from: formatted)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed!.timeIntervalSince1970, date.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - iso8601WithFractionalSeconds

    func testIso8601WithFractionalSeconds() {
        let date = Date(timeIntervalSince1970: 1705312800.123)
        let formatted = DateFormatters.iso8601WithFractionalSeconds.string(from: date)
        XCTAssertTrue(formatted.contains("2024-01-15"))
        XCTAssertTrue(formatted.contains("."))
    }

    // MARK: - iso8601DateOnly

    func testIso8601DateOnly() {
        let date = Date(timeIntervalSince1970: 1705312800) // Jan 15, 2024
        let formatted = DateFormatters.iso8601DateOnly.string(from: date)
        XCTAssertTrue(formatted.contains("2024-01-15"))
        // Should not contain time component
        XCTAssertFalse(formatted.contains("T"))
    }

    // MARK: - isoDate

    func testIsoDateFormat() {
        let date = Date(timeIntervalSince1970: 1705312800)
        let formatted = DateFormatters.isoDate.string(from: date)
        // Should be in yyyy-MM-dd format
        XCTAssertTrue(formatted.contains("2024"))
        XCTAssertTrue(formatted.contains("01"))
        XCTAssertTrue(formatted.contains("15"))
    }

    func testIsoDateParseRoundTrip() {
        let dateString = "2024-06-15"
        let parsed = DateFormatters.isoDate.date(from: dateString)
        XCTAssertNotNil(parsed)
        let reformatted = DateFormatters.isoDate.string(from: parsed!)
        XCTAssertEqual(reformatted, dateString)
    }

    // MARK: - shortTime

    func testShortTimeFormat() {
        let date = Date(timeIntervalSince1970: 1705312800)
        let formatted = DateFormatters.shortTime.string(from: date)
        // Should produce a time string (locale-dependent, but not empty)
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - mediumDateTime

    func testMediumDateTimeFormat() {
        let date = Date(timeIntervalSince1970: 1705312800)
        let formatted = DateFormatters.mediumDateTime.string(from: date)
        XCTAssertFalse(formatted.isEmpty)
        // Should contain both date and time info
        XCTAssertTrue(formatted.contains("2024") || formatted.contains("24"))
    }

    // MARK: - filenameSafe

    func testFilenameSafeFormat() {
        let date = Date(timeIntervalSince1970: 1705312800)
        let formatted = DateFormatters.filenameSafe.string(from: date)
        // Format: yyyy-MM-dd_HHmmss
        XCTAssertTrue(formatted.contains("2024"))
        XCTAssertTrue(formatted.contains("_"))
        // Should not contain characters unsafe for filenames
        XCTAssertFalse(formatted.contains("/"))
        XCTAssertFalse(formatted.contains(":"))
        XCTAssertFalse(formatted.contains(" "))
    }

    // MARK: - relative

    func testRelativeFormatter() {
        let formatter = DateFormatters.relative
        // Just verify it's usable
        let result = formatter.localizedString(for: Date(), relativeTo: Date())
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Formatter consistency (same instance)

    func testFormattersSameInstance() {
        let a = DateFormatters.iso8601
        let b = DateFormatters.iso8601
        XCTAssertTrue(a === b, "Static formatters should return the same instance")

        let c = DateFormatters.isoDate
        let d = DateFormatters.isoDate
        XCTAssertTrue(c === d)

        let e = DateFormatters.filenameSafe
        let f = DateFormatters.filenameSafe
        XCTAssertTrue(e === f)
    }

    // MARK: - Additional formatters

    func testDayOfWeekFormat() {
        let date = Date(timeIntervalSince1970: 1705312800) // Monday Jan 15, 2024
        let formatted = DateFormatters.dayOfWeek.string(from: date)
        XCTAssertFalse(formatted.isEmpty)
        // Locale-dependent but should be a day name
    }

    func testHourMinute24Format() {
        let date = Date(timeIntervalSince1970: 1705312800)
        let formatted = DateFormatters.hourMinute24.string(from: date)
        XCTAssertTrue(formatted.contains(":"))
    }

    func testMonthDayFormat() {
        let date = Date(timeIntervalSince1970: 1705312800)
        let formatted = DateFormatters.monthDay.string(from: date)
        XCTAssertFalse(formatted.isEmpty)
    }
}
