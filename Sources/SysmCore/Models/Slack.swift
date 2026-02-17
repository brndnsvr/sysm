import Foundation

public struct SlackChannel: Codable {
    public let id: String
    public let name: String
    public let isPrivate: Bool
    public let memberCount: Int?
    public let topic: String?

    public init(id: String, name: String, isPrivate: Bool, memberCount: Int? = nil, topic: String? = nil) {
        self.id = id
        self.name = name
        self.isPrivate = isPrivate
        self.memberCount = memberCount
        self.topic = topic
    }
}

public struct SlackMessageResult: Codable {
    public let channel: String
    public let timestamp: String
    public let ok: Bool

    public init(channel: String, timestamp: String, ok: Bool) {
        self.channel = channel
        self.timestamp = timestamp
        self.ok = ok
    }
}

public enum SlackError: LocalizedError {
    case notConfigured
    case invalidToken
    case apiError(String)
    case channelNotFound(String)
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Slack is not configured"
        case .invalidToken:
            return "Slack token is invalid or expired"
        case .apiError(let message):
            return "Slack API error: \(message)"
        case .channelNotFound(let name):
            return "Channel '\(name)' not found"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notConfigured:
            return """
            Set up Slack integration:
              sysm slack auth --token xoxb-your-token

            Create a Slack app at https://api.slack.com/apps
            Required scopes: chat:write, channels:read, users:read
            """
        case .invalidToken:
            return "Update your token: sysm slack auth --token xoxb-new-token"
        default:
            return nil
        }
    }
}
