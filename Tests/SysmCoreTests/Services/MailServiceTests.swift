//
//  MailServiceTests.swift
//  sysm
//

import XCTest
@testable import SysmCore

final class MailServiceTests: XCTestCase {
    var mockRunner: MockAppleScriptRunner!
    var service: MailService!

    override func setUp() {
        super.setUp()
        mockRunner = MockAppleScriptRunner()
        service = MailService(scriptRunner: mockRunner)
    }

    override func tearDown() {
        mockRunner = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Account Tests

    func testGetAccountsSuccess() throws {
        mockRunner.mockResponses["mail-accounts"] = "Work|||Personal|||iCloud"

        let accounts = try service.getAccounts()

        XCTAssertEqual(accounts.count, 3)
        XCTAssertEqual(accounts[0].name, "Work")
        XCTAssertEqual(accounts[1].name, "Personal")
        XCTAssertEqual(accounts[2].name, "iCloud")
        XCTAssertTrue(mockRunner.lastScript!.contains("tell application \"Mail\""))
    }

    func testGetAccountsEmpty() throws {
        mockRunner.mockResponses["mail-accounts"] = ""

        let accounts = try service.getAccounts()

        XCTAssertEqual(accounts.count, 0)
    }

    // MARK: - Inbox Tests

    func testGetInboxMessagesWithLimit() throws {
        let mockOutput = """
        msg-1|||Subject One|||sender@example.com|||recipient@example.com|||2024-01-15 14:30:00|||false|||false|||Inbox|||false|||
        msg-2|||Subject Two|||sender2@example.com|||recipient@example.com|||2024-01-14 10:00:00|||true|||false|||Inbox|||true|||attachment.pdf
        """
        mockRunner.mockResponses["mail-inbox"] = mockOutput

        let messages = try service.getInboxMessages(accountName: nil, limit: 10)

        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].id, "msg-1")
        XCTAssertEqual(messages[0].subject, "Subject One")
        XCTAssertEqual(messages[0].sender, "sender@example.com")
        XCTAssertFalse(messages[0].isRead)
        XCTAssertFalse(messages[0].hasAttachments)

        XCTAssertEqual(messages[1].id, "msg-2")
        XCTAssertTrue(messages[1].isRead)
        XCTAssertTrue(messages[1].hasAttachments)
    }

    func testGetInboxMessagesWithAccount() throws {
        mockRunner.mockResponses["mail-inbox"] = "msg-1|||Test|||sender@example.com|||recipient@example.com|||2024-01-15 14:30:00|||false|||false|||Inbox|||false|||"

        _ = try service.getInboxMessages(accountName: "Work", limit: 10)

        XCTAssertTrue(mockRunner.lastScript!.contains("Work"))
    }

    // MARK: - Unread Messages Tests

    func testGetUnreadMessages() throws {
        let mockOutput = """
        msg-1|||Unread One|||sender@example.com|||recipient@example.com|||2024-01-15 14:30:00|||false|||false|||Inbox|||false|||
        """
        mockRunner.mockResponses["mail-unread"] = mockOutput

        let messages = try service.getUnreadMessages(accountName: nil, limit: 5)

        XCTAssertEqual(messages.count, 1)
        XCTAssertFalse(messages[0].isRead)
    }

    // MARK: - Search Tests

    func testSearchMessages() throws {
        mockRunner.mockResponses["mail-search"] = "msg-1|||Found Message|||sender@example.com|||recipient@example.com|||2024-01-15 14:30:00|||false|||false|||Inbox|||false|||"

        let messages = try service.searchMessages(
            accountName: nil,
            query: "important",
            bodyQuery: nil,
            afterDate: nil,
            beforeDate: nil,
            limit: 10
        )

        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(mockRunner.lastScript!.contains("important"))
    }

    // MARK: - Message Operations Tests

    func testMarkMessageAsRead() throws {
        mockRunner.mockResponses["mail-mark"] = "success"

        XCTAssertNoThrow(try service.markMessage(id: "msg-1", read: true))
        XCTAssertTrue(mockRunner.lastScript!.contains("msg-1"))
        XCTAssertTrue(mockRunner.lastScript!.contains("read status"))
    }

    func testFlagMessage() throws {
        mockRunner.mockResponses["mail-flag"] = "success"

        XCTAssertNoThrow(try service.flagMessage(id: "msg-1", flagged: true))
        XCTAssertTrue(mockRunner.lastScript!.contains("msg-1"))
        XCTAssertTrue(mockRunner.lastScript!.contains("flagged"))
    }

    func testDeleteMessage() throws {
        mockRunner.mockResponses["mail-delete"] = "success"

        XCTAssertNoThrow(try service.deleteMessage(id: "msg-1"))
        XCTAssertTrue(mockRunner.lastScript!.contains("msg-1"))
        XCTAssertTrue(mockRunner.lastScript!.contains("delete"))
    }

    // MARK: - Draft Tests

    func testCreateDraft() throws {
        mockRunner.mockResponses["mail-create-draft"] = "success"

        XCTAssertNoThrow(
            try service.createDraft(
                to: "recipient@example.com",
                subject: "Test Subject",
                body: "Test Body"
            )
        )

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("recipient@example.com"))
        XCTAssertTrue(script.contains("Test Subject"))
        XCTAssertTrue(script.contains("Test Body"))
    }

    // MARK: - Send Mail Tests

    func testSendMessage() throws {
        mockRunner.mockResponses["mail-send"] = "success"

        XCTAssertNoThrow(
            try service.sendMessage(
                to: "recipient@example.com",
                cc: nil,
                bcc: nil,
                subject: "Test",
                body: "Message body",
                isHTML: false,
                accountName: nil
            )
        )

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("recipient@example.com"))
        XCTAssertTrue(script.contains("Test"))
        XCTAssertTrue(script.contains("send"))
    }

    // MARK: - Error Tests

    func testAppleScriptError() {
        enum TestError: Error {
            case scriptFailed
        }
        mockRunner.mockErrors["mail-inbox"] = TestError.scriptFailed

        XCTAssertThrowsError(try service.getInboxMessages(accountName: nil, limit: 10))
    }

    // MARK: - Escaping Tests

    func testInputEscaping() throws {
        mockRunner.mockResponses["mail-search"] = ""

        _ = try service.searchMessages(
            accountName: nil,
            query: "test's \"quoted\" text",
            bodyQuery: nil,
            afterDate: nil,
            beforeDate: nil,
            limit: 10
        )

        // Verify escaping was applied
        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("\\"))
    }
}
