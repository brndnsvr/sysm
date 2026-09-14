import XCTest
@testable import SysmCore

final class ICSTimeZoneTests: XCTestCase {

    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    private func utc(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func event(start: String, end: String) throws -> ICSEventData? {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Standup
        \(start)
        \(end)
        END:VEVENT
        END:VCALENDAR
        """
        return try ICSParser(content: ics, timeZone: losAngeles).parse().first
    }

    func testTZIDTimesAreReadInTheirZone() throws {
        // Only times ending in Z used to parse; this event was dropped.
        let parsed = try XCTUnwrap(event(start: "DTSTART;TZID=America/New_York:20260115T090000",
                                         end: "DTEND;TZID=America/New_York:20260115T093000"))

        XCTAssertFalse(parsed.isAllDay)
        XCTAssertEqual(parsed.startDate, utc(2026, 1, 15, 14))
        XCTAssertEqual(parsed.endDate, utc(2026, 1, 15, 14, 30))
    }

    func testQuotedTZIDIsRead() throws {
        let parsed = try XCTUnwrap(event(start: #"DTSTART;TZID="Europe/Paris":20260115T090000"#,
                                         end: #"DTEND;TZID="Europe/Paris":20260115T100000"#))

        XCTAssertEqual(parsed.startDate, utc(2026, 1, 15, 8))
    }

    func testFloatingTimesUseTheParserZone() throws {
        let parsed = try XCTUnwrap(event(start: "DTSTART:20260115T090000", end: "DTEND:20260115T100000"))

        XCTAssertEqual(parsed.startDate, utc(2026, 1, 15, 17))
    }

    func testUTCTimesStillParse() throws {
        let parsed = try XCTUnwrap(event(start: "DTSTART:20260115T090000Z", end: "DTEND:20260115T100000Z"))

        XCTAssertEqual(parsed.startDate, utc(2026, 1, 15, 9))
    }

    func testUnknownZoneNameWithAColonIsReadAsFloating() throws {
        // The colon inside the quotes used to end the property name early.
        let parsed = try XCTUnwrap(event(start: #"DTSTART;TZID="(UTC-05:00) Eastern Time":20260115T090000"#,
                                         end: #"DTEND;TZID="(UTC-05:00) Eastern Time":20260115T100000"#))

        XCTAssertEqual(parsed.startDate, utc(2026, 1, 15, 17))
    }
}
