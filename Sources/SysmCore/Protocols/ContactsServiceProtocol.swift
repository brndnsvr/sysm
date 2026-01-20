import Foundation

/// Protocol defining contacts service operations for accessing macOS Contacts.
///
/// Implementations provide access to the user's contacts through the Contacts framework,
/// supporting search by name, email, phone, birthday queries, and CRUD operations.
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

    // MARK: - CRUD Operations

    /// Creates a new contact.
    /// - Parameters:
    ///   - givenName: First name.
    ///   - familyName: Last name.
    ///   - organization: Company/organization name.
    ///   - jobTitle: Job title.
    ///   - emails: Email addresses with optional labels.
    ///   - phones: Phone numbers with optional labels.
    ///   - addresses: Postal addresses.
    ///   - birthday: Birthday date components.
    ///   - note: Notes about the contact.
    ///   - urls: Website URLs.
    ///   - socialProfiles: Social media profiles.
    ///   - relations: Related people.
    /// - Returns: The created contact.
    func createContact(
        givenName: String?,
        familyName: String?,
        organization: String?,
        jobTitle: String?,
        emails: [(label: String?, value: String)]?,
        phones: [(label: String?, value: String)]?,
        addresses: [ContactAddress]?,
        birthday: DateComponents?,
        note: String?,
        urls: [(label: String?, value: String)]?,
        socialProfiles: [ContactSocialProfile]?,
        relations: [(label: String, name: String)]?
    ) async throws -> Contact

    /// Updates an existing contact.
    /// - Parameters:
    ///   - identifier: Contact identifier.
    ///   - givenName: New first name (nil to keep current).
    ///   - familyName: New last name (nil to keep current).
    ///   - organization: New organization (nil to keep current).
    ///   - jobTitle: New job title (nil to keep current).
    ///   - emails: New emails (nil to keep current).
    ///   - phones: New phones (nil to keep current).
    ///   - note: New note (nil to keep current).
    /// - Returns: The updated contact.
    func updateContact(
        identifier: String,
        givenName: String?,
        familyName: String?,
        organization: String?,
        jobTitle: String?,
        emails: [(label: String?, value: String)]?,
        phones: [(label: String?, value: String)]?,
        note: String?
    ) async throws -> Contact

    /// Deletes a contact.
    /// - Parameter identifier: Contact identifier.
    /// - Returns: True if deleted successfully.
    func deleteContact(identifier: String) async throws -> Bool
}
