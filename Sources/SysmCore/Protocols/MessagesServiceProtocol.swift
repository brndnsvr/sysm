import Foundation

/// Protocol defining messages service operations for accessing macOS Messages via AppleScript.
///
/// This protocol provides access to iMessage and SMS conversations through the Messages app,
/// supporting message sending and conversation history retrieval. Operations use AppleScript
/// to interact with the Messages application.
///
/// ## Permission Requirements
///
/// Messages app integration uses AppleScript and may require:
/// - Automation permission for controlling Messages.app
/// - System Settings > Privacy & Security > Automation
/// - Messages.app must be running for operations
/// - Full Disk Access may be required for reading message history
///
/// ## Usage Example
///
/// ```swift
/// let service = MessagesService()
///
/// // Send a message
/// try service.sendMessage(
///     to: "+1234567890",
///     message: "Hello from sysm!"
/// )
///
/// // Get recent conversations
/// let conversations = try service.getRecentConversations(limit: 10)
/// for conv in conversations {
///     print("\(conv.participant): \(conv.lastMessage)")
/// }
///
/// // Get messages from a conversation
/// if let firstConv = conversations.first {
///     let messages = try service.getMessages(
///         conversationId: firstConv.id,
///         limit: 20
///     )
/// }
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// AppleScript operations are synchronous and blocking.
///
/// ## Error Handling
///
/// All methods can throw ``MessagesError`` variants:
/// - ``MessagesError/messagesNotRunning`` - Messages.app is not running
/// - ``MessagesError/conversationNotFound(_:)`` - Conversation not found by ID
/// - ``MessagesError/sendFailed(_:)`` - Message send operation failed
/// - ``MessagesError/scriptFailed(_:)`` - AppleScript execution failed
/// - ``MessagesError/invalidRecipient(_:)`` - Invalid phone number or email format
///
public protocol MessagesServiceProtocol: Sendable {
    // MARK: - Send Messages

    /// Sends a message to a recipient.
    ///
    /// Sends an iMessage or SMS to the specified recipient. The recipient can be a phone number
    /// (for SMS/iMessage) or email address (for iMessage only).
    ///
    /// - Parameters:
    ///   - recipient: Phone number (e.g., "+1234567890") or email address.
    ///   - message: Message text to send.
    /// - Throws:
    ///   - ``MessagesError/messagesNotRunning`` if Messages.app is not running.
    ///   - ``MessagesError/invalidRecipient(_:)`` if recipient format is invalid.
    ///   - ``MessagesError/sendFailed(_:)`` if send operation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Send via phone number
    /// try service.sendMessage(to: "+14155551234", message: "Meeting at 3pm")
    ///
    /// // Send via email (iMessage)
    /// try service.sendMessage(to: "friend@icloud.com", message: "How are you?")
    /// ```
    func sendMessage(to recipient: String, message: String) throws

    // MARK: - Conversation Queries

    /// Retrieves recent conversations.
    ///
    /// Returns the most recent conversations sorted by last message time (newest first).
    /// Includes both iMessage and SMS conversations.
    ///
    /// - Parameter limit: Maximum number of conversations to return.
    /// - Returns: Array of ``Conversation`` objects.
    /// - Throws: ``MessagesError/messagesNotRunning`` if Messages.app is not running.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let recent = try service.getRecentConversations(limit: 5)
    /// for conv in recent {
    ///     print("\(conv.participant): \(conv.messageCount) messages")
    /// }
    /// ```
    func getRecentConversations(limit: Int) throws -> [Conversation]

    /// Retrieves messages from a specific conversation.
    ///
    /// Returns messages from the specified conversation, sorted by time (newest first).
    ///
    /// - Parameters:
    ///   - conversationId: The conversation's unique identifier.
    ///   - limit: Maximum number of messages to return.
    /// - Returns: Array of ``Message`` objects from the conversation.
    /// - Throws:
    ///   - ``MessagesError/messagesNotRunning`` if Messages.app is not running.
    ///   - ``MessagesError/conversationNotFound(_:)`` if conversation doesn't exist.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let messages = try service.getMessages(conversationId: "ABC123", limit: 50)
    /// for msg in messages {
    ///     print("[\(msg.sender)] \(msg.text)")
    /// }
    /// ```
    func getMessages(conversationId: String, limit: Int) throws -> [Message]
}
