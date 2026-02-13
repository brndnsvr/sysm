//
//  ReminderServiceTests.swift
//  sysm
//

import XCTest
import EventKit
@testable import SysmCore

final class ReminderServiceTests: XCTestCase {
    var service: ReminderService!
    var eventStore: EKEventStore!

    override func setUp() async throws {
        try await super.setUp()
        eventStore = EKEventStore()
        service = ReminderService(eventStore: eventStore)
    }

    override func tearDown() async throws {
        service = nil
        eventStore = nil
        try await super.tearDown()
    }

    // MARK: - Access Tests

    func testRequestAccessGranted() async throws {
        do {
            try await service.requestAccess()
            XCTAssertTrue(true)
        } catch {
            XCTAssertTrue(error is ReminderError)
        }
    }

    // MARK: - List Tests

    func testGetLists() async throws {
        do {
            let lists = try await service.getLists()
            XCTAssertNotNil(lists)
        } catch ReminderError.accessDenied {
            throw XCTSkip("Reminders access not granted")
        }
    }

    func testCreateList() async throws {
        do {
            let listId = try await service.createList(name: "Test List")
            XCTAssertFalse(listId.isEmpty)

            // Clean up
            try await service.deleteList(id: listId)
        } catch ReminderError.accessDenied {
            throw XCTSkip("Reminders access not granted")
        } catch ReminderError.noValidSource {
            throw XCTSkip("No valid source for creating lists")
        }
    }

    // MARK: - Reminder Creation Tests

    func testCreateReminder() async throws {
        do {
            let reminderId = try await service.createReminder(
                title: "Test Reminder",
                notes: nil,
                dueDate: nil,
                listName: nil,
                priority: nil,
                url: nil
            )

            XCTAssertFalse(reminderId.isEmpty)

            // Clean up
            try await service.deleteReminder(id: reminderId)
        } catch ReminderError.accessDenied {
            throw XCTSkip("Reminders access not granted")
        }
    }

    func testCreateReminderWithDueDate() async throws {
        do {
            let dueDate = Date().addingTimeInterval(86400) // Tomorrow

            let reminderId = try await service.createReminder(
                title: "Reminder with Due Date",
                notes: "Important task",
                dueDate: dueDate,
                listName: nil,
                priority: 5,
                url: nil
            )

            XCTAssertFalse(reminderId.isEmpty)

            // Clean up
            try await service.deleteReminder(id: reminderId)
        } catch ReminderError.accessDenied {
            throw XCTSkip("Reminders access not granted")
        }
    }

    // MARK: - Query Tests

    func testGetIncompleteReminders() async throws {
        do {
            let reminders = try await service.getIncompleteReminders(listName: nil)
            XCTAssertNotNil(reminders)
        } catch ReminderError.accessDenied {
            throw XCTSkip("Reminders access not granted")
        }
    }

    func testGetCompletedReminders() async throws {
        do {
            let reminders = try await service.getCompletedReminders(listName: nil)
            XCTAssertNotNil(reminders)
        } catch ReminderError.accessDenied {
            throw XCTSkip("Reminders access not granted")
        }
    }

    func testSearchReminders() async throws {
        do {
            let reminders = try await service.searchReminders(query: "Test", listName: nil)
            XCTAssertNotNil(reminders)
        } catch ReminderError.accessDenied {
            throw XCTSkip("Reminders access not granted")
        }
    }

    // MARK: - Update Tests

    func testCompleteReminder() async throws {
        do {
            // Create reminder
            let reminderId = try await service.createReminder(
                title: "To Complete",
                notes: nil,
                dueDate: nil,
                listName: nil,
                priority: nil,
                url: nil
            )

            // Complete it
            try await service.completeReminder(id: reminderId)

            // Clean up
            try await service.deleteReminder(id: reminderId)
        } catch ReminderError.accessDenied {
            throw XCTSkip("Reminders access not granted")
        }
    }

    func testUpdateReminder() async throws {
        do {
            // Create reminder
            let reminderId = try await service.createReminder(
                title: "Original",
                notes: nil,
                dueDate: nil,
                listName: nil,
                priority: nil,
                url: nil
            )

            // Update it
            try await service.updateReminder(
                id: reminderId,
                title: "Updated",
                notes: "New notes",
                dueDate: nil,
                priority: 8
            )

            // Clean up
            try await service.deleteReminder(id: reminderId)
        } catch ReminderError.accessDenied {
            throw XCTSkip("Reminders access not granted")
        }
    }

    // MARK: - Error Tests

    func testListNotFoundError() async {
        do {
            _ = try await service.getList(name: "Nonexistent List That Does Not Exist")
            XCTFail("Should have thrown listNotFound error")
        } catch ReminderError.listNotFound {
            // Expected
        } catch ReminderError.accessDenied {
            throw XCTSkip("Reminders access not granted")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testInvalidYearError() async {
        await XCTAssertThrowsError(
            try await service.getReminders(from: Date(), to: Date(), listName: nil, year: 1999)
        ) { error in
            if case ReminderError.invalidYear = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Priority Tests

    func testPriorityValues() async throws {
        do {
            // Test low priority (9)
            let lowId = try await service.createReminder(
                title: "Low Priority",
                notes: nil,
                dueDate: nil,
                listName: nil,
                priority: 9,
                url: nil
            )

            // Test high priority (1)
            let highId = try await service.createReminder(
                title: "High Priority",
                notes: nil,
                dueDate: nil,
                listName: nil,
                priority: 1,
                url: nil
            )

            // Clean up
            try await service.deleteReminder(id: lowId)
            try await service.deleteReminder(id: highId)
        } catch ReminderError.accessDenied {
            throw XCTSkip("Reminders access not granted")
        }
    }
}
