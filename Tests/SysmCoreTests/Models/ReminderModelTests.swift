import XCTest
@testable import SysmCore

final class ReminderModelTests: XCTestCase {

    // MARK: - ReminderPriority.from(ekPriority:)

    func testPriorityFromEKNone() {
        XCTAssertEqual(ReminderPriority.from(ekPriority: 0), .none)
    }

    func testPriorityFromEKHigh() {
        XCTAssertEqual(ReminderPriority.from(ekPriority: 1), .high)
        XCTAssertEqual(ReminderPriority.from(ekPriority: 2), .high)
        XCTAssertEqual(ReminderPriority.from(ekPriority: 3), .high)
        XCTAssertEqual(ReminderPriority.from(ekPriority: 4), .high)
    }

    func testPriorityFromEKMedium() {
        XCTAssertEqual(ReminderPriority.from(ekPriority: 5), .medium)
    }

    func testPriorityFromEKLow() {
        XCTAssertEqual(ReminderPriority.from(ekPriority: 6), .low)
        XCTAssertEqual(ReminderPriority.from(ekPriority: 7), .low)
        XCTAssertEqual(ReminderPriority.from(ekPriority: 8), .low)
        XCTAssertEqual(ReminderPriority.from(ekPriority: 9), .low)
    }

    func testPriorityFromEKOutOfRange() {
        XCTAssertEqual(ReminderPriority.from(ekPriority: 10), .none)
        XCTAssertEqual(ReminderPriority.from(ekPriority: -1), .none)
    }

    // MARK: - ReminderPriority.description

    func testPriorityDescription() {
        XCTAssertEqual(ReminderPriority.none.description, "None")
        XCTAssertEqual(ReminderPriority.high.description, "High")
        XCTAssertEqual(ReminderPriority.medium.description, "Medium")
        XCTAssertEqual(ReminderPriority.low.description, "Low")
    }

    // MARK: - Reminder.formatted() via JSON decode

    private func makeReminder(
        title: String = "Buy groceries",
        isCompleted: Bool = false,
        priority: Int = 0,
        priorityLevel: Int = 0,
        listName: String = "Shopping",
        hasRecurrence: Bool = false,
        notes: String? = nil,
        url: String? = nil
    ) -> Reminder {
        var dict: [String: Any] = [
            "id": "test-id",
            "title": title,
            "listName": listName,
            "isCompleted": isCompleted,
            "priority": priority,
            "priorityLevel": priorityLevel,
            "hasRecurrence": hasRecurrence,
            "hasAlarms": false,
        ]
        if let notes = notes { dict["notes"] = notes }
        if let url = url { dict["url"] = url }
        let data = try! JSONSerialization.data(withJSONObject: dict)
        return try! JSONDecoder().decode(Reminder.self, from: data)
    }

    func testFormattedIncomplete() {
        let reminder = makeReminder(isCompleted: false)
        let output = reminder.formatted()
        XCTAssertTrue(output.contains("[ ]"))
        XCTAssertTrue(output.contains("Buy groceries"))
    }

    func testFormattedComplete() {
        let reminder = makeReminder(isCompleted: true)
        let output = reminder.formatted()
        XCTAssertTrue(output.contains("[x]"))
    }

    func testFormattedWithPriority() {
        let reminder = makeReminder(priorityLevel: 1) // high
        let output = reminder.formatted()
        XCTAssertTrue(output.contains("!high"))
    }

    func testFormattedIncludeList() {
        let reminder = makeReminder(listName: "Work")
        let output = reminder.formatted(includeList: true)
        XCTAssertTrue(output.contains("[Work]"))
    }

    func testFormattedShowDetails() {
        let reminder = makeReminder(notes: "Pick up milk", url: "https://example.com")
        let output = reminder.formatted(showDetails: true)
        XCTAssertTrue(output.contains("Notes:"))
        XCTAssertTrue(output.contains("URL:"))
    }

    // MARK: - Reminder.detailedDescription

    func testDetailedDescription() {
        let reminder = makeReminder(title: "Call dentist", priorityLevel: 1, listName: "Health")
        let output = reminder.detailedDescription
        XCTAssertTrue(output.contains("Call dentist"))
        XCTAssertTrue(output.contains("List: Health"))
        XCTAssertTrue(output.contains("Priority: High"))
    }
}
