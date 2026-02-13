import Foundation

/// Protocol defining mail service operations for accessing and managing macOS Mail via AppleScript.
///
/// This protocol provides comprehensive access to the user's email through the Mail app,
/// supporting account management, inbox queries, message search, draft creation, send operations,
/// attachment handling, and reply/forward functionality. Operations use AppleScript to interact
/// with the Mail application.
///
/// ## Permission Requirements
///
/// Mail app integration uses AppleScript and may require:
/// - Automation permission for controlling Mail.app
/// - System Settings > Privacy & Security > Automation
/// - Mail.app must be running for most operations
///
/// ## Usage Example
///
/// ```swift
/// let service = MailService()
///
/// // Get unread messages
/// let unread = try service.getUnreadMessages(accountName: nil, limit: 10)
/// for message in unread {
///     print("\(message.sender): \(message.subject)")
/// }
///
/// // Send an email
/// try service.sendMessage(
///     to: "colleague@example.com",
///     cc: nil,
///     bcc: nil,
///     subject: "Project Update",
///     body: "The project is on track.",
///     isHTML: false,
///     accountName: nil
/// )
///
/// // Reply to a message
/// let replyId = try service.reply(
///     messageId: message.id,
///     body: "Thanks for the update!",
///     replyAll: false,
///     send: true
/// )
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// AppleScript operations are synchronous and blocking.
///
/// ## Error Handling
///
/// All methods can throw ``MailError`` variants:
/// - ``MailError/mailNotRunning`` - Mail.app is not running
/// - ``MailError/accountNotFound(_:)`` - Specified account doesn't exist
/// - ``MailError/messageNotFound(_:)`` - Message not found by ID
/// - ``MailError/mailboxNotFound(_:)`` - Mailbox not found
/// - ``MailError/sendFailed(_:)`` - Email send operation failed
/// - ``MailError/scriptFailed(_:)`` - AppleScript execution failed
/// - ``MailError/invalidMessageId(_:)`` - Invalid message ID format
/// - ``MailError/attachmentNotFound(_:)`` - Attachment file not found
///
public protocol MailServiceProtocol: Sendable {
    // MARK: - Account Management

    /// Retrieves all configured mail accounts.
    ///
    /// Returns account information including names and email addresses for all accounts
    /// configured in Mail.app.
    ///
    /// - Returns: Array of ``MailAccount`` objects.
    /// - Throws: ``MailError/mailNotRunning`` if Mail.app is not running.
    func getAccounts() throws -> [MailAccount]

    // MARK: - Message Queries

    /// Retrieves recent inbox messages.
    ///
    /// Returns messages from the inbox, optionally filtered by account. Messages are sorted
    /// by date received (newest first).
    ///
    /// - Parameters:
    ///   - accountName: Optional account name to filter messages. If nil, returns from all accounts.
    ///   - limit: Maximum number of messages to return.
    /// - Returns: Array of ``MailMessage`` objects.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/accountNotFound(_:)`` if specified account doesn't exist.
    func getInboxMessages(accountName: String?, limit: Int) throws -> [MailMessage]

    /// Retrieves unread messages.
    ///
    /// Returns only unread messages, optionally filtered by account. Messages are sorted
    /// by date received (newest first).
    ///
    /// - Parameters:
    ///   - accountName: Optional account name to filter messages. If nil, returns from all accounts.
    ///   - limit: Maximum number of messages to return.
    /// - Returns: Array of unread ``MailMessage`` objects.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/accountNotFound(_:)`` if specified account doesn't exist.
    func getUnreadMessages(accountName: String?, limit: Int) throws -> [MailMessage]

    /// Retrieves a specific message by ID with full details.
    ///
    /// Returns complete message information including full body content. Content can be
    /// optionally truncated for large messages.
    ///
    /// - Parameters:
    ///   - id: The message's unique identifier.
    ///   - maxContentLength: Maximum content length in characters. Use nil for full content.
    /// - Returns: ``MailMessageDetail`` object if found, nil if message doesn't exist.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/invalidMessageId(_:)`` if message ID format is invalid.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Get full message content
    /// if let detail = try service.getMessage(id: "12345", maxContentLength: nil) {
    ///     print("From: \(detail.sender)")
    ///     print("Subject: \(detail.subject)")
    ///     print("Body: \(detail.content)")
    /// }
    /// ```
    func getMessage(id: String, maxContentLength: Int?) throws -> MailMessageDetail?

    // MARK: - Draft Creation

    /// Creates a new draft message.
    ///
    /// Creates a draft message in Mail.app that can be edited and sent later.
    /// Opens the compose window with the specified fields populated.
    ///
    /// - Parameters:
    ///   - to: Optional recipient email address.
    ///   - subject: Optional email subject line.
    ///   - body: Optional email body content.
    /// - Throws: ``MailError/mailNotRunning`` if Mail.app is not running.
    func createDraft(to: String?, subject: String?, body: String?) throws

    // MARK: - Message Management

    /// Marks a message as read or unread.
    ///
    /// Changes the read/unread status of a message.
    ///
    /// - Parameters:
    ///   - id: The message's unique identifier.
    ///   - read: `true` to mark as read, `false` to mark as unread.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/messageNotFound(_:)`` if message doesn't exist.
    func markMessage(id: String, read: Bool) throws

    /// Deletes a message.
    ///
    /// Moves the message to the Trash mailbox.
    ///
    /// - Parameter id: The message's unique identifier.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/messageNotFound(_:)`` if message doesn't exist.
    func deleteMessage(id: String) throws

    /// Flags or unflags a message.
    ///
    /// Sets or removes the flagged status on a message for follow-up tracking.
    ///
    /// - Parameters:
    ///   - id: The message's unique identifier.
    ///   - flagged: `true` to flag the message, `false` to unflag.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/messageNotFound(_:)`` if message doesn't exist.
    func flagMessage(id: String, flagged: Bool) throws

    /// Moves a message to a different mailbox.
    ///
    /// Transfers the message to the specified mailbox within an account.
    ///
    /// - Parameters:
    ///   - id: The message's unique identifier.
    ///   - toMailbox: Target mailbox name (e.g., "Archive", "Work Projects").
    ///   - accountName: Optional account name containing the target mailbox.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/messageNotFound(_:)`` if message doesn't exist.
    ///   - ``MailError/mailboxNotFound(_:)`` if target mailbox doesn't exist.
    func moveMessage(id: String, toMailbox: String, accountName: String?) throws

    // MARK: - Mailbox Operations

    /// Retrieves all mailboxes.
    ///
    /// Returns all mailboxes (folders) optionally filtered by account. Includes system
    /// mailboxes (Inbox, Sent, Trash) and user-created mailboxes.
    ///
    /// - Parameter accountName: Optional account name to filter mailboxes.
    /// - Returns: Array of ``MailMailbox`` objects.
    /// - Throws: ``MailError/mailNotRunning`` if Mail.app is not running.
    func getMailboxes(accountName: String?) throws -> [MailMailbox]

    // MARK: - Enhanced Search

    /// Searches messages with advanced filtering options.
    ///
    /// Performs multi-criteria search across messages. All non-nil parameters are combined
    /// with AND logic. Supports searching in subject, sender, body, and date ranges.
    ///
    /// - Parameters:
    ///   - accountName: Optional account name to filter messages.
    ///   - query: Optional search query for subject and sender fields.
    ///   - bodyQuery: Optional search query for message body content.
    ///   - afterDate: Optional filter for messages received after this date.
    ///   - beforeDate: Optional filter for messages received before this date.
    ///   - limit: Maximum number of results to return.
    /// - Returns: Array of matching ``MailMessage`` objects.
    /// - Throws: ``MailError/mailNotRunning`` if Mail.app is not running.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Find messages about "project" in the last week
    /// let weekAgo = Date().addingTimeInterval(-7*24*3600)
    /// let results = try service.searchMessages(
    ///     accountName: nil,
    ///     query: "project",
    ///     bodyQuery: nil,
    ///     afterDate: weekAgo,
    ///     beforeDate: nil,
    ///     limit: 50
    /// )
    /// ```
    func searchMessages(
        accountName: String?,
        query: String?,
        bodyQuery: String?,
        afterDate: Date?,
        beforeDate: Date?,
        limit: Int
    ) throws -> [MailMessage]

    // MARK: - Send Mail

    /// Sends an email message.
    ///
    /// Creates and sends a new email immediately. Supports both plain text and HTML formatting.
    ///
    /// - Parameters:
    ///   - to: Recipient email address (required).
    ///   - cc: Optional CC recipient email address.
    ///   - bcc: Optional BCC recipient email address.
    ///   - subject: Email subject line.
    ///   - body: Email body content.
    ///   - isHTML: `true` if body contains HTML, `false` for plain text.
    ///   - accountName: Optional account to send from. Uses default account if nil.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/sendFailed(_:)`` if send operation failed.
    ///   - ``MailError/accountNotFound(_:)`` if specified account doesn't exist.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try service.sendMessage(
    ///     to: "team@example.com",
    ///     cc: "manager@example.com",
    ///     bcc: nil,
    ///     subject: "Weekly Report",
    ///     body: "<h1>Report</h1><p>All tasks completed.</p>",
    ///     isHTML: true,
    ///     accountName: "Work"
    /// )
    /// ```
    func sendMessage(
        to: String,
        cc: String?,
        bcc: String?,
        subject: String,
        body: String,
        isHTML: Bool,
        accountName: String?
    ) throws

    // MARK: - Attachments

    /// Downloads all attachments from a message.
    ///
    /// Extracts and saves all attachments from the specified message to a directory.
    /// Files are saved with their original names.
    ///
    /// - Parameters:
    ///   - messageId: The message's unique identifier.
    ///   - outputDir: Directory path to save attachments (must exist).
    /// - Returns: Array of file paths for downloaded attachments.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/messageNotFound(_:)`` if message doesn't exist.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let files = try service.downloadAttachments(
    ///     messageId: "12345",
    ///     outputDir: "/tmp/attachments"
    /// )
    /// print("Downloaded \(files.count) files")
    /// ```
    func downloadAttachments(messageId: String, outputDir: String) throws -> [String]

    // MARK: - Reply & Forward

    /// Replies to a message.
    ///
    /// Creates a reply message with quoted original content. Can reply to sender only or
    /// reply all. Optionally sends immediately or saves as draft.
    ///
    /// - Parameters:
    ///   - messageId: The message's unique identifier to reply to.
    ///   - body: Reply body text (added before quoted original).
    ///   - replyAll: `true` to reply to all recipients, `false` to reply only to sender.
    ///   - send: `true` to send immediately, `false` to save as draft.
    /// - Returns: The new reply message's unique identifier.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/messageNotFound(_:)`` if original message doesn't exist.
    ///   - ``MailError/sendFailed(_:)`` if send is true and send operation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let replyId = try service.reply(
    ///     messageId: "12345",
    ///     body: "Thanks for the information!",
    ///     replyAll: false,
    ///     send: true
    /// )
    /// ```
    func reply(messageId: String, body: String, replyAll: Bool, send: Bool) throws -> String

    /// Forwards a message.
    ///
    /// Creates a forward message with the original content. Optionally sends immediately
    /// or saves as draft.
    ///
    /// - Parameters:
    ///   - messageId: The message's unique identifier to forward.
    ///   - to: Recipient email address for the forwarded message.
    ///   - body: Forward body text (added before original content).
    ///   - send: `true` to send immediately, `false` to save as draft.
    /// - Returns: The new forward message's unique identifier.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/messageNotFound(_:)`` if original message doesn't exist.
    ///   - ``MailError/sendFailed(_:)`` if send is true and send operation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let forwardId = try service.forward(
    ///     messageId: "12345",
    ///     to: "colleague@example.com",
    ///     body: "FYI - see below",
    ///     send: true
    /// )
    /// ```
    func forward(messageId: String, to: String, body: String, send: Bool) throws -> String

    // MARK: - Drafts Management

    /// Lists all draft messages.
    ///
    /// Returns all messages currently in the Drafts mailbox across all accounts.
    ///
    /// - Returns: Array of draft ``MailMessage`` objects.
    /// - Throws: ``MailError/mailNotRunning`` if Mail.app is not running.
    func listDrafts() throws -> [MailMessage]

    /// Deletes a draft message.
    ///
    /// Permanently deletes a draft message. The message must be in the Drafts mailbox.
    ///
    /// - Parameter messageId: The draft message's unique identifier.
    /// - Throws:
    ///   - ``MailError/mailNotRunning`` if Mail.app is not running.
    ///   - ``MailError/messageNotFound(_:)`` if draft doesn't exist.
    func deleteDraft(messageId: String) throws
}

extension MailServiceProtocol {
    /// Convenience method to get a message with full content.
    ///
    /// Calls ``getMessage(id:maxContentLength:)`` with nil maxContentLength.
    ///
    /// - Parameter id: The message's unique identifier.
    /// - Returns: ``MailMessageDetail`` object if found, nil otherwise.
    /// - Throws: Same errors as ``getMessage(id:maxContentLength:)``.
    public func getMessage(id: String) throws -> MailMessageDetail? {
        try getMessage(id: id, maxContentLength: nil)
    }
}
