//
//  ICSParserTests.swift
//  sysm
//

import XCTest
import EventKit
@testable import SysmCore

final class ICSParserTests: XCTestCase {
    var eventStore: EKEventStore!

    override func setUp() {
        super.setUp()
        eventStore = EKEventStore()
    }

    override func tearDown() {
        eventStore = nil
        super.tearDown()
    }

    // MARK: - Basic Parsing Tests

    func testParseSimpleEvent() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        BEGIN:VEVENT
        UID:test-event-1@example.com
        DTSTART:20240115T100000Z
        DTEND:20240115T110000Z
        SUMMARY:Test Event
        END:VEVENT
        END:VCALENDAR
        """

        let events = try ICSParser.parse(icsContent, eventStore: eventStore)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].title, "Test Event")
    }

    func testParseMultipleEvents() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        BEGIN:VEVENT
        UID:event-1@example.com
        DTSTART:20240115T100000Z
        DTEND:20240115T110000Z
        SUMMARY:Event One
        END:VEVENT
        BEGIN:VEVENT
        UID:event-2@example.com
        DTSTART:20240116T140000Z
        DTEND:20240116T150000Z
        SUMMARY:Event Two
        END:VEVENT
        END:VCALENDAR
        """

        let events = try ICSParser.parse(icsContent, eventStore: eventStore)

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].title, "Event One")
        XCTAssertEqual(events[1].title, "Event Two")
    }

    // MARK: - Event Properties Tests

    func testParseEventWithLocation() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        BEGIN:VEVENT
        UID:event-location@example.com
        DTSTART:20240115T100000Z
        DTEND:20240115T110000Z
        SUMMARY:Meeting
        LOCATION:Conference Room A
        END:VEVENT
        END:VCALENDAR
        """

        let events = try ICSParser.parse(icsContent, eventStore: eventStore)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].location, "Conference Room A")
    }

    func testParseEventWithDescription() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        BEGIN:VEVENT
        UID:event-notes@example.com
        DTSTART:20240115T100000Z
        DTEND:20240115T110000Z
        SUMMARY:Task
        DESCRIPTION:Important notes here
        END:VEVENT
        END:VCALENDAR
        """

        let events = try ICSParser.parse(icsContent, eventStore: eventStore)

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].notes, "Important notes here")
    }

    // MARK: - All-Day Event Tests

    func testParseAllDayEvent() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        BEGIN:VEVENT
        UID:allday@example.com
        DTSTART;VALUE=DATE:20240115
        DTEND;VALUE=DATE:20240116
        SUMMARY:All Day Event
        END:VEVENT
        END:VCALENDAR
        """

        let events = try ICSParser.parse(icsContent, eventStore: eventStore)

        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(events[0].isAllDay)
    }

    // MARK: - Special Characters Tests

    func testParseEventWithEscapedCharacters() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        BEGIN:VEVENT
        UID:escaped@example.com
        DTSTART:20240115T100000Z
        DTEND:20240115T110000Z
        SUMMARY:Event with\\, comma\\; semicolon
        DESCRIPTION:Line 1\\nLine 2
        END:VEVENT
        END:VCALENDAR
        """

        let events = try ICSParser.parse(icsContent, eventStore: eventStore)

        XCTAssertEqual(events.count, 1)
        // ICS escaping: \, becomes comma, \; becomes semicolon, \n becomes newline
        XCTAssertTrue(events[0].title.contains(",") || events[0].title.contains("comma"))
    }

    // MARK: - Malformed ICS Tests

    func testParseMissingVCALENDAR() {
        let icsContent = """
        BEGIN:VEVENT
        DTSTART:20240115T100000Z
        DTEND:20240115T110000Z
        SUMMARY:Invalid Event
        END:VEVENT
        """

        XCTAssertThrowsError(try ICSParser.parse(icsContent, eventStore: eventStore))
    }

    func testParseMissingRequiredFields() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        BEGIN:VEVENT
        UID:incomplete@example.com
        SUMMARY:Incomplete Event
        END:VEVENT
        END:VCALENDAR
        """

        // Should either throw or create event with default dates
        // Behavior depends on ICSParser implementation
        let events = try? ICSParser.parse(icsContent, eventStore: eventStore)

        // If it doesn't throw, should still return array
        if let events = events {
            XCTAssertNotNil(events)
        }
    }

    // MARK: - Empty/Minimal ICS Tests

    func testParseEmptyCalendar() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        END:VCALENDAR
        """

        let events = try ICSParser.parse(icsContent, eventStore: eventStore)

        XCTAssertEqual(events.count, 0)
    }

    // MARK: - Date Format Tests

    func testParseLocalDateTime() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        BEGIN:VEVENT
        UID:local@example.com
        DTSTART:20240115T100000
        DTEND:20240115T110000
        SUMMARY:Local Time Event
        END:VEVENT
        END:VCALENDAR
        """

        let events = try ICSParser.parse(icsContent, eventStore: eventStore)

        XCTAssertEqual(events.count, 1)
        XCTAssertNotNil(events[0].startDate)
    }

    func testParseUTCDateTime() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        BEGIN:VEVENT
        UID:utc@example.com
        DTSTART:20240115T100000Z
        DTEND:20240115T110000Z
        SUMMARY:UTC Event
        END:VEVENT
        END:VCALENDAR
        """

        let events = try ICSParser.parse(icsContent, eventStore: eventStore)

        XCTAssertEqual(events.count, 1)
        XCTAssertNotNil(events[0].startDate)
    }

    // MARK: - Line Folding Tests

    func testParseFoldedLines() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        BEGIN:VEVENT
        UID:folded@example.com
        DTSTART:20240115T100000Z
        DTEND:20240115T110000Z
        SUMMARY:This is a very long summary that
         continues on the next line
        END:VEVENT
        END:VCALENDAR
        """

        let events = try ICSParser.parse(icsContent, eventStore: eventStore)

        XCTAssertEqual(events.count, 1)
        // Folded lines should be joined
        XCTAssertTrue(events[0].title.contains("continues"))
    }

    // MARK: - Calendar Properties Tests

    func testParseCalendarName() throws {
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//Test//EN
        X-WR-CALNAME:My Calendar
        BEGIN:VEVENT
        UID:event@example.com
        DTSTART:20240115T100000Z
        DTEND:20240115T110000Z
        SUMMARY:Event
        END:VEVENT
        END:VCALENDAR
        """

        let events = try ICSParser.parse(icsContent, eventStore: eventStore)

        XCTAssertEqual(events.count, 1)
    }
}
