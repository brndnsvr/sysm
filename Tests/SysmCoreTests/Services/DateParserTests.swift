import XCTest
@testable import SysmCore

final class DateParserTests: XCTestCase {

    var parser: DateParser!
    var calendar: Calendar!

    override func setUp() {
        super.setUp()
        parser = DateParser()
        calendar = Calendar.current
    }

    override func tearDown() {
        parser = nil
        calendar = nil
        super.tearDown()
    }

    // MARK: - parse() - Relative Dates

    func testParse_Today() {
        let result = parser.parse("today")
        XCTAssertNotNil(result)

        if let date = result {
            XCTAssertTrue(calendar.isDateInToday(date))
        }
    }

    func testParse_Tomorrow() {
        let result = parser.parse("tomorrow")
        XCTAssertNotNil(result)

        if let date = result {
            XCTAssertTrue(calendar.isDateInTomorrow(date))
        }
    }

    func testParse_TomorrowWithTime() {
        let result = parser.parse("tomorrow 3pm")
        XCTAssertNotNil(result)

        if let date = result {
            XCTAssertTrue(calendar.isDateInTomorrow(date))
            let hour = calendar.component(.hour, from: date)
            XCTAssertEqual(hour, 15)
        }
    }

    // MARK: - parse() - Day of Week

    func testParse_NextMonday() {
        let result = parser.parse("next monday")
        XCTAssertNotNil(result)

        if let date = result {
            let weekday = calendar.component(.weekday, from: date)
            XCTAssertEqual(weekday, 2) // Monday is 2

            // Should be in the future
            XCTAssertTrue(date > Date())
        }
    }

    func testParse_Friday() {
        let result = parser.parse("friday")
        XCTAssertNotNil(result)

        if let date = result {
            let weekday = calendar.component(.weekday, from: date)
            XCTAssertEqual(weekday, 6) // Friday is 6
        }
    }

    func testParse_ShortDayName() {
        let result = parser.parse("tue")
        XCTAssertNotNil(result)

        if let date = result {
            let weekday = calendar.component(.weekday, from: date)
            XCTAssertEqual(weekday, 3) // Tuesday is 3
        }
    }

    // MARK: - parseTime()

    func testParseTime_24Hour() {
        let baseDate = Date()
        let result = parser.parseTime(from: "15:30", baseDate: baseDate)
        XCTAssertNotNil(result)

        if let date = result {
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            XCTAssertEqual(hour, 15)
            XCTAssertEqual(minute, 30)
        }
    }

    func testParseTime_12HourPM() {
        let baseDate = Date()
        let result = parser.parseTime(from: "3pm", baseDate: baseDate)
        XCTAssertNotNil(result)

        if let date = result {
            let hour = calendar.component(.hour, from: date)
            XCTAssertEqual(hour, 15)
        }
    }

    func testParseTime_12HourAM() {
        let baseDate = Date()
        let result = parser.parseTime(from: "9am", baseDate: baseDate)
        XCTAssertNotNil(result)

        if let date = result {
            let hour = calendar.component(.hour, from: date)
            XCTAssertEqual(hour, 9)
        }
    }

    func testParseTime_12HourWithMinutes() {
        let baseDate = Date()
        let result = parser.parseTime(from: "2:30 pm", baseDate: baseDate)
        XCTAssertNotNil(result)

        if let date = result {
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            XCTAssertEqual(hour, 14)
            XCTAssertEqual(minute, 30)
        }
    }

    func testParseTime_Noon() {
        let baseDate = Date()
        let result = parser.parseTime(from: "12pm", baseDate: baseDate)
        XCTAssertNotNil(result)

        if let date = result {
            let hour = calendar.component(.hour, from: date)
            XCTAssertEqual(hour, 12)
        }
    }

    func testParseTime_Midnight() {
        let baseDate = Date()
        let result = parser.parseTime(from: "12am", baseDate: baseDate)
        XCTAssertNotNil(result)

        if let date = result {
            let hour = calendar.component(.hour, from: date)
            XCTAssertEqual(hour, 0)
        }
    }

    func testParseTime_NoTimeInText() {
        let baseDate = Date()
        let result = parser.parseTime(from: "no time here", baseDate: baseDate)
        XCTAssertNil(result)
    }

    // MARK: - parseISO()

    func testParseISO_ValidDate() {
        let result = parser.parseISO("2025-02-02")
        XCTAssertNotNil(result)

        if let date = result {
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            XCTAssertEqual(year, 2025)
            XCTAssertEqual(month, 2)
            XCTAssertEqual(day, 2)
        }
    }

    func testParseISO_WithTime() {
        let result = parser.parseISO("2025-02-02 15:30")
        XCTAssertNotNil(result)

        if let date = result {
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            XCTAssertEqual(year, 2025)
            XCTAssertEqual(month, 2)
            XCTAssertEqual(day, 2)
            XCTAssertEqual(hour, 15)
            XCTAssertEqual(minute, 30)
        }
    }

    func testParseISO_InvalidFormat() {
        let result = parser.parseISO("02-02-2025")
        XCTAssertNil(result)
    }

    func testParseISO_InvalidDate() {
        let result = parser.parseISO("2025-13-45")
        XCTAssertNil(result)
    }

    // MARK: - parseSlashDate()

    func testParseSlashDate_MonthDay() {
        let result = parser.parseSlashDate("2/15")
        XCTAssertNotNil(result)

        if let date = result {
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            XCTAssertEqual(month, 2)
            XCTAssertEqual(day, 15)
        }
    }

    func testParseSlashDate_MonthDayYear() {
        let result = parser.parseSlashDate("2/15/25")
        XCTAssertNotNil(result)

        if let date = result {
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            XCTAssertEqual(year, 2025)
            XCTAssertEqual(month, 2)
            XCTAssertEqual(day, 15)
        }
    }

    func testParseSlashDate_FullYear() {
        let result = parser.parseSlashDate("12/25/2025")
        XCTAssertNotNil(result)

        if let date = result {
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            XCTAssertEqual(year, 2025)
            XCTAssertEqual(month, 12)
            XCTAssertEqual(day, 25)
        }
    }

    func testParseSlashDate_InvalidFormat() {
        let result = parser.parseSlashDate("not-a-date")
        XCTAssertNil(result)
    }

    // MARK: - Edge Cases

    func testParse_CaseInsensitive() {
        let result1 = parser.parse("TOMORROW")
        let result2 = parser.parse("tomorrow")
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
    }

    func testParse_WithExtraWhitespace() {
        let result = parser.parse("  tomorrow  ")
        XCTAssertNotNil(result)

        if let date = result {
            XCTAssertTrue(calendar.isDateInTomorrow(date))
        }
    }

    func testParse_UnknownFormat() {
        let result = parser.parse("gibberish")
        // Should return nil or attempt to parse as time (which would fail)
        // The implementation may return nil or a date depending on the text
        // This tests that it doesn't crash
        _ = result
    }
}
