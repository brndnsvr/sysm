import Foundation

public protocol OutlookServiceProtocol: Sendable {
    func isAvailable() -> Bool
    func getInbox(limit: Int) throws -> [OutlookMessage]
    func getUnread(limit: Int) throws -> [OutlookMessage]
    func searchMessages(query: String, limit: Int) throws -> [OutlookMessage]
    func getMessage(id: String) throws -> OutlookMessageDetail?
    func send(to: [String], cc: [String], subject: String, body: String) throws
    func getCalendarEvents(days: Int) throws -> [OutlookCalendarEvent]
    func getTasks(priority: String?) throws -> [OutlookTask]
}
