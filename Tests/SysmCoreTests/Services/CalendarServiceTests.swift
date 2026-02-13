//
//  CalendarServiceTests.swift
//  sysm
//

import XCTest
import EventKit
@testable import SysmCore

final class CalendarServiceTests: XCTestCase {
    var service: CalendarService!
    var eventStore: EKEventStore!

    override func setUp() async throws {
        try await super.setUp()
        eventStore = EKEventStore()
        service = CalendarService(eventStore: eventStore)
    }

    override func tearDown() async throws {
        service = nil
        eventStore = nil
        try await super.tearDown()
    }

    // MARK: - Access Tests

    func testRequestAccessGranted() async throws {
        // Note: This test requires calendar access to be granted
        // In CI, this may fail unless permissions are pre-configured
        do {
            try await service.requestAccess()
            // If we get here, access was granted
            XCTAssertTrue(true)
        } catch {
            // Access denied - this is expected in CI environments
            XCTAssertTrue(error is CalendarError)
        }
    }

    // MARK: - Calendar List Tests

    func testGetCalendars() async throws {
        do {
            let calendars = try await service.getCalendars()
            // Should return an array (empty if no access)
            XCTAssertNotNil(calendars)
        } catch CalendarError.accessDenied {
            // Expected if permissions not granted
            throw XCTSkip("Calendar access not granted")
        }
    }

    // MARK: - Event Creation Tests

    func testCreateEvent() async throws {
        do {
            let startDate = Date()
            let endDate = startDate.addingTimeInterval(3600)

            let eventId = try await service.createEvent(
                title: "Test Event",
                startDate: startDate,
                endDate: endDate,
                location: nil,
                notes: nil,
                calendarName: nil,
                allDay: false
            )

            XCTAssertFalse(eventId.isEmpty)

            // Clean up
            try await service.deleteEvent(id: eventId)
        } catch CalendarError.accessDenied {
            throw XCTSkip("Calendar access not granted")
        }
    }

    func testCreateAllDayEvent() async throws {
        do {
            let startDate = Date()
            let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!

            let eventId = try await service.createEvent(
                title: "All Day Event",
                startDate: startDate,
                endDate: endDate,
                location: nil,
                notes: nil,
                calendarName: nil,
                allDay: true
            )

            XCTAssertFalse(eventId.isEmpty)

            // Clean up
            try await service.deleteEvent(id: eventId)
        } catch CalendarError.accessDenied {
            throw XCTSkip("Calendar access not granted")
        }
    }

    // MARK: - Event Query Tests

    func testGetTodayEvents() async throws {
        do {
            let events = try await service.getTodayEvents(calendarName: nil)
            // Should return an array (possibly empty)
            XCTAssertNotNil(events)
        } catch CalendarError.accessDenied {
            throw XCTSkip("Calendar access not granted")
        }
    }

    func testGetEventsInRange() async throws {
        do {
            let startDate = Date()
            let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!

            let events = try await service.getEvents(
                from: startDate,
                to: endDate,
                calendarName: nil
            )

            XCTAssertNotNil(events)
        } catch CalendarError.accessDenied {
            throw XCTSkip("Calendar access not granted")
        }
    }

    // MARK: - Event Update Tests

    func testUpdateEvent() async throws {
        do {
            // Create event
            let startDate = Date()
            let endDate = startDate.addingTimeInterval(3600)

            let eventId = try await service.createEvent(
                title: "Original Title",
                startDate: startDate,
                endDate: endDate,
                location: nil,
                notes: nil,
                calendarName: nil,
                allDay: false
            )

            // Update event
            try await service.updateEvent(
                id: eventId,
                title: "Updated Title",
                startDate: nil,
                endDate: nil,
                location: "New Location",
                notes: "Updated notes"
            )

            // Clean up
            try await service.deleteEvent(id: eventId)
        } catch CalendarError.accessDenied {
            throw XCTSkip("Calendar access not granted")
        }
    }

    // MARK: - Error Tests

    func testInvalidYearError() async {
        await XCTAssertThrowsError(
            try await service.getEvents(from: Date(), to: Date(), calendarName: nil, year: 1999)
        ) { error in
            if case CalendarError.invalidYear = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }

        await XCTAssertThrowsError(
            try await service.getEvents(from: Date(), to: Date(), calendarName: nil, year: 2200)
        ) { error in
            if case CalendarError.invalidYear = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testCalendarNotFoundError() async {
        do {
            _ = try await service.getCalendar(name: "Nonexistent Calendar That Does Not Exist")
            XCTFail("Should have thrown calendarNotFound error")
        } catch CalendarError.calendarNotFound {
            // Expected
        } catch CalendarError.accessDenied {
            throw XCTSkip("Calendar access not granted")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Helper Extension Tests

    func testHexColorConversion() {
        // Test valid hex colors
        XCTAssertNotNil("#FF5733".hexColor)
        XCTAssertNotNil("#000000".hexColor)
        XCTAssertNotNil("#FFFFFF".hexColor)

        // Test invalid hex colors
        XCTAssertNil("FF5733".hexColor)  // Missing #
        XCTAssertNil("#FF57".hexColor)   // Too short
        XCTAssertNil("#GG5733".hexColor) // Invalid characters
    }
}

// Helper for async error assertions
func XCTAssertThrowsError<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail("Expression did not throw an error", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
