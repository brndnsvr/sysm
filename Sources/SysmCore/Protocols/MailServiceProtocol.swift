import Foundation

/// Protocol defining mail service operations for accessing macOS Mail via AppleScript.
///
/// Implementations provide read access to the user's email accounts and messages,
/// supporting inbox queries, search, draft creation, and message management.
public protocol MailServiceProtocol: Sendable {
    /// Retrieves all configured mail accounts.
    /// - Returns: Array of mail accounts.
    func getAccounts() throws -> [MailAccount]

    /// Retrieves recent inbox messages.
    /// - Parameters:
    ///   - accountName: Optional account name to filter messages.
    ///   - limit: Maximum number of messages to return.
    /// - Returns: Array of inbox messages.
    func getInboxMessages(accountName: String?, limit: Int) throws -> [MailMessage]

    /// Retrieves unread messages.
    /// - Parameters:
    ///   - accountName: Optional account name to filter messages.
    ///   - limit: Maximum number of messages to return.
    /// - Returns: Array of unread messages.
    func getUnreadMessages(accountName: String?, limit: Int) throws -> [MailMessage]

    /// Retrieves a specific message by ID with optional content truncation.
    /// - Parameters:
    ///   - id: The message ID.
    ///   - maxContentLength: Maximum content length in characters, nil for full content.
    /// - Returns: The message detail if found, nil otherwise.
    func getMessage(id: String, maxContentLength: Int?) throws -> MailMessageDetail?

    /// Creates a new draft message.
    /// - Parameters:
    ///   - to: Optional recipient email.
    ///   - subject: Optional email subject.
    ///   - body: Optional email body.
    func createDraft(to: String?, subject: String?, body: String?) throws

    // MARK: - Message Management

    /// Marks a message as read or unread.
    /// - Parameters:
    ///   - id: The message ID.
    ///   - read: True to mark as read, false to mark as unread.
    func markMessage(id: String, read: Bool) throws

    /// Deletes a message.
    /// - Parameter id: The message ID.
    func deleteMessage(id: String) throws

    /// Flags or unflags a message.
    /// - Parameters:
    ///   - id: The message ID.
    ///   - flagged: True to flag, false to unflag.
    func flagMessage(id: String, flagged: Bool) throws

    /// Moves a message to a different mailbox.
    /// - Parameters:
    ///   - id: The message ID.
    ///   - toMailbox: The target mailbox name.
    ///   - accountName: Optional account name for the target mailbox.
    func moveMessage(id: String, toMailbox: String, accountName: String?) throws

    // MARK: - Mailbox Operations

    /// Retrieves all mailboxes.
    /// - Parameter accountName: Optional account name to filter mailboxes.
    /// - Returns: Array of mailboxes.
    func getMailboxes(accountName: String?) throws -> [MailMailbox]

    // MARK: - Enhanced Search

    /// Searches messages with advanced filtering options.
    /// - Parameters:
    ///   - accountName: Optional account name to filter messages.
    ///   - query: Optional search query for subject/sender.
    ///   - bodyQuery: Optional search query for message body.
    ///   - afterDate: Optional filter for messages after this date.
    ///   - beforeDate: Optional filter for messages before this date.
    ///   - limit: Maximum number of results.
    /// - Returns: Array of matching messages.
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
    /// - Parameters:
    ///   - to: Recipient email address.
    ///   - cc: Optional CC recipient.
    ///   - bcc: Optional BCC recipient.
    ///   - subject: Email subject.
    ///   - body: Email body.
    ///   - isHTML: True if body is HTML, false for plain text.
    ///   - accountName: Optional account to send from.
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
    /// - Parameters:
    ///   - messageId: The message ID.
    ///   - outputDir: Directory path to save attachments.
    /// - Returns: Array of downloaded file paths.
    func downloadAttachments(messageId: String, outputDir: String) throws -> [String]

    // MARK: - Reply & Forward

    /// Replies to a message.
    /// - Parameters:
    ///   - messageId: The message ID.
    ///   - body: Reply body text.
    ///   - replyAll: True to reply all, false to reply to sender only.
    ///   - send: True to send immediately, false to create draft.
    /// - Returns: The reply message ID.
    func reply(messageId: String, body: String, replyAll: Bool, send: Bool) throws -> String

    /// Forwards a message.
    /// - Parameters:
    ///   - messageId: The message ID.
    ///   - to: Recipient email address.
    ///   - body: Forward body text.
    ///   - send: True to send immediately, false to create draft.
    /// - Returns: The forward message ID.
    func forward(messageId: String, to: String, body: String, send: Bool) throws -> String

    // MARK: - Drafts Management

    /// Lists all draft messages.
    /// - Returns: Array of draft messages.
    func listDrafts() throws -> [MailMessage]

    /// Deletes a draft message.
    /// - Parameter messageId: The draft message ID.
    func deleteDraft(messageId: String) throws
}

extension MailServiceProtocol {
    public func getMessage(id: String) throws -> MailMessageDetail? {
        try getMessage(id: id, maxContentLength: nil)
    }
}
