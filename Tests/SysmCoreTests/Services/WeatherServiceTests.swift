import XCTest
@testable import SysmCore

final class WeatherServiceTests: XCTestCase {

    private let newYork = OpenMeteoTimeParser(timezone: "America/New_York", utcOffsetSeconds: -14400)

    private func utc(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    // MARK: - OpenMeteoTimeParser

    func testDateTimeIsReadInTheLocationZone() {
        // 17:00 EDT is 21:00 UTC. Read as UTC, it rendered as 13:00 in New York.
        XCTAssertEqual(newYork.dateTime("2026-09-12T17:00"), utc(2026, 9, 12, 21))
    }

    func testDateIsLocalMidnight() {
        XCTAssertEqual(newYork.date("2026-09-12"), utc(2026, 9, 12, 4))
    }

    func testDateTimeFollowsDSTInsideTheForecast() {
        // US DST ends 2026-11-01. The response's fixed -4h offset would give
        // 16:00 UTC; the zone name gives EST.
        XCTAssertEqual(newYork.dateTime("2026-11-02T12:00"), utc(2026, 11, 2, 17))
    }

    func testUnknownZoneFallsBackToTheOffset() {
        let parser = OpenMeteoTimeParser(timezone: "Not/AZone", utcOffsetSeconds: 19800)
        XCTAssertEqual(parser.dateTime("2026-09-12T12:00"), utc(2026, 9, 12, 6, 30))
    }

    func testUnknownZoneWithoutOffsetIsGMT() {
        let parser = OpenMeteoTimeParser(timezone: "Not/AZone", utcOffsetSeconds: nil)
        XCTAssertEqual(parser.timeZone, .gmt)
    }

    func testRejectsStringsInTheWrongShape() {
        XCTAssertNil(newYork.dateTime("2026-09-12"))
        XCTAssertNil(newYork.dateTime("not a date"))
        XCTAssertNil(newYork.date("not a date"))
    }

    // MARK: - Rendering

    func testHourlyRowShowsTheLocalHour() throws {
        let hour = try XCTUnwrap(newYork.dateTime("2026-09-12T17:00"))
        let forecast = HourlyForecast(
            location: "New York",
            hours: [HourForecast(time: hour, temperature: 70, precipitationProbability: 0, condition: .clear)],
            timezone: "America/New_York"
        )
        XCTAssertTrue(forecast.formatted().contains("17:00"), forecast.formatted())
    }

    // MARK: - Alerts

    func testOpenMeteoAlertsThrowInsteadOfReportingNone() async {
        do {
            _ = try await WeatherService().getAlerts(location: "New York")
            XCTFail("Expected WeatherError.alertsUnavailable")
        } catch WeatherError.alertsUnavailable {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
