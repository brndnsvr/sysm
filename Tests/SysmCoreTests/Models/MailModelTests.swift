import XCTest
@testable import SysmCore

final class MailModelTests: XCTestCase {

    // MARK: - MailError errorDescription

    func testMailErrorDescriptions() {
        XCTAssertNotNil(MailError.appleScriptError("test").errorDescription)
        XCTAssertNotNil(MailError.mailNotRunning.errorDescription)
        XCTAssertNotNil(MailError.messageNotFound("1").errorDescription)
        XCTAssertNotNil(MailError.mailboxNotFound("Inbox").errorDescription)
        XCTAssertNotNil(MailError.accountNotFound("Work").errorDescription)
        XCTAssertNotNil(MailError.sendFailed("reason").errorDescription)
        XCTAssertNotNil(MailError.invalidDateRange.errorDescription)
        XCTAssertNotNil(MailError.noRecipientsSpecified.errorDescription)
        XCTAssertNotNil(MailError.invalidOutputDirectory("/tmp").errorDescription)
    }

    func testMailErrorRecoverySuggestions() {
        // All cases should have recovery suggestions
        XCTAssertNotNil(MailError.appleScriptError("test").recoverySuggestion)
        XCTAssertNotNil(MailError.mailNotRunning.recoverySuggestion)
        XCTAssertNotNil(MailError.messageNotFound("1").recoverySuggestion)
        XCTAssertNotNil(MailError.mailboxNotFound("Inbox").recoverySuggestion)
        XCTAssertNotNil(MailError.accountNotFound("Work").recoverySuggestion)
        XCTAssertNotNil(MailError.sendFailed("reason").recoverySuggestion)
        XCTAssertNotNil(MailError.invalidDateRange.recoverySuggestion)
        XCTAssertNotNil(MailError.noRecipientsSpecified.recoverySuggestion)
        XCTAssertNotNil(MailError.invalidOutputDirectory("/tmp").recoverySuggestion)
    }

    // MARK: - MailMessage Codable

    func testMailMessageCodable() throws {
        let msg = MailMessage(id: "1", messageId: "msg-1", subject: "Hello", from: "a@b.com",
                              dateReceived: "Jan 15", isRead: true, accountName: "Work")
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(MailMessage.self, from: data)
        XCTAssertEqual(decoded.id, "1")
        XCTAssertEqual(decoded.subject, "Hello")
        XCTAssertTrue(decoded.isRead)
    }

    // MARK: - MailMessageDetail Codable

    func testMailMessageDetailCodable() throws {
        let detail = MailMessageDetail(
            id: "1", messageId: "msg-1", subject: "Test", from: "a@b.com",
            to: "c@d.com", cc: "e@f.com", bcc: nil, replyTo: nil,
            dateReceived: "Jan 15", dateSent: "Jan 14",
            content: "Body text", isRead: false, isFlagged: true,
            mailbox: "Inbox", accountName: "Work",
            attachments: [MailAttachment(name: "file.pdf", mimeType: "application/pdf", size: 1024)]
        )
        let data = try JSONEncoder().encode(detail)
        let decoded = try JSONDecoder().decode(MailMessageDetail.self, from: data)
        XCTAssertEqual(decoded.subject, "Test")
        XCTAssertEqual(decoded.cc, "e@f.com")
        XCTAssertNil(decoded.bcc)
        XCTAssertTrue(decoded.isFlagged)
        XCTAssertEqual(decoded.attachments.count, 1)
        XCTAssertEqual(decoded.attachments[0].name, "file.pdf")
    }

    // MARK: - MailMailbox Codable

    func testMailMailboxCodable() throws {
        let mailbox = MailMailbox(name: "Inbox", accountName: "Work", unreadCount: 5, messageCount: 100, fullPath: "Work/Inbox")
        let data = try JSONEncoder().encode(mailbox)
        let decoded = try JSONDecoder().decode(MailMailbox.self, from: data)
        XCTAssertEqual(decoded.name, "Inbox")
        XCTAssertEqual(decoded.unreadCount, 5)
        XCTAssertEqual(decoded.fullPath, "Work/Inbox")
    }

    // MARK: - MailAttachment Codable

    func testMailAttachmentCodable() throws {
        let attachment = MailAttachment(name: "report.xlsx", mimeType: "application/vnd.ms-excel", size: 50000)
        let data = try JSONEncoder().encode(attachment)
        let decoded = try JSONDecoder().decode(MailAttachment.self, from: data)
        XCTAssertEqual(decoded.name, "report.xlsx")
        XCTAssertEqual(decoded.size, 50000)
    }
}
