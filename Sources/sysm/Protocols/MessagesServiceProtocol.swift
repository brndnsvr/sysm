import Foundation

/// Protocol for messages service operations
protocol MessagesServiceProtocol {
    func sendMessage(to recipient: String, message: String) throws
    func getRecentConversations(limit: Int) throws -> [Conversation]
    func getMessages(conversationId: String, limit: Int) throws -> [Message]
}
