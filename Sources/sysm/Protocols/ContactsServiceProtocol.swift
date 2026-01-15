import Foundation

/// Protocol for contacts service operations
protocol ContactsServiceProtocol: Sendable {
    func ensureAccess() async throws
    func search(query: String) async throws -> [Contact]
    func getContact(identifier: String) async throws -> Contact?
    func searchByEmail(query: String) async throws -> [(name: String, email: String)]
    func searchByPhone(query: String) async throws -> [(name: String, phone: String)]
    func getUpcomingBirthdays(days: Int) async throws -> [(name: String, birthday: DateComponents, daysUntil: Int)]
    func getGroups() async throws -> [ContactGroup]
}
