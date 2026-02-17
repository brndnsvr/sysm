import XCTest
@testable import SysmCore

final class MessagesServiceTests: XCTestCase {
    var mock: MockAppleScriptRunner!
    var service: MessagesService!

    override func setUp() {
        super.setUp()
        mock = MockAppleScriptRunner()
        ServiceContainer.shared.appleScriptRunnerFactory = { [mock] in mock! }
        ServiceContainer.shared.clearCache()
        service = MessagesService()
    }

    override func tearDown() {
        super.tearDown()
        ServiceContainer.shared.reset()
    }

    // MARK: - getRecentConversations()

    func testGetRecentConversationsParsesOutput() throws {
        mock.defaultResponse = "chat-1|||Family|||+1234567890, +0987654321###chat-2|||Work|||alice@work.com###"
        let conversations = try service.getRecentConversations(limit: 10)
        XCTAssertEqual(conversations.count, 2)
        XCTAssertEqual(conversations[0].id, "chat-1")
        XCTAssertEqual(conversations[0].name, "Family")
        XCTAssertEqual(conversations[0].participants, "+1234567890, +0987654321")
        XCTAssertEqual(conversations[1].name, "Work")
    }

    func testGetRecentConversationsEmpty() throws {
        mock.defaultResponse = ""
        let conversations = try service.getRecentConversations(limit: 10)
        XCTAssertTrue(conversations.isEmpty)
    }

    func testGetRecentConversationsMalformedSkipped() throws {
        mock.defaultResponse = "chat-1|||Family|||participants###bad###"
        let conversations = try service.getRecentConversations(limit: 10)
        XCTAssertEqual(conversations.count, 1)
    }

    // MARK: - getMessages()

    func testGetMessagesParsesOutput() throws {
        mock.defaultResponse = "Jan 15, 2024|||+1234567890|||Hello!###Jan 15, 2024|||+0987654321|||Hi there###"
        let messages = try service.getMessages(conversationId: "chat-1", limit: 10)
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0].sender, "+1234567890")
        XCTAssertEqual(messages[0].content, "Hello!")
        XCTAssertEqual(messages[1].content, "Hi there")
    }

    func testGetMessagesEmpty() throws {
        mock.defaultResponse = ""
        let messages = try service.getMessages(conversationId: "chat-1", limit: 10)
        XCTAssertTrue(messages.isEmpty)
    }

    // MARK: - sendMessage()

    func testSendMessageSuccess() throws {
        mock.defaultResponse = ""
        try service.sendMessage(to: "+1234567890", message: "Test message")
        XCTAssertFalse(mock.executedScripts.isEmpty)
    }

    // MARK: - Error mapping

    func testErrorMappingAppleScript() {
        mock.errorToThrow = AppleScriptError.executionFailed("Messages error")
        XCTAssertThrowsError(try service.getRecentConversations(limit: 10)) { error in
            guard case MessagesError.appleScriptError = error else {
                XCTFail("Expected appleScriptError, got \(error)")
                return
            }
        }
    }
}
