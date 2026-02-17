import XCTest
@testable import SysmCore

final class TrackedReminderTests: XCTestCase {

    // MARK: - Codable round-trip with snake_case CodingKeys

    func testCodableRoundTrip() throws {
        let reminder = TrackedReminder(
            originalName: "Buy groceries",
            firstSeen: "2024-01-15",
            tracked: true,
            dismissed: false,
            project: "personal",
            status: "pending",
            completedDate: nil
        )
        let data = try JSONEncoder().encode(reminder)
        let decoded = try JSONDecoder().decode(TrackedReminder.self, from: data)
        XCTAssertEqual(decoded.originalName, "Buy groceries")
        XCTAssertEqual(decoded.firstSeen, "2024-01-15")
        XCTAssertTrue(decoded.tracked)
        XCTAssertFalse(decoded.dismissed)
        XCTAssertEqual(decoded.project, "personal")
        XCTAssertEqual(decoded.status, "pending")
        XCTAssertNil(decoded.completedDate)
    }

    func testCodableWithCompletedDate() throws {
        let reminder = TrackedReminder(
            originalName: "Ship feature",
            tracked: true,
            status: "done",
            completedDate: "2024-01-16"
        )
        let data = try JSONEncoder().encode(reminder)
        let decoded = try JSONDecoder().decode(TrackedReminder.self, from: data)
        XCTAssertEqual(decoded.completedDate, "2024-01-16")
        XCTAssertEqual(decoded.status, "done")
    }

    // MARK: - snake_case JSON keys

    func testSnakeCaseEncoding() throws {
        let reminder = TrackedReminder(originalName: "Test", firstSeen: "2024-01-15", completedDate: "2024-01-16")
        let data = try JSONEncoder().encode(reminder)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        // Keys should be snake_case
        XCTAssertNotNil(json["original_name"])
        XCTAssertNotNil(json["first_seen"])
        XCTAssertNotNil(json["completed_date"])
        // camelCase should NOT be present
        XCTAssertNil(json["originalName"])
        XCTAssertNil(json["firstSeen"])
        XCTAssertNil(json["completedDate"])
    }

    // MARK: - todayString()

    func testTodayStringFormat() {
        let today = TrackedReminder.todayString()
        // Should be ISO date format: yyyy-MM-dd
        let parts = today.split(separator: "-")
        XCTAssertEqual(parts.count, 3, "todayString should return yyyy-MM-dd format")
        XCTAssertEqual(parts[0].count, 4, "Year should be 4 digits")
        XCTAssertEqual(parts[1].count, 2, "Month should be 2 digits")
        XCTAssertEqual(parts[2].count, 2, "Day should be 2 digits")
    }

    // MARK: - makeKey()

    func testMakeKeyLowercases() {
        XCTAssertEqual(TrackedReminder.makeKey("Buy Groceries"), "buy groceries")
    }

    func testMakeKeyTrims() {
        XCTAssertEqual(TrackedReminder.makeKey("  spaced  "), "spaced")
    }

    func testMakeKeyNormalization() {
        // Same input should produce same key
        let key1 = TrackedReminder.makeKey("Buy GROCERIES")
        let key2 = TrackedReminder.makeKey("buy groceries")
        XCTAssertEqual(key1, key2)
    }

    func testMakeKeyEmpty() {
        XCTAssertEqual(TrackedReminder.makeKey(""), "")
    }

    // MARK: - Default values

    func testDefaultValues() {
        let reminder = TrackedReminder(originalName: "Test")
        XCTAssertFalse(reminder.tracked)
        XCTAssertFalse(reminder.dismissed)
        XCTAssertEqual(reminder.project, "")
        XCTAssertEqual(reminder.status, "pending")
        XCTAssertNil(reminder.completedDate)
        // firstSeen should default to today
        XCTAssertEqual(reminder.firstSeen, TrackedReminder.todayString())
    }
}
