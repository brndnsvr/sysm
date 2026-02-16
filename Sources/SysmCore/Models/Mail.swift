import Foundation

// MARK: - Models

public struct MailAccount: Codable {
    public let id: String
    public let name: String
    public let email: String
}

public struct MailMessage: Codable {
    public let id: String
    public let messageId: String
    public let subject: String
    public let from: String
    public let dateReceived: String
    public let isRead: Bool
    public let accountName: String
}

public struct MailMessageDetail: Codable {
    public let id: String
    public let messageId: String
    public let subject: String
    public let from: String
    public let to: String
    public let cc: String?
    public let bcc: String?
    public let replyTo: String?
    public let dateReceived: String
    public let dateSent: String?
    public let content: String
    public let isRead: Bool
    public let isFlagged: Bool
    public let mailbox: String?
    public let accountName: String?
    public let attachments: [MailAttachment]
}

public struct MailAttachment: Codable {
    public let name: String
    public let mimeType: String
    public let size: Int
}

public struct MailMailbox: Codable {
    public let name: String
    public let accountName: String
    public let unreadCount: Int
    public let messageCount: Int
    public let fullPath: String
}

// MARK: - Errors

public enum MailError: LocalizedError {
    case appleScriptError(String)
    case mailNotRunning
    case messageNotFound(String)
    case mailboxNotFound(String)
    case accountNotFound(String)
    case sendFailed(String)
    case invalidDateRange
    case noRecipientsSpecified
    case invalidOutputDirectory(String)

    public var errorDescription: String? {
        switch self {
        case .appleScriptError(let message):
            return "AppleScript error: \(message)"
        case .mailNotRunning:
            return "Mail app is not running"
        case .messageNotFound(let id):
            return "Message '\(id)' not found"
        case .mailboxNotFound(let name):
            return "Mailbox '\(name)' not found"
        case .accountNotFound(let name):
            return "Account '\(name)' not found"
        case .sendFailed(let reason):
            return "Failed to send message: \(reason)"
        case .invalidDateRange:
            return "Invalid date range specified"
        case .noRecipientsSpecified:
            return "No recipients specified"
        case .invalidOutputDirectory(let path):
            return "Invalid output directory: '\(path)'"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .appleScriptError(let message):
            return """
            AppleScript execution failed: \(message)

            This may require automation permission:
            1. Open System Settings
            2. Navigate to Privacy & Security > Automation
            3. Find Terminal (or your terminal app)
            4. Enable Mail
            5. Restart sysm
            """
        case .mailNotRunning:
            return """
            Mail app must be running to access messages.

            Try:
            1. Open Mail app: open -a Mail
            2. Wait a few seconds for it to start
            3. Run the command again
            """
        case .messageNotFound:
            return """
            Message not found with that identifier.

            Try:
            - List recent messages: sysm mail inbox --limit 20
            - Search messages: sysm mail search "subject"
            - Check different account: sysm mail inbox --account "Work"
            """
        case .mailboxNotFound(let name):
            return """
            Mailbox '\(name)' not found.

            Try:
            - List mailboxes: sysm mail mailboxes
            - Use standard names: "Inbox", "Sent", "Drafts", "Archive"
            - Include account: sysm mail mailboxes --account "Work"
            """
        case .accountNotFound(let name):
            return """
            Mail account '\(name)' not found.

            Try:
            - List accounts: sysm mail accounts
            - Check spelling and capitalization
            - Omit --account to search all accounts
            """
        case .sendFailed(let reason):
            return """
            Failed to send message: \(reason)

            Try:
            - Verify recipient email address is valid
            - Check your internet connection
            - Ensure Mail app is configured correctly
            - Try sending from Mail app directly first
            """
        case .invalidDateRange:
            return """
            Invalid date range. Start date must be before end date.

            Example:
            sysm mail search --after "2024-01-01" --before "2024-12-31"
            """
        case .noRecipientsSpecified:
            return """
            At least one recipient is required to send a message.

            Example:
            sysm mail send --to "user@example.com" --subject "Test" --body "Message"
            """
        case .invalidOutputDirectory(let path):
            return """
            Output directory doesn't exist or isn't writable: \(path)

            Try:
            - Create the directory: mkdir -p "\(path)"
            - Check permissions: ls -ld "\(path)"
            - Use a different directory
            """
        }
    }
}
