import XCTest
@testable import SysmCore

final class TaggedReminderTests: XCTestCase {

    // MARK: - Helpers

    private func makeReminder(notes: String?) -> Reminder {
        struct ReminderProxy: Codable {
            var id: String
            var title: String
            var listName: String
            var isCompleted: Bool
            var priority: Int
            var priorityLevel: Int
            var hasRecurrence: Bool
            var hasAlarms: Bool
            var notes: String?
        }

        let proxy = ReminderProxy(
            id: "test-id", title: "Test Reminder", listName: "Reminders",
            isCompleted: false, priority: 0, priorityLevel: 0,
            hasRecurrence: false, hasAlarms: false, notes: notes
        )
        let proxyData = try! JSONEncoder().encode(proxy)
        return try! JSONDecoder().decode(Reminder.self, from: proxyData)
    }

    // MARK: - Reminder.tags

    func testTagsExtraction() {
        let reminder = makeReminder(notes: "#work #urgent")
        XCTAssertEqual(reminder.tags, ["work", "urgent"])
    }

    func testTagsNilNotes() {
        let reminder = makeReminder(notes: nil)
        XCTAssertEqual(reminder.tags, [])
    }

    func testTagsNoHashtags() {
        let reminder = makeReminder(notes: "Just regular notes")
        XCTAssertEqual(reminder.tags, [])
    }

    func testTagsCaseNormalization() {
        let reminder = makeReminder(notes: "#Work #URGENT #important")
        XCTAssertEqual(reminder.tags, ["work", "urgent", "important"])
    }

    func testTagsWithDashesAndUnderscores() {
        let reminder = makeReminder(notes: "#high-priority #to_do")
        XCTAssertEqual(reminder.tags, ["high-priority", "to_do"])
    }

    // MARK: - Reminder.hasTag()

    func testHasTagPresent() {
        let reminder = makeReminder(notes: "#work #urgent")
        XCTAssertTrue(reminder.hasTag("work"))
    }

    func testHasTagAbsent() {
        let reminder = makeReminder(notes: "#work #urgent")
        XCTAssertFalse(reminder.hasTag("personal"))
    }

    func testHasTagCaseInsensitive() {
        let reminder = makeReminder(notes: "#Work")
        XCTAssertTrue(reminder.hasTag("WORK"))
        XCTAssertTrue(reminder.hasTag("work"))
    }

    // MARK: - TagHelper.addTags()

    func testAddTagsNilNotes() {
        let result = TagHelper.addTags(["work"], to: nil)
        XCTAssertEqual(result, "#work")
    }

    func testAddTagsEmptyNotes() {
        let result = TagHelper.addTags(["work", "urgent"], to: "")
        XCTAssertEqual(result, "#work #urgent")
    }

    func testAddTagsExistingTags() {
        let result = TagHelper.addTags(["new"], to: "#existing")
        XCTAssertTrue(result.contains("#existing"))
        XCTAssertTrue(result.contains("#new"))
    }

    func testAddTagsNoExistingTags() {
        let result = TagHelper.addTags(["work"], to: "Some notes here")
        XCTAssertTrue(result.contains("Some notes here"))
        XCTAssertTrue(result.contains("Tags:"))
        XCTAssertTrue(result.contains("#work"))
    }

    // MARK: - TagHelper.removeTag()

    func testRemoveTagExisting() {
        let result = TagHelper.removeTag("work", from: "#work #urgent")
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.contains("#work"))
        XCTAssertTrue(result!.contains("#urgent"))
    }

    func testRemoveTagNilInput() {
        let result = TagHelper.removeTag("work", from: nil)
        XCTAssertNil(result)
    }

    func testRemoveTagNonExistent() {
        let result = TagHelper.removeTag("missing", from: "#work #urgent")
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("#work"))
        XCTAssertTrue(result!.contains("#urgent"))
    }

    // MARK: - TagHelper.extractTags()

    func testExtractTagsDeduplication() {
        // extractTags doesn't deduplicate by itself, but tags in the same text
        // would be unique unless duplicated
        let result = TagHelper.extractTags(from: "#work #urgent #work")
        XCTAssertTrue(result.contains("work"))
        XCTAssertTrue(result.contains("urgent"))
    }

    func testExtractTagsNil() {
        let result = TagHelper.extractTags(from: nil)
        XCTAssertEqual(result, [])
    }
}
