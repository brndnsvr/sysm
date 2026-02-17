import XCTest
@testable import SysmCore

final class CalendarEventModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeEvent(
        id: String = "evt-1",
        title: String = "Team Meeting",
        calendarName: String = "Work",
        startDate: Date = Date(timeIntervalSince1970: 1705312800), // Jan 15, 2024 10:00 AM UTC
        endDate: Date = Date(timeIntervalSince1970: 1705316400),   // Jan 15, 2024 11:00 AM UTC
        isAllDay: Bool = false,
        location: String? = nil,
        notes: String? = nil,
        url: String? = nil,
        hasRecurrence: Bool = false,
        recurrenceRule: RecurrenceRule? = nil,
        attendees: [EventAttendee]? = nil,
        alarms: [EventAlarm]? = nil
    ) -> CalendarEvent {
        // Use JSON round-trip to construct since CalendarEvent's public init requires EKEvent
        let json: [String: Any] = [
            "id": id,
            "title": title,
            "calendarName": calendarName,
            "startDate": startDate.timeIntervalSinceReferenceDate,
            "endDate": endDate.timeIntervalSinceReferenceDate,
            "isAllDay": isAllDay,
            "hasRecurrence": hasRecurrence,
            "availability": "busy",
        ]

        // Build with full Codable JSON
        var jsonDict: [String: Any] = json
        if let loc = location { jsonDict["location"] = loc }
        if let n = notes { jsonDict["notes"] = n }
        if let u = url { jsonDict["url"] = u }

        let data = try! JSONSerialization.data(withJSONObject: jsonDict)
        return try! JSONDecoder().decode(CalendarEvent.self, from: data)
    }

    // MARK: - timeRange

    func testTimeRangeAllDay() {
        let event = makeEvent(isAllDay: true)
        XCTAssertEqual(event.timeRange, "All day")
    }

    func testTimeRangeNonAllDay() {
        let event = makeEvent(isAllDay: false)
        // Should contain " - " separator for time range
        XCTAssertTrue(event.timeRange.contains(" - "))
    }

    // MARK: - formatted()

    func testFormattedBasic() {
        let event = makeEvent(title: "Standup")
        let result = event.formatted()
        XCTAssertTrue(result.hasPrefix("- "))
        XCTAssertTrue(result.contains("Standup"))
    }

    func testFormattedWithLocation() {
        let event = makeEvent(location: "Room A")
        let result = event.formatted()
        XCTAssertTrue(result.contains("@ Room A"))
    }

    func testFormattedEmptyLocation() {
        let event = makeEvent(location: "")
        let result = event.formatted()
        XCTAssertFalse(result.contains("@"))
    }

    func testFormattedWithCalendar() {
        let event = makeEvent(calendarName: "Personal")
        let result = event.formatted(showCalendar: true)
        XCTAssertTrue(result.contains("[Personal]"))
    }

    func testFormattedWithRecurrence() {
        let event = makeEvent(hasRecurrence: true)
        let result = event.formatted()
        XCTAssertTrue(result.contains("[repeating]"))
    }

    // MARK: - detailedDescription

    func testDetailedDescriptionBasic() {
        let event = makeEvent(title: "Design Review", calendarName: "Work")
        let desc = event.detailedDescription
        XCTAssertTrue(desc.contains("Title: Design Review"))
        XCTAssertTrue(desc.contains("Calendar: Work"))
        XCTAssertTrue(desc.contains("Date:"))
        XCTAssertTrue(desc.contains("Time:"))
        XCTAssertTrue(desc.contains("Availability: busy"))
    }

    func testDetailedDescriptionWithLocation() {
        let event = makeEvent(location: "Conference Room B")
        let desc = event.detailedDescription
        XCTAssertTrue(desc.contains("Location: Conference Room B"))
    }

    func testDetailedDescriptionWithUrl() {
        let event = makeEvent(url: "https://zoom.us/j/123")
        let desc = event.detailedDescription
        XCTAssertTrue(desc.contains("URL: https://zoom.us/j/123"))
    }

    func testDetailedDescriptionWithNotes() {
        let event = makeEvent(notes: "Bring the report")
        let desc = event.detailedDescription
        XCTAssertTrue(desc.contains("Notes: Bring the report"))
    }

    // MARK: - Codable round-trip

    func testCalendarEventCodableRoundTrip() throws {
        let event = makeEvent(title: "Roundtrip Test", location: "Here")
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(CalendarEvent.self, from: data)
        XCTAssertEqual(decoded.id, event.id)
        XCTAssertEqual(decoded.title, "Roundtrip Test")
        XCTAssertEqual(decoded.calendarName, "Work")
        XCTAssertEqual(decoded.location, "Here")
    }
}
