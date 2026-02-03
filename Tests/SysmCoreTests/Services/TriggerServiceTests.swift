import XCTest
@testable import SysmCore

final class TriggerServiceTests: XCTestCase {

    var tempDir: URL!
    var triggerFile: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TriggerServiceTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        triggerFile = tempDir.appendingPathComponent("TRIGGER.md")
    }

    override func tearDown() {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        tempDir = nil
        triggerFile = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_DefaultPath() {
        let service = TriggerService()
        // Should initialize without crashing
        // Cannot test exact path without mocking FileManager
        XCTAssertNotNil(service)
    }

    func testInit_EnvironmentVariable() {
        // Set environment variable temporarily
        let testPath = "/tmp/test-trigger.md"
        setenv("SYSM_TRIGGER_PATH", testPath, 1)
        defer { unsetenv("SYSM_TRIGGER_PATH") }

        let service = TriggerService()
        XCTAssertNotNil(service)
    }

    func testInit_CustomRelativePath() {
        let service = TriggerService(relativePath: "custom/path/TRIGGER.md")
        XCTAssertNotNil(service)
    }

    // MARK: - syncTrackedReminders Tests

    func testSyncTrackedReminders_FileDoesNotExist() throws {
        // Use environment variable to point to non-existent file
        setenv("SYSM_TRIGGER_PATH", "/tmp/nonexistent-\(UUID().uuidString).md", 1)
        defer { unsetenv("SYSM_TRIGGER_PATH") }

        let service = TriggerService()
        let tracked: [(key: String, reminder: TrackedReminder)] = [
            ("test", TrackedReminder(originalName: "Test Task", firstSeen: "2025-02-02"))
        ]

        // Should not throw when file doesn't exist
        try service.syncTrackedReminders(tracked)
    }

    func testSyncTrackedReminders_EmptyTrackedList() throws {
        // Create a basic trigger file
        let content = """
        # Daily Trigger

        ## 📅 Upcoming Deadlines
        Some content here.
        """
        try content.write(to: triggerFile, atomically: true, encoding: .utf8)

        setenv("SYSM_TRIGGER_PATH", triggerFile.path, 1)
        defer { unsetenv("SYSM_TRIGGER_PATH") }

        let service = TriggerService()
        try service.syncTrackedReminders([])

        let result = try String(contentsOf: triggerFile, encoding: .utf8)
        XCTAssertTrue(result.contains("## 📌 Tracked Reminders"))
        XCTAssertTrue(result.contains("No active tracked reminders."))
    }

    func testSyncTrackedReminders_AddNewSection() throws {
        // Create trigger file without tracked reminders section
        let content = """
        # Daily Trigger

        ## 📅 Upcoming Deadlines
        Some content here.
        """
        try content.write(to: triggerFile, atomically: true, encoding: .utf8)

        setenv("SYSM_TRIGGER_PATH", triggerFile.path, 1)
        defer { unsetenv("SYSM_TRIGGER_PATH") }

        let service = TriggerService()
        let tracked: [(key: String, reminder: TrackedReminder)] = [
            ("task1", TrackedReminder(
                originalName: "Test Task",
                firstSeen: "2025-02-02",
                tracked: true,
                project: "TestProject",
                status: "pending"
            ))
        ]

        try service.syncTrackedReminders(tracked)

        let result = try String(contentsOf: triggerFile, encoding: .utf8)
        XCTAssertTrue(result.contains("## 📌 Tracked Reminders"))
        XCTAssertTrue(result.contains("Test Task"))
        XCTAssertTrue(result.contains("TestProject"))
        XCTAssertTrue(result.contains("Pending"))
    }

    func testSyncTrackedReminders_UpdateExistingSection() throws {
        // Create trigger file with existing tracked reminders section
        let content = """
        # Daily Trigger

        ## 📌 Tracked Reminders
        | Reminder | Added | Project | Status |
        |----------|-------|---------|--------|
        | Old Task | 2025-01-01 | OldProject | Pending |

        ## 📅 Upcoming Deadlines
        Some content here.
        """
        try content.write(to: triggerFile, atomically: true, encoding: .utf8)

        setenv("SYSM_TRIGGER_PATH", triggerFile.path, 1)
        defer { unsetenv("SYSM_TRIGGER_PATH") }

        let service = TriggerService()
        let tracked: [(key: String, reminder: TrackedReminder)] = [
            ("task1", TrackedReminder(
                originalName: "New Task",
                firstSeen: "2025-02-02",
                project: "NewProject",
                status: "pending"
            ))
        ]

        try service.syncTrackedReminders(tracked)

        let result = try String(contentsOf: triggerFile, encoding: .utf8)
        XCTAssertTrue(result.contains("## 📌 Tracked Reminders"))
        XCTAssertTrue(result.contains("New Task"))
        XCTAssertTrue(result.contains("NewProject"))
        XCTAssertFalse(result.contains("Old Task"))
    }

    func testSyncTrackedReminders_FiltersDoneStatus() throws {
        let content = """
        # Daily Trigger

        ## 📅 Upcoming Deadlines
        Some content here.
        """
        try content.write(to: triggerFile, atomically: true, encoding: .utf8)

        setenv("SYSM_TRIGGER_PATH", triggerFile.path, 1)
        defer { unsetenv("SYSM_TRIGGER_PATH") }

        let service = TriggerService()
        let tracked: [(key: String, reminder: TrackedReminder)] = [
            ("task1", TrackedReminder(
                originalName: "Active Task",
                firstSeen: "2025-02-02",
                status: "pending"
            )),
            ("task2", TrackedReminder(
                originalName: "Done Task",
                firstSeen: "2025-02-01",
                status: "done"
            ))
        ]

        try service.syncTrackedReminders(tracked)

        let result = try String(contentsOf: triggerFile, encoding: .utf8)
        XCTAssertTrue(result.contains("Active Task"))
        XCTAssertFalse(result.contains("Done Task"))
    }

    func testSyncTrackedReminders_EmptyProject() throws {
        let content = """
        # Daily Trigger
        """
        try content.write(to: triggerFile, atomically: true, encoding: .utf8)

        setenv("SYSM_TRIGGER_PATH", triggerFile.path, 1)
        defer { unsetenv("SYSM_TRIGGER_PATH") }

        let service = TriggerService()
        let tracked: [(key: String, reminder: TrackedReminder)] = [
            ("task1", TrackedReminder(
                originalName: "Task Without Project",
                firstSeen: "2025-02-02",
                project: "",
                status: "pending"
            ))
        ]

        try service.syncTrackedReminders(tracked)

        let result = try String(contentsOf: triggerFile, encoding: .utf8)
        XCTAssertTrue(result.contains("Task Without Project"))
        XCTAssertTrue(result.contains("| -"))
    }
}
