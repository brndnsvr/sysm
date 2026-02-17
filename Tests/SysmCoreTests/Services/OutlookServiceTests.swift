import XCTest
@testable import SysmCore

final class OutlookServiceTests: XCTestCase {
    var mock: MockAppleScriptRunner!
    var service: OutlookService!

    override func setUp() {
        super.setUp()
        mock = MockAppleScriptRunner()
        ServiceContainer.shared.appleScriptRunnerFactory = { [mock] in mock! }
        ServiceContainer.shared.clearCache()
        service = OutlookService()
    }

    override func tearDown() {
        super.tearDown()
        ServiceContainer.shared.reset()
    }

    // MARK: - getInbox()

    func testGetInboxParsesMultipleRecords() throws {
        mock.defaultResponse = "100|||Meeting Tomorrow|||alice@test.com|||Jan 15, 2024|||true###200|||Project Update|||bob@test.com|||Jan 14, 2024|||false###"
        let messages = try service.getInbox(limit: 10)
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].id, "100")
        XCTAssertEqual(messages[0].subject, "Meeting Tomorrow")
        XCTAssertEqual(messages[0].from, "alice@test.com")
        XCTAssertTrue(messages[0].isRead)
        XCTAssertEqual(messages[1].id, "200")
        XCTAssertFalse(messages[1].isRead)
    }

    func testGetInboxEmpty() throws {
        mock.defaultResponse = ""
        let messages = try service.getInbox(limit: 10)
        XCTAssertTrue(messages.isEmpty)
    }

    func testGetInboxMalformedSkipped() throws {
        mock.defaultResponse = "100|||Subject|||from@test.com|||Jan 15|||true###bad###"
        let messages = try service.getInbox(limit: 10)
        XCTAssertEqual(messages.count, 1)
    }

    // MARK: - getUnread()

    func testGetUnreadParsesOutput() throws {
        mock.defaultResponse = "300|||Urgent|||urgent@test.com|||Jan 15, 2024|||false###"
        let messages = try service.getUnread(limit: 5)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].subject, "Urgent")
        XCTAssertFalse(messages[0].isRead)
    }

    func testGetUnreadEmpty() throws {
        mock.defaultResponse = ""
        let messages = try service.getUnread(limit: 5)
        XCTAssertTrue(messages.isEmpty)
    }

    // MARK: - getCalendarEvents()

    func testGetCalendarEventsParsesOutput() throws {
        // Each record needs exactly 6 fields: id|||subject|||start|||end|||location|||isAllDay
        mock.defaultResponse = "1|||Team Standup|||Jan 15 10:00|||Jan 15 10:30|||Room A|||false###2|||Lunch|||Jan 15 12:00|||Jan 15 13:00||||||true###"
        let events = try service.getCalendarEvents(days: 7)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].id, "1")
        XCTAssertEqual(events[0].subject, "Team Standup")
        XCTAssertEqual(events[0].location, "Room A")
        XCTAssertFalse(events[0].isAllDay)
        XCTAssertNil(events[1].location) // empty location -> nil
        XCTAssertTrue(events[1].isAllDay)
    }

    func testGetCalendarEventsEmpty() throws {
        mock.defaultResponse = ""
        let events = try service.getCalendarEvents(days: 7)
        XCTAssertTrue(events.isEmpty)
    }

    // MARK: - getTasks()

    func testGetTasksParsesOutput() throws {
        mock.defaultResponse = "1|||Fix bug|||Jan 20, 2024|||high priority|||false###2|||Review PR||||||normal priority|||true###"
        let tasks = try service.getTasks(priority: nil)
        XCTAssertEqual(tasks.count, 2)
        XCTAssertEqual(tasks[0].name, "Fix bug")
        XCTAssertEqual(tasks[0].dueDate, "Jan 20, 2024")
        XCTAssertFalse(tasks[0].isComplete)
        XCTAssertNil(tasks[1].dueDate)
        XCTAssertTrue(tasks[1].isComplete)
    }

    func testGetTasksEmpty() throws {
        mock.defaultResponse = ""
        let tasks = try service.getTasks(priority: nil)
        XCTAssertTrue(tasks.isEmpty)
    }

    // MARK: - getMessage()

    func testGetMessageParsesDetail() throws {
        let fields = [
            "42",                // id
            "Test Subject",      // subject
            "alice@test.com",    // from
            "bob@test.com",      // to
            "cc@test.com",       // cc
            "Jan 15, 2024",      // date
            "Hello World",       // body
            "true",              // isRead
        ]
        mock.defaultResponse = fields.joined(separator: "|||FIELD|||")
        let detail = try service.getMessage(id: "42")
        XCTAssertNotNil(detail)
        XCTAssertEqual(detail?.subject, "Test Subject")
        XCTAssertEqual(detail?.from, "alice@test.com")
        XCTAssertEqual(detail?.to, "bob@test.com")
        XCTAssertEqual(detail?.cc, "cc@test.com")
        XCTAssertEqual(detail?.body, "Hello World")
        XCTAssertEqual(detail?.isRead, true)
    }

    func testGetMessageNoCc() throws {
        let fields = ["42", "Subject", "from@test.com", "to@test.com", "", "Jan 15", "Body", "false"]
        mock.defaultResponse = fields.joined(separator: "|||FIELD|||")
        let detail = try service.getMessage(id: "42")
        XCTAssertNil(detail?.cc)
        XCTAssertFalse(detail?.isRead ?? true)
    }

    func testGetMessageEmpty() throws {
        mock.defaultResponse = ""
        let detail = try service.getMessage(id: "42")
        XCTAssertNil(detail)
    }

    func testGetMessageNonNumericId() {
        XCTAssertThrowsError(try service.getMessage(id: "not-a-number")) { error in
            guard case OutlookError.messageNotFound = error else {
                XCTFail("Expected messageNotFound, got \(error)")
                return
            }
        }
    }

    // MARK: - send()

    func testSendEmptyRecipients() {
        XCTAssertThrowsError(try service.send(to: [], cc: [], subject: "Test", body: "Body")) { error in
            guard case OutlookError.noRecipientsSpecified = error else {
                XCTFail("Expected noRecipientsSpecified, got \(error)")
                return
            }
        }
    }

    func testSendSuccess() throws {
        mock.defaultResponse = "ok"
        try service.send(to: ["test@example.com"], cc: [], subject: "Test", body: "Body")
        XCTAssertFalse(mock.executedScripts.isEmpty)
    }

    // MARK: - Error mapping

    func testErrorMappingNotRunning() {
        mock.errorToThrow = AppleScriptError.executionFailed("not running")
        XCTAssertThrowsError(try service.getInbox(limit: 10)) { error in
            guard case OutlookError.outlookNotRunning = error else {
                XCTFail("Expected outlookNotRunning, got \(error)")
                return
            }
        }
    }

    func testErrorMappingGenericAppleScript() {
        mock.errorToThrow = AppleScriptError.executionFailed("some other error")
        XCTAssertThrowsError(try service.getInbox(limit: 10)) { error in
            guard case OutlookError.appleScriptError = error else {
                XCTFail("Expected appleScriptError, got \(error)")
                return
            }
        }
    }

    // MARK: - OutlookError descriptions

    func testOutlookErrorDescriptions() {
        XCTAssertNotNil(OutlookError.outlookNotRunning.errorDescription)
        XCTAssertNotNil(OutlookError.outlookNotInstalled.errorDescription)
        XCTAssertNotNil(OutlookError.appleScriptError("test").errorDescription)
        XCTAssertNotNil(OutlookError.messageNotFound("1").errorDescription)
        XCTAssertNotNil(OutlookError.sendFailed("test").errorDescription)
        XCTAssertNotNil(OutlookError.noRecipientsSpecified.errorDescription)
    }

    func testOutlookErrorRecoverySuggestions() {
        XCTAssertNotNil(OutlookError.outlookNotRunning.recoverySuggestion)
        XCTAssertNotNil(OutlookError.outlookNotInstalled.recoverySuggestion)
        XCTAssertNotNil(OutlookError.appleScriptError("test").recoverySuggestion)
    }

    // MARK: - Model Codable round-trips

    func testOutlookMessageCodable() throws {
        let msg = OutlookMessage(id: "1", subject: "Test", from: "a@b.com", dateReceived: "Jan 15", isRead: true, account: "Work")
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(OutlookMessage.self, from: data)
        XCTAssertEqual(decoded.id, "1")
        XCTAssertEqual(decoded.subject, "Test")
        XCTAssertEqual(decoded.account, "Work")
    }

    func testOutlookCalendarEventCodable() throws {
        let event = OutlookCalendarEvent(id: "1", subject: "Meeting", startTime: "10:00", endTime: "11:00", location: "Room A", isAllDay: false)
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(OutlookCalendarEvent.self, from: data)
        XCTAssertEqual(decoded.subject, "Meeting")
        XCTAssertEqual(decoded.location, "Room A")
    }

    func testOutlookTaskCodable() throws {
        let task = OutlookTask(id: "1", name: "Fix bug", dueDate: "Jan 20", priority: "high", isComplete: false)
        let data = try JSONEncoder().encode(task)
        let decoded = try JSONDecoder().decode(OutlookTask.self, from: data)
        XCTAssertEqual(decoded.name, "Fix bug")
        XCTAssertFalse(decoded.isComplete)
    }
}
