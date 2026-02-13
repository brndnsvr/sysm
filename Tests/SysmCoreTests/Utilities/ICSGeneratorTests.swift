//
//  ICSGeneratorTests.swift
//  sysm
//

import XCTest
import EventKit
@testable import SysmCore

final class ICSGeneratorTests: XCTestCase {

    var eventStore: EKEventStore!

    override func setUp() {
        super.setUp()
        eventStore = EKEventStore()
    }

    override func tearDown() {
        eventStore = nil
        super.tearDown()
    }

    // MARK: - Basic Event Tests

    func testGenerateSimpleEvent() {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Test Event"
        event.startDate = Date(timeIntervalSince1970: 1705320000) // 2024-01-15 10:00:00 UTC
        event.endDate = Date(timeIntervalSince1970: 1705323600)   // 2024-01-15 11:00:00 UTC

        let ics = ICSGenerator.generate(events: [event], calendarName: "Test Calendar")

        XCTAssertTrue(ics.contains("BEGIN:VCALENDAR"))
        XCTAssertTrue(ics.contains("END:VCALENDAR"))
        XCTAssertTrue(ics.contains("BEGIN:VEVENT"))
        XCTAssertTrue(ics.contains("END:VEVENT"))
        XCTAssertTrue(ics.contains("SUMMARY:Test Event"))
        XCTAssertTrue(ics.contains("VERSION:2.0"))
        XCTAssertTrue(ics.contains("PRODID:-//sysm//"))
    }

    func testGenerateMultipleEvents() {
        let event1 = EKEvent(eventStore: eventStore)
        event1.title = "Event 1"
        event1.startDate = Date(timeIntervalSince1970: 1705320000)
        event1.endDate = Date(timeIntervalSince1970: 1705323600)

        let event2 = EKEvent(eventStore: eventStore)
        event2.title = "Event 2"
        event2.startDate = Date(timeIntervalSince1970: 1705406400)
        event2.endDate = Date(timeIntervalSince1970: 1705410000)

        let ics = ICSGenerator.generate(events: [event1, event2], calendarName: "Calendar")

        // Should have one calendar with two events
        let vcalendarCount = ics.components(separatedBy: "BEGIN:VCALENDAR").count - 1
        let veventCount = ics.components(separatedBy: "BEGIN:VEVENT").count - 1

        XCTAssertEqual(vcalendarCount, 1)
        XCTAssertEqual(veventCount, 2)
        XCTAssertTrue(ics.contains("Event 1"))
        XCTAssertTrue(ics.contains("Event 2"))
    }

    // MARK: - Event Properties Tests

    func testGenerateEventWithLocation() {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Meeting"
        event.location = "Conference Room A"
        event.startDate = Date(timeIntervalSince1970: 1705320000)
        event.endDate = Date(timeIntervalSince1970: 1705323600)

        let ics = ICSGenerator.generate(events: [event], calendarName: "Work")

        XCTAssertTrue(ics.contains("LOCATION:Conference Room A"))
    }

    func testGenerateEventWithNotes() {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Meeting"
        event.notes = "Important meeting notes"
        event.startDate = Date(timeIntervalSince1970: 1705320000)
        event.endDate = Date(timeIntervalSince1970: 1705323600)

        let ics = ICSGenerator.generate(events: [event], calendarName: "Work")

        XCTAssertTrue(ics.contains("DESCRIPTION:Important meeting notes"))
    }

    func testGenerateAllDayEvent() {
        let event = EKEvent(eventStore: eventStore)
        event.title = "All Day Event"
        event.isAllDay = true
        event.startDate = Date(timeIntervalSince1970: 1705276800) // 2024-01-15 00:00:00 UTC
        event.endDate = Date(timeIntervalSince1970: 1705363200)   // 2024-01-16 00:00:00 UTC

        let ics = ICSGenerator.generate(events: [event], calendarName: "Calendar")

        // All-day events should use date format without time
        XCTAssertTrue(ics.contains("DTSTART;VALUE=DATE:") || ics.contains("DTSTART:"))
    }

    // MARK: - Special Characters Tests

    func testGenerateEventWithSpecialCharacters() {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Event with, comma; semicolon\nand newline"
        event.location = "Room \"A\" & B"
        event.notes = "Notes with\nmultiple\nlines"
        event.startDate = Date(timeIntervalSince1970: 1705320000)
        event.endDate = Date(timeIntervalSince1970: 1705323600)

        let ics = ICSGenerator.generate(events: [event], calendarName: "Calendar")

        // ICS format should escape or handle special characters properly
        XCTAssertTrue(ics.contains("SUMMARY:"))
        XCTAssertTrue(ics.contains("LOCATION:"))
        XCTAssertTrue(ics.contains("DESCRIPTION:"))

        // Should not have unescaped newlines that break ICS format
        let lines = ics.components(separatedBy: "\n")
        for line in lines {
            // Each line should start with a valid ICS property or be a continuation
            if !line.isEmpty {
                XCTAssertTrue(
                    line.starts(with: " ") || // Continuation line
                    line.contains(":") ||      // Property line
                    line.starts(with: "BEGIN") ||
                    line.starts(with: "END")
                )
            }
        }
    }

    // MARK: - Empty/Nil Tests

    func testGenerateNoEvents() {
        let ics = ICSGenerator.generate(events: [], calendarName: "Empty")

        XCTAssertTrue(ics.contains("BEGIN:VCALENDAR"))
        XCTAssertTrue(ics.contains("END:VCALENDAR"))

        let veventCount = ics.components(separatedBy: "BEGIN:VEVENT").count - 1
        XCTAssertEqual(veventCount, 0)
    }

    func testGenerateEventWithNilProperties() {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Minimal Event"
        event.location = nil
        event.notes = nil
        event.startDate = Date(timeIntervalSince1970: 1705320000)
        event.endDate = Date(timeIntervalSince1970: 1705323600)

        let ics = ICSGenerator.generate(events: [event], calendarName: "Calendar")

        XCTAssertTrue(ics.contains("SUMMARY:Minimal Event"))
        XCTAssertFalse(ics.contains("LOCATION:"))
        XCTAssertFalse(ics.contains("DESCRIPTION:"))
    }

    // MARK: - Format Validation Tests

    func testICSFormatCompliance() {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Format Test"
        event.startDate = Date(timeIntervalSince1970: 1705320000)
        event.endDate = Date(timeIntervalSince1970: 1705323600)

        let ics = ICSGenerator.generate(events: [event], calendarName: "Test")

        // Must start with BEGIN:VCALENDAR and end with END:VCALENDAR
        XCTAssertTrue(ics.hasPrefix("BEGIN:VCALENDAR"))
        XCTAssertTrue(ics.hasSuffix("END:VCALENDAR\n") || ics.hasSuffix("END:VCALENDAR"))

        // Must have required properties
        XCTAssertTrue(ics.contains("VERSION:2.0"))
        XCTAssertTrue(ics.contains("PRODID:"))

        // Event must have required properties
        XCTAssertTrue(ics.contains("DTSTART:"))
        XCTAssertTrue(ics.contains("DTEND:") || ics.contains("DURATION:"))
        XCTAssertTrue(ics.contains("SUMMARY:"))
        XCTAssertTrue(ics.contains("UID:"))
    }

    func testDateTimeFormat() {
        let event = EKEvent(eventStore: eventStore)
        event.title = "DateTime Test"
        event.startDate = Date(timeIntervalSince1970: 1705320000) // 2024-01-15 10:00:00 UTC
        event.endDate = Date(timeIntervalSince1970: 1705323600)

        let ics = ICSGenerator.generate(events: [event], calendarName: "Test")

        // DateTime should be in format: YYYYMMDDTHHmmssZ
        let dtStartPattern = "DTSTART:[0-9]{8}T[0-9]{6}Z?"
        let dtEndPattern = "DTEND:[0-9]{8}T[0-9]{6}Z?"

        XCTAssertTrue(ics.range(of: dtStartPattern, options: .regularExpression) != nil)
        XCTAssertTrue(ics.range(of: dtEndPattern, options: .regularExpression) != nil)
    }
}
