import Foundation

/// Protocol defining messages service operations for accessing macOS Messages via AppleScript.
///
/// Implementations provide access to iMessage conversations and the ability to send messages.
public protocol MessagesServiceProtocol: Sendable {
    /// Sends a message to a recipient.
    /// - Parameters:
    ///   - recipient: Phone number or email address.
    ///   - message: Message text to send.
    func sendMessage(to recipient: String, message: String) throws

    /// Retrieves recent conversations.
    /// - Parameter limit: Maximum number of conversations to return.
    /// - Returns: Array of recent conversations.
    func getRecentConversations(limit: Int) throws -> [Conversation]

    /// Retrieves messages from a conversation.
    /// - Parameters:
    ///   - conversationId: The conversation identifier.
    ///   - limit: Maximum number of messages to return.
    /// - Returns: Array of messages in the conversation.
    func getMessages(conversationId: String, limit: Int) throws -> [Message]
}
