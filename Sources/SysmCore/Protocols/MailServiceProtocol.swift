import Foundation

/// Protocol defining mail service operations for accessing macOS Mail via AppleScript.
///
/// Implementations provide read access to the user's email accounts and messages,
/// supporting inbox queries, search, and draft creation.
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

    /// Retrieves a specific message by ID.
    /// - Parameter id: The message ID.
    /// - Returns: The message detail if found, nil otherwise.
    func getMessage(id: String) throws -> MailMessageDetail?

    /// Searches messages by query.
    /// - Parameters:
    ///   - accountName: Optional account name to filter messages.
    ///   - query: Search query string.
    ///   - limit: Maximum number of results.
    /// - Returns: Array of matching messages.
    func searchMessages(accountName: String?, query: String, limit: Int) throws -> [MailMessage]

    /// Creates a new draft message.
    /// - Parameters:
    ///   - to: Optional recipient email.
    ///   - subject: Optional email subject.
    ///   - body: Optional email body.
    func createDraft(to: String?, subject: String?, body: String?) throws
}
