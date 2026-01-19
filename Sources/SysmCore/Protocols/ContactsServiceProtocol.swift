import Foundation

/// Protocol defining contacts service operations for accessing macOS Contacts.
///
/// Implementations provide read-only access to the user's contacts through the Contacts framework,
/// supporting search by name, email, phone, and birthday queries.
public protocol ContactsServiceProtocol: Sendable {
    /// Ensures the app has access to contacts data.
    /// - Throws: If access is denied or cannot be determined.
    func ensureAccess() async throws

    /// Searches contacts by name.
    /// - Parameter query: Name or partial name to search for.
    /// - Returns: Array of matching contacts.
    func search(query: String) async throws -> [Contact]

    /// Retrieves a specific contact by identifier.
    /// - Parameter identifier: The contact's unique identifier.
    /// - Returns: The contact if found, nil otherwise.
    func getContact(identifier: String) async throws -> Contact?

    /// Searches contacts by email address.
    /// - Parameter query: Email or partial email to search for.
    /// - Returns: Array of tuples with name and matching email.
    func searchByEmail(query: String) async throws -> [(name: String, email: String)]

    /// Searches contacts by phone number.
    /// - Parameter query: Phone number or partial number to search for.
    /// - Returns: Array of tuples with name and matching phone.
    func searchByPhone(query: String) async throws -> [(name: String, phone: String)]

    /// Retrieves contacts with upcoming birthdays.
    /// - Parameter days: Number of days to look ahead.
    /// - Returns: Array of tuples with name, birthday, and days until.
    func getUpcomingBirthdays(days: Int) async throws -> [(name: String, birthday: DateComponents, daysUntil: Int)]

    /// Retrieves all contact groups.
    /// - Returns: Array of contact groups.
    func getGroups() async throws -> [ContactGroup]
}
