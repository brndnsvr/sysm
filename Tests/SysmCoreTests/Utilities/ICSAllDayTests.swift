import EventKit
import XCTest
@testable import SysmCore

final class ICSAllDayTests: XCTestCase {

    private let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
    private let eventStore = EKEventStore()
    private var savedDefaultZone: TimeZone?

    override func setUp() {
        super.setUp()
        // EventKit snaps all-day dates to midnight in the default time zone,
        // so events built from Tokyo dates need Tokyo as the default.
        savedDefaultZone = NSTimeZone.default
        NSTimeZone.default = tokyo
    }

    override func tearDown() {
        if let savedDefaultZone {
            NSTimeZone.default = savedDefaultZone
        }
        super.tearDown()
    }

    private static let holiday = """
    BEGIN:VCALENDAR
    BEGIN:VEVENT
    SUMMARY:Holiday
    DTSTART;VALUE=DATE:20260101
    DTEND;VALUE=DATE:20260102
    END:VEVENT
    END:VCALENDAR
    """

    private func localDate(_ year: Int, _ month: Int, _ day: Int,
                           _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0,
                           in zone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar.date(from: DateComponents(year: year, month: month, day: day,
                                                  hour: hour, minute: minute, second: second))!
    }

    private func allDayEvent(from start: Date, to end: Date) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Holiday"
        event.isAllDay = true
        event.startDate = start
        event.endDate = end
        return event
    }

    // MARK: - Export

    func testExportWritesTheLocalDateEastOfUTC() {
        // Tokyo midnight on Jan 15 is Jan 14 15:00 UTC, which UTC formatting wrote as 20240114.
        let event = allDayEvent(from: localDate(2024, 1, 15, in: tokyo),
                                to: localDate(2024, 1, 15, 23, 59, 59, in: tokyo))
        let ics = ICSGenerator.generate(events: [event], calendarName: "Calendar", timeZone: tokyo)

        XCTAssertTrue(ics.contains("DTSTART;VALUE=DATE:20240115"), ics)
        XCTAssertTrue(ics.contains("DTEND;VALUE=DATE:20240116"), ics)
    }

    func testExportEndIsTheDayAfterTheLastDay() {
        let event = allDayEvent(from: localDate(2024, 1, 15, in: tokyo),
                                to: localDate(2024, 1, 17, 23, 59, 59, in: tokyo))
        let ics = ICSGenerator.generate(events: [event], calendarName: "Calendar", timeZone: tokyo)

        XCTAssertTrue(ics.contains("DTEND;VALUE=DATE:20240118"), ics)
    }

    // MARK: - Import

    func testImportLandsOnTheLocalDateWestOfUTC() throws {
        // Read as UTC, 20260101 became Dec 31 16:00 in Los Angeles.
        let event = try XCTUnwrap(ICSParser(content: Self.holiday, timeZone: losAngeles).parse().first)

        XCTAssertTrue(event.isAllDay)
        XCTAssertEqual(event.startDate, localDate(2026, 1, 1, in: losAngeles))
    }

    func testImportEndsWithinTheLastDay() throws {
        let event = try XCTUnwrap(ICSParser(content: Self.holiday, timeZone: losAngeles).parse().first)

        XCTAssertEqual(event.endDate, localDate(2026, 1, 1, 23, 59, 59, in: losAngeles))
    }

    func testImportTreatsAnEndEqualToTheStartAsOneDay() throws {
        let ics = Self.holiday.replacingOccurrences(of: "DTEND;VALUE=DATE:20260102",
                                                    with: "DTEND;VALUE=DATE:20260101")
        let event = try XCTUnwrap(ICSParser(content: ics, timeZone: losAngeles).parse().first)

        XCTAssertEqual(event.endDate, event.startDate)
    }

    // MARK: - Round trip

    func testRoundTripKeepsDatesAndLength() throws {
        let start = localDate(2024, 3, 9, in: tokyo)
        let end = localDate(2024, 3, 10, 23, 59, 59, in: tokyo)
        let ics = ICSGenerator.generate(events: [allDayEvent(from: start, to: end)],
                                        calendarName: "Calendar", timeZone: tokyo)
        let parsed = try XCTUnwrap(ICSParser(content: ics, timeZone: tokyo).parse().first)

        XCTAssertTrue(parsed.isAllDay)
        XCTAssertEqual(parsed.startDate, start)
        XCTAssertEqual(parsed.endDate, end)
    }
}
