import Foundation

/// Protocol for mail service operations
protocol MailServiceProtocol {
    func getAccounts() throws -> [MailAccount]
    func getInboxMessages(limit: Int) throws -> [MailMessage]
    func getUnreadMessages(limit: Int) throws -> [MailMessage]
    func getMessage(id: String) throws -> MailMessageDetail?
    func searchMessages(query: String, limit: Int) throws -> [MailMessage]
    func createDraft(to: String?, subject: String?, body: String?) throws
}
