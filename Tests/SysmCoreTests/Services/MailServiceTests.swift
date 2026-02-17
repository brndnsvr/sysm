import XCTest
@testable import SysmCore

final class MailServiceTests: XCTestCase {
    var mock: MockAppleScriptRunner!
    var service: MailService!

    override func setUp() {
        super.setUp()
        mock = MockAppleScriptRunner()
        ServiceContainer.shared.appleScriptRunnerFactory = { [mock] in mock! }
        ServiceContainer.shared.clearCache()
        service = MailService()
    }

    override func tearDown() {
        super.tearDown()
        ServiceContainer.shared.reset()
    }

    // MARK: - getAccounts()

    func testGetAccountsParsesOutput() throws {
        mock.defaultResponse = "acc-1|||Work|||alice@work.com###acc-2|||Personal|||alice@home.com###"
        let accounts = try service.getAccounts()
        XCTAssertEqual(accounts.count, 2)
        XCTAssertEqual(accounts[0].id, "acc-1")
        XCTAssertEqual(accounts[0].name, "Work")
        XCTAssertEqual(accounts[0].email, "alice@work.com")
        XCTAssertEqual(accounts[1].name, "Personal")
    }

    func testGetAccountsEmpty() throws {
        mock.defaultResponse = ""
        let accounts = try service.getAccounts()
        XCTAssertTrue(accounts.isEmpty)
    }

    // MARK: - getInboxMessages()

    func testGetInboxMessagesParsesThreeRecords() throws {
        mock.defaultResponse = "1|||msg-id-1|||Subject 1|||alice@test.com|||Jan 15, 2024|||true|||Work###2|||msg-id-2|||Subject 2|||bob@test.com|||Jan 14, 2024|||false|||Work###3|||msg-id-3|||Subject 3|||charlie@test.com|||Jan 13, 2024|||true|||Personal###"
        let messages = try service.getInboxMessages()
        XCTAssertEqual(messages.count, 3)
        XCTAssertEqual(messages[0].id, "1")
        XCTAssertEqual(messages[0].subject, "Subject 1")
        XCTAssertEqual(messages[0].from, "alice@test.com")
        XCTAssertTrue(messages[0].isRead)
        XCTAssertFalse(messages[1].isRead)
    }

    func testGetInboxMessagesMalformedSkipped() throws {
        mock.defaultResponse = "1|||msg-id-1|||Subject|||alice@test.com|||Jan 15|||true|||Work###bad-record###"
        let messages = try service.getInboxMessages()
        XCTAssertEqual(messages.count, 1) // Malformed record skipped
    }

    func testGetInboxMessagesEmpty() throws {
        mock.defaultResponse = ""
        let messages = try service.getInboxMessages()
        XCTAssertTrue(messages.isEmpty)
    }

    // MARK: - getMessage()

    func testGetMessageParsesDetail() throws {
        let fields = [
            "Test Subject",    // 0: subject
            "alice@test.com",  // 1: from
            "bob@test.com",    // 2: to
            "Jan 15, 2024",    // 3: date
            "Hello World",     // 4: content
            "true",            // 5: isRead
            "false",           // 6: isFlagged
            "",                // 7: cc
            "",                // 8: replyTo
            "",                // 9: dateSent
            "Inbox",           // 10: mailbox
            "Work",            // 11: account
            "",                // 12: attachments
            "msg-id-1",        // 13: messageId
        ]
        mock.defaultResponse = fields.joined(separator: "|||FIELD|||")
        let detail = try service.getMessage(id: "12345")
        XCTAssertNotNil(detail)
        XCTAssertEqual(detail?.subject, "Test Subject")
        XCTAssertEqual(detail?.from, "alice@test.com")
        XCTAssertEqual(detail?.content, "Hello World")
        XCTAssertEqual(detail?.isRead, true)
        XCTAssertEqual(detail?.mailbox, "Inbox")
    }

    func testGetMessageWithAttachments() throws {
        let fields = [
            "Subject", "from@test.com", "to@test.com", "Jan 15",
            "Body", "true", "false", "", "", "", "Inbox", "Work",
            "report.pdf||ATT||application/pdf||ATT||1024||ATTLIST||image.png||ATT||image/png||ATT||2048||ATTLIST||",
            "msg-1",
        ]
        mock.defaultResponse = fields.joined(separator: "|||FIELD|||")
        let detail = try service.getMessage(id: "12345")
        XCTAssertEqual(detail?.attachments.count, 2)
        XCTAssertEqual(detail?.attachments[0].name, "report.pdf")
        XCTAssertEqual(detail?.attachments[0].mimeType, "application/pdf")
        XCTAssertEqual(detail?.attachments[0].size, 1024)
    }

    func testGetMessageMaxContentLength() throws {
        let longContent = String(repeating: "x", count: 1000)
        let fields = [
            "Subject", "from@test.com", "to@test.com", "Jan 15",
            longContent, "true", "false", "", "", "", "", "", "", "",
        ]
        mock.defaultResponse = fields.joined(separator: "|||FIELD|||")
        let detail = try service.getMessage(id: "12345", maxContentLength: 100)
        XCTAssertEqual(detail?.content.count, 100)
    }

    // MARK: - searchMessages()

    func testSearchInvalidDateRange() {
        let after = Date(timeIntervalSince1970: 1700000000)
        let before = Date(timeIntervalSince1970: 1600000000)
        XCTAssertThrowsError(try service.searchMessages(afterDate: after, beforeDate: before)) { error in
            guard case MailError.invalidDateRange = error else {
                XCTFail("Expected invalidDateRange")
                return
            }
        }
    }

    // MARK: - sendMessage()

    func testSendMessageEmptyTo() {
        XCTAssertThrowsError(try service.sendMessage(to: "", subject: "Test", body: "Body")) { error in
            guard case MailError.noRecipientsSpecified = error else {
                XCTFail("Expected noRecipientsSpecified")
                return
            }
        }
    }

    func testSendMessageSuccess() throws {
        mock.defaultResponse = "ok"
        // Should not throw
        try service.sendMessage(to: "test@example.com", subject: "Test", body: "Body")
        XCTAssertFalse(mock.executedScripts.isEmpty)
    }

    // MARK: - Error Mapping

    func testErrorMappingNotRunning() {
        mock.errorToThrow = AppleScriptError.executionFailed("Mail is not running")
        XCTAssertThrowsError(try service.getAccounts()) { error in
            guard case MailError.mailNotRunning = error else {
                XCTFail("Expected mailNotRunning, got \(error)")
                return
            }
        }
    }

    func testErrorMappingGenericAppleScript() {
        mock.errorToThrow = AppleScriptError.executionFailed("some other error")
        XCTAssertThrowsError(try service.getAccounts()) { error in
            guard case MailError.appleScriptError = error else {
                XCTFail("Expected appleScriptError, got \(error)")
                return
            }
        }
    }

    // MARK: - sanitizedId

    func testNonNumericIdThrowsMessageNotFound() {
        XCTAssertThrowsError(try service.getMessage(id: "not-a-number")) { error in
            guard case MailError.messageNotFound = error else {
                XCTFail("Expected messageNotFound")
                return
            }
        }
    }

    // MARK: - markMessage / flagMessage error paths

    func testMarkMessageErrorPath() {
        mock.defaultResponse = "error:not found"
        XCTAssertThrowsError(try service.markMessage(id: "12345", read: true)) { error in
            guard case MailError.messageNotFound = error else {
                XCTFail("Expected messageNotFound")
                return
            }
        }
    }

    func testFlagMessageErrorPath() {
        mock.defaultResponse = "error:not found"
        XCTAssertThrowsError(try service.flagMessage(id: "12345", flagged: true)) { error in
            guard case MailError.messageNotFound = error else {
                XCTFail("Expected messageNotFound")
                return
            }
        }
    }
}
