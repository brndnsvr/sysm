import Foundation

public struct OutlookMessage: Codable {
    public let id: String
    public let subject: String
    public let from: String
    public let dateReceived: String
    public let isRead: Bool
    public let account: String?

    public init(id: String, subject: String, from: String, dateReceived: String, isRead: Bool, account: String? = nil) {
        self.id = id
        self.subject = subject
        self.from = from
        self.dateReceived = dateReceived
        self.isRead = isRead
        self.account = account
    }
}

public struct OutlookMessageDetail: Codable {
    public let id: String
    public let subject: String
    public let from: String
    public let to: String
    public let cc: String?
    public let dateReceived: String
    public let body: String
    public let isRead: Bool

    public init(id: String, subject: String, from: String, to: String, cc: String?,
                dateReceived: String, body: String, isRead: Bool) {
        self.id = id
        self.subject = subject
        self.from = from
        self.to = to
        self.cc = cc
        self.dateReceived = dateReceived
        self.body = body
        self.isRead = isRead
    }
}

public struct OutlookCalendarEvent: Codable {
    public let id: String
    public let subject: String
    public let startTime: String
    public let endTime: String
    public let location: String?
    public let isAllDay: Bool

    public init(id: String, subject: String, startTime: String, endTime: String,
                location: String?, isAllDay: Bool) {
        self.id = id
        self.subject = subject
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.isAllDay = isAllDay
    }
}

public struct OutlookTask: Codable {
    public let id: String
    public let name: String
    public let dueDate: String?
    public let priority: String
    public let isComplete: Bool

    public init(id: String, name: String, dueDate: String?, priority: String, isComplete: Bool) {
        self.id = id
        self.name = name
        self.dueDate = dueDate
        self.priority = priority
        self.isComplete = isComplete
    }
}

public enum OutlookError: LocalizedError {
    case outlookNotRunning
    case outlookNotInstalled
    case appleScriptError(String)
    case messageNotFound(String)
    case sendFailed(String)
    case noRecipientsSpecified

    public var errorDescription: String? {
        switch self {
        case .outlookNotRunning:
            return "Microsoft Outlook is not running"
        case .outlookNotInstalled:
            return "Microsoft Outlook is not installed"
        case .appleScriptError(let message):
            return "Outlook AppleScript error: \(message)"
        case .messageNotFound(let id):
            return "Message '\(id)' not found"
        case .sendFailed(let message):
            return "Failed to send message: \(message)"
        case .noRecipientsSpecified:
            return "No recipients specified"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .outlookNotRunning:
            return "Open Microsoft Outlook first: open -a 'Microsoft Outlook'"
        case .outlookNotInstalled:
            return "Install Microsoft Outlook from the App Store or Office 365"
        case .appleScriptError:
            return """
            Grant automation permission:
            System Settings > Privacy & Security > Automation > Terminal > Microsoft Outlook
            """
        default:
            return nil
        }
    }
}
