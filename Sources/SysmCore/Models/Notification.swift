import Foundation

public struct PendingNotification: Codable, Sendable {
    public let identifier: String
    public let title: String
    public let body: String
    public let subtitle: String?
    public let triggerDate: Date?

    public init(identifier: String, title: String, body: String, subtitle: String?, triggerDate: Date?) {
        self.identifier = identifier
        self.title = title
        self.body = body
        self.subtitle = subtitle
        self.triggerDate = triggerDate
    }
}
