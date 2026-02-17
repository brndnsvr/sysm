import Foundation

public protocol NotificationServiceProtocol: Sendable {
    func send(title: String, body: String, subtitle: String?, sound: Bool) async throws
    func schedule(title: String, body: String, subtitle: String?, triggerDate: Date, sound: Bool) async throws -> String
    func listPending() async throws -> [PendingNotification]
    func removePending(identifier: String) async throws
    func removeAllPending() async throws
}
