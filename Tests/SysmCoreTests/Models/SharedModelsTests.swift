import XCTest
@testable import SysmCore

final class SharedModelsTests: XCTestCase {

    // MARK: - EventAlarm

    func testEventAlarmAtTimeOfEvent() {
        let alarm = EventAlarm(triggerMinutes: 0)
        XCTAssertEqual(alarm.description, "At time of event")
    }

    func testEventAlarmMinutesBefore() {
        XCTAssertEqual(EventAlarm(triggerMinutes: 1).description, "1 minute before")
        XCTAssertEqual(EventAlarm(triggerMinutes: 15).description, "15 minutes before")
        XCTAssertEqual(EventAlarm(triggerMinutes: 59).description, "59 minutes before")
    }

    func testEventAlarmHoursBefore() {
        XCTAssertEqual(EventAlarm(triggerMinutes: 60).description, "1 hour before")
        XCTAssertEqual(EventAlarm(triggerMinutes: 120).description, "2 hours before")
    }

    func testEventAlarmDaysBefore() {
        XCTAssertEqual(EventAlarm(triggerMinutes: 1440).description, "1 day before")
        XCTAssertEqual(EventAlarm(triggerMinutes: 2880).description, "2 days before")
    }

    func testEventAlarmLocationBased() {
        let loc = StructuredLocation(title: "Office")
        let alarmEnter = EventAlarm(location: loc, proximity: "enter")
        XCTAssertTrue(alarmEnter.description.contains("arriving"))
        XCTAssertTrue(alarmEnter.description.contains("Office"))

        let alarmLeave = EventAlarm(location: loc, proximity: "leave")
        XCTAssertTrue(alarmLeave.description.contains("leaving"))
    }

    func testEventAlarmCodableRoundTrip() throws {
        let alarm = EventAlarm(triggerMinutes: 30)
        let data = try JSONEncoder().encode(alarm)
        let decoded = try JSONDecoder().decode(EventAlarm.self, from: data)
        XCTAssertEqual(decoded.triggerMinutes, 30)
        XCTAssertEqual(decoded.type, "display")
    }

    // MARK: - EventAvailability

    func testEventAvailabilityCodableRoundTrip() throws {
        for availability in EventAvailability.allCases {
            let data = try JSONEncoder().encode(availability)
            let decoded = try JSONDecoder().decode(EventAvailability.self, from: data)
            XCTAssertEqual(decoded, availability)
        }
    }

    func testEventAvailabilityAllCases() {
        XCTAssertEqual(EventAvailability.allCases.count, 4)
        XCTAssertTrue(EventAvailability.allCases.contains(.busy))
        XCTAssertTrue(EventAvailability.allCases.contains(.free))
        XCTAssertTrue(EventAvailability.allCases.contains(.tentative))
        XCTAssertTrue(EventAvailability.allCases.contains(.unavailable))
    }

    // MARK: - StructuredLocation

    func testStructuredLocationBasic() {
        let loc = StructuredLocation(title: "Apple Park")
        XCTAssertEqual(loc.title, "Apple Park")
        XCTAssertNil(loc.address)
        XCTAssertNil(loc.latitude)
        XCTAssertNil(loc.longitude)
        XCTAssertEqual(loc.radius, 100.0) // Default
    }

    func testStructuredLocationWithCoordinates() {
        let loc = StructuredLocation(title: "Office", latitude: 37.33, longitude: -122.01, radius: 50.0)
        XCTAssertEqual(loc.latitude, 37.33)
        XCTAssertEqual(loc.longitude, -122.01)
        XCTAssertEqual(loc.radius, 50.0)
    }

    func testStructuredLocationCodableRoundTrip() throws {
        let loc = StructuredLocation(title: "Home", address: "123 Main St", latitude: 40.7, longitude: -74.0, radius: 200.0)
        let data = try JSONEncoder().encode(loc)
        let decoded = try JSONDecoder().decode(StructuredLocation.self, from: data)
        XCTAssertEqual(decoded.title, "Home")
        XCTAssertEqual(decoded.address, "123 Main St")
        XCTAssertEqual(decoded.latitude, 40.7)
        XCTAssertEqual(decoded.longitude, -74.0)
        XCTAssertEqual(decoded.radius, 200.0)
    }
}
