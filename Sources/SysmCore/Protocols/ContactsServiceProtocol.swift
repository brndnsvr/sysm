import Foundation

/// Protocol defining contacts service operations for accessing and managing macOS Contacts.
///
/// This protocol provides comprehensive access to the user's contacts through the Contacts framework,
/// supporting advanced search (name, email, phone, company, job title), birthday queries, contact groups,
/// photo management, deduplication, and full CRUD operations. All operations require Contacts access
/// permission from the user.
///
/// ## Permission Requirements
///
/// Before using any contacts operations, the app must request and obtain Contacts access:
/// - System Settings > Privacy & Security > Contacts
/// - Use ``ensureAccess()`` to verify permission before operations
///
/// ## Usage Example
///
/// ```swift
/// let service = ContactsService()
///
/// // Ensure access first
/// try await service.ensureAccess()
///
/// // Search by name
/// let results = try await service.search(query: "John")
/// for contact in results {
///     print("\(contact.displayName) - \(contact.emails.first?.value ?? "no email")")
/// }
///
/// // Create new contact
/// let newContact = try await service.createContact(
///     givenName: "Jane",
///     familyName: "Doe",
///     organization: "Acme Corp",
///     jobTitle: "Engineer",
///     emails: [("work", "jane@acme.com")],
///     phones: [("mobile", "555-1234")],
///     addresses: nil,
///     birthday: nil,
///     note: "Met at conference",
///     urls: nil,
///     socialProfiles: nil,
///     relations: nil
/// )
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// Contact operations are performed using the thread-safe Contacts framework.
///
/// ## Error Handling
///
/// All methods can throw ``ContactsError`` variants:
/// - ``ContactsError/accessDenied`` - Contacts permission not granted
/// - ``ContactsError/contactNotFound(_:)`` - Contact not found by identifier
/// - ``ContactsError/groupNotFound(_:)`` - Contact group not found
/// - ``ContactsError/invalidIdentifier(_:)`` - Invalid contact or group identifier
/// - ``ContactsError/saveFailed(_:)`` - Failed to save contact changes
/// - ``ContactsError/imageNotFound(_:)`` - Contact photo image file not found
/// - ``ContactsError/invalidImageFormat`` - Unsupported image format
///
public protocol ContactsServiceProtocol: Sendable {
    // MARK: - Access Management

    /// Ensures the app has access to contacts data.
    ///
    /// This method verifies that Contacts permission has been granted. Call this before
    /// any other contact operations to ensure proper access.
    ///
    /// - Throws: ``ContactsError/accessDenied`` if contacts access not granted or restricted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     try await service.ensureAccess()
    ///     print("Contacts access verified")
    /// } catch ContactsError.accessDenied {
    ///     print("User denied contacts access")
    /// }
    /// ```
    func ensureAccess() async throws

    // MARK: - Search Operations

    /// Searches contacts by name (first, last, or full name).
    ///
    /// Performs a case-insensitive prefix match against contact names. Matches partial
    /// names, so "John" will match "John Smith", "Johnny", etc.
    ///
    /// - Parameter query: Name or partial name to search for.
    /// - Returns: Array of matching ``Contact`` objects.
    /// - Throws: ``ContactsError/accessDenied`` if contacts access not granted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let results = try await service.search(query: "Smith")
    /// print("Found \(results.count) contacts")
    /// ```
    func search(query: String) async throws -> [Contact]

    /// Advanced multi-field search for contacts.
    ///
    /// Searches across multiple contact fields simultaneously. All non-nil parameters
    /// are combined with AND logic (contact must match all specified criteria).
    ///
    /// - Parameters:
    ///   - name: Optional name to search for (matches given name, family name, or nickname).
    ///   - company: Optional company/organization name to search for.
    ///   - jobTitle: Optional job title to search for.
    ///   - email: Optional email address to search for.
    /// - Returns: Array of matching ``Contact`` objects.
    /// - Throws: ``ContactsError/accessDenied`` if contacts access not granted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Find all engineers at Acme Corp
    /// let engineers = try await service.advancedSearch(
    ///     name: nil,
    ///     company: "Acme",
    ///     jobTitle: "Engineer",
    ///     email: nil
    /// )
    /// ```
    func advancedSearch(name: String?, company: String?, jobTitle: String?, email: String?) async throws -> [Contact]

    /// Retrieves a specific contact by identifier.
    ///
    /// - Parameter identifier: The contact's unique identifier from Contacts framework.
    /// - Returns: The ``Contact`` object if found, nil if not found.
    /// - Throws: ``ContactsError/accessDenied`` if contacts access not granted.
    func getContact(identifier: String) async throws -> Contact?

    /// Searches contacts by email address.
    ///
    /// Performs case-insensitive search across all email addresses. Returns tuples
    /// for each matching email (a contact with multiple matching emails appears multiple times).
    ///
    /// - Parameter query: Email address or partial email to search for.
    /// - Returns: Array of tuples with contact name and matching email address.
    /// - Throws: ``ContactsError/accessDenied`` if contacts access not granted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let results = try await service.searchByEmail(query: "@acme.com")
    /// for (name, email) in results {
    ///     print("\(name): \(email)")
    /// }
    /// ```
    func searchByEmail(query: String) async throws -> [(name: String, email: String)]

    /// Searches contacts by phone number.
    ///
    /// Performs search across all phone numbers. Supports partial matching.
    /// Returns tuples for each matching phone (a contact with multiple matching phones appears multiple times).
    ///
    /// - Parameter query: Phone number or partial number to search for (digits only recommended).
    /// - Returns: Array of tuples with contact name and matching phone number.
    /// - Throws: ``ContactsError/accessDenied`` if contacts access not granted.
    func searchByPhone(query: String) async throws -> [(name: String, phone: String)]

    /// Retrieves contacts with upcoming birthdays.
    ///
    /// Returns contacts whose birthdays fall within the specified number of days from today.
    /// Results are sorted by days until birthday (soonest first).
    ///
    /// - Parameter days: Number of days to look ahead (e.g., 30 for next month).
    /// - Returns: Array of tuples with contact name, birthday components, and days until birthday.
    /// - Throws: ``ContactsError/accessDenied`` if contacts access not granted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let upcoming = try await service.getUpcomingBirthdays(days: 7)
    /// for (name, birthday, daysUntil) in upcoming {
    ///     print("\(name)'s birthday in \(daysUntil) days")
    /// }
    /// ```
    func getUpcomingBirthdays(days: Int) async throws -> [(name: String, birthday: DateComponents, daysUntil: Int)]

    // MARK: - Group Management

    /// Retrieves all contact groups.
    ///
    /// Returns all groups defined in the Contacts app. Groups can be used to organize
    /// contacts into categories (e.g., "Family", "Work", "Friends").
    ///
    /// - Returns: Array of ``ContactGroup`` objects.
    /// - Throws: ``ContactsError/accessDenied`` if contacts access not granted.
    func getGroups() async throws -> [ContactGroup]

    /// Gets members of a contact group.
    ///
    /// Returns all contacts that are members of the specified group.
    ///
    /// - Parameter groupIdentifier: Group's unique identifier.
    /// - Returns: Array of ``Contact`` objects in the group.
    /// - Throws:
    ///   - ``ContactsError/accessDenied`` if contacts access not granted.
    ///   - ``ContactsError/groupNotFound(_:)`` if group doesn't exist.
    func getGroupMembers(groupIdentifier: String) async throws -> [Contact]

    /// Adds a contact to a group.
    ///
    /// Adds an existing contact to a group. A contact can be a member of multiple groups.
    ///
    /// - Parameters:
    ///   - contactIdentifier: Contact's unique identifier.
    ///   - groupIdentifier: Group's unique identifier.
    /// - Returns: `true` if added successfully, `false` if already a member.
    /// - Throws:
    ///   - ``ContactsError/accessDenied`` if contacts access not granted.
    ///   - ``ContactsError/contactNotFound(_:)`` if contact doesn't exist.
    ///   - ``ContactsError/groupNotFound(_:)`` if group doesn't exist.
    ///   - ``ContactsError/saveFailed(_:)`` if save operation failed.
    func addContactToGroup(contactIdentifier: String, groupIdentifier: String) async throws -> Bool

    /// Removes a contact from a group.
    ///
    /// Removes a contact's membership from a group. The contact itself is not deleted.
    ///
    /// - Parameters:
    ///   - contactIdentifier: Contact's unique identifier.
    ///   - groupIdentifier: Group's unique identifier.
    /// - Returns: `true` if removed successfully, `false` if not a member.
    /// - Throws:
    ///   - ``ContactsError/accessDenied`` if contacts access not granted.
    ///   - ``ContactsError/contactNotFound(_:)`` if contact doesn't exist.
    ///   - ``ContactsError/groupNotFound(_:)`` if group doesn't exist.
    ///   - ``ContactsError/saveFailed(_:)`` if save operation failed.
    func removeContactFromGroup(contactIdentifier: String, groupIdentifier: String) async throws -> Bool

    /// Renames a contact group.
    ///
    /// Changes the display name of an existing group.
    ///
    /// - Parameters:
    ///   - groupIdentifier: Group's unique identifier.
    ///   - newName: New display name for the group.
    /// - Returns: `true` if renamed successfully.
    /// - Throws:
    ///   - ``ContactsError/accessDenied`` if contacts access not granted.
    ///   - ``ContactsError/groupNotFound(_:)`` if group doesn't exist.
    ///   - ``ContactsError/saveFailed(_:)`` if save operation failed.
    func renameGroup(groupIdentifier: String, newName: String) async throws -> Bool

    // MARK: - CRUD Operations

    /// Creates a new contact with comprehensive field support.
    ///
    /// Creates a contact with any combination of fields. At minimum, provide either a name
    /// (givenName or familyName) or organization. All parameters are optional, but at least
    /// one should be provided for a meaningful contact.
    ///
    /// - Parameters:
    ///   - givenName: First name.
    ///   - familyName: Last name.
    ///   - organization: Company/organization name.
    ///   - jobTitle: Job title.
    ///   - emails: Email addresses with optional labels (e.g., "work", "home", "other").
    ///   - phones: Phone numbers with optional labels (e.g., "mobile", "work", "home").
    ///   - addresses: Postal addresses using ``ContactAddress`` objects.
    ///   - birthday: Birthday date components (month, day, and optionally year).
    ///   - note: Free-form notes about the contact.
    ///   - urls: Website URLs with optional labels.
    ///   - socialProfiles: Social media profiles using ``ContactSocialProfile`` objects.
    ///   - relations: Related people with labels (e.g., "spouse", "child", "manager").
    /// - Returns: The created ``Contact`` object with system-assigned identifier.
    /// - Throws:
    ///   - ``ContactsError/accessDenied`` if contacts access not granted.
    ///   - ``ContactsError/saveFailed(_:)`` if save operation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let contact = try await service.createContact(
    ///     givenName: "Jane",
    ///     familyName: "Smith",
    ///     organization: "Tech Corp",
    ///     jobTitle: "Senior Engineer",
    ///     emails: [("work", "jane@tech.com"), ("personal", "jane@example.com")],
    ///     phones: [("mobile", "555-0123")],
    ///     addresses: nil,
    ///     birthday: DateComponents(month: 3, day: 15),
    ///     note: "Met at tech conference 2024",
    ///     urls: nil,
    ///     socialProfiles: nil,
    ///     relations: nil
    /// )
    /// print("Created contact: \(contact.identifier)")
    /// ```
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

    /// Updates an existing contact with new field values.
    ///
    /// Updates specified fields of an existing contact. All parameters except identifier
    /// are optional - only non-nil values will be updated. Nil values leave the current
    /// value unchanged.
    ///
    /// - Parameters:
    ///   - identifier: Contact's unique identifier.
    ///   - givenName: New first name (nil to keep current).
    ///   - familyName: New last name (nil to keep current).
    ///   - organization: New organization (nil to keep current).
    ///   - jobTitle: New job title (nil to keep current).
    ///   - emails: New emails - replaces all existing emails (nil to keep current).
    ///   - phones: New phones - replaces all existing phones (nil to keep current).
    ///   - note: New note (nil to keep current).
    /// - Returns: The updated ``Contact`` object.
    /// - Throws:
    ///   - ``ContactsError/accessDenied`` if contacts access not granted.
    ///   - ``ContactsError/contactNotFound(_:)`` if contact doesn't exist.
    ///   - ``ContactsError/saveFailed(_:)`` if save operation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Update just the job title
    /// let updated = try await service.updateContact(
    ///     identifier: "ABC123",
    ///     givenName: nil,
    ///     familyName: nil,
    ///     organization: nil,
    ///     jobTitle: "Lead Engineer",
    ///     emails: nil,
    ///     phones: nil,
    ///     note: nil
    /// )
    /// ```
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

    /// Deletes a contact permanently.
    ///
    /// Removes the contact from all groups and deletes it from the Contacts database.
    /// This operation cannot be undone.
    ///
    /// - Parameter identifier: Contact's unique identifier.
    /// - Returns: `true` if deleted successfully.
    /// - Throws:
    ///   - ``ContactsError/accessDenied`` if contacts access not granted.
    ///   - ``ContactsError/contactNotFound(_:)`` if contact doesn't exist.
    ///   - ``ContactsError/saveFailed(_:)`` if delete operation failed.
    func deleteContact(identifier: String) async throws -> Bool

    // MARK: - Photo Management

    /// Sets a contact's photo from an image file.
    ///
    /// Loads an image from the filesystem and assigns it as the contact's photo.
    /// Supports common image formats (PNG, JPEG, HEIC, etc.).
    ///
    /// - Parameters:
    ///   - identifier: Contact's unique identifier.
    ///   - imagePath: Absolute or relative path to the image file.
    /// - Returns: `true` if photo was set successfully.
    /// - Throws:
    ///   - ``ContactsError/accessDenied`` if contacts access not granted.
    ///   - ``ContactsError/contactNotFound(_:)`` if contact doesn't exist.
    ///   - ``ContactsError/imageNotFound(_:)`` if image file doesn't exist at path.
    ///   - ``ContactsError/invalidImageFormat`` if image format is not supported.
    ///   - ``ContactsError/saveFailed(_:)`` if save operation failed.
    func setContactPhoto(identifier: String, imagePath: String) async throws -> Bool

    /// Retrieves a contact's photo and saves it to a file.
    ///
    /// Exports the contact's photo image to the specified file path.
    /// Returns false if the contact has no photo set.
    ///
    /// - Parameters:
    ///   - identifier: Contact's unique identifier.
    ///   - outputPath: Destination file path for the exported image.
    /// - Returns: `true` if photo was saved, `false` if contact has no photo.
    /// - Throws:
    ///   - ``ContactsError/accessDenied`` if contacts access not granted.
    ///   - ``ContactsError/contactNotFound(_:)`` if contact doesn't exist.
    func getContactPhoto(identifier: String, outputPath: String) async throws -> Bool

    /// Removes a contact's photo.
    ///
    /// Deletes the photo image from the contact. The contact itself is not deleted.
    ///
    /// - Parameter identifier: Contact's unique identifier.
    /// - Returns: `true` if photo was removed or contact had no photo.
    /// - Throws:
    ///   - ``ContactsError/accessDenied`` if contacts access not granted.
    ///   - ``ContactsError/contactNotFound(_:)`` if contact doesn't exist.
    ///   - ``ContactsError/saveFailed(_:)`` if save operation failed.
    func removeContactPhoto(identifier: String) async throws -> Bool

    // MARK: - Deduplication

    /// Finds potential duplicate contacts using similarity matching.
    ///
    /// Analyzes all contacts to find potential duplicates based on name, email, and phone
    /// similarity. Returns groups of contacts that are likely duplicates of each other.
    ///
    /// - Parameter similarityThreshold: Similarity threshold from 0.0 to 1.0. Higher values
    ///   require closer matches. Default 0.8 works well for most cases.
    /// - Returns: Array of contact groups where each group contains potential duplicates.
    /// - Throws: ``ContactsError/accessDenied`` if contacts access not granted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let duplicates = try await service.findDuplicates(similarityThreshold: 0.8)
    /// for group in duplicates {
    ///     print("Potential duplicates:")
    ///     for contact in group {
    ///         print("  - \(contact.displayName)")
    ///     }
    /// }
    /// ```
    func findDuplicates(similarityThreshold: Double) async throws -> [[Contact]]

    /// Merges two contacts, keeping the primary and merging in data from the duplicate.
    ///
    /// Combines data from both contacts into the primary contact, then deletes the duplicate.
    /// Data from the duplicate is added to the primary (emails, phones, addresses, etc.),
    /// but the primary's existing data takes precedence for single-value fields.
    ///
    /// - Parameters:
    ///   - primaryIdentifier: Identifier of the contact to keep.
    ///   - duplicateIdentifier: Identifier of the contact to merge and delete.
    /// - Returns: The merged ``Contact`` object.
    /// - Throws:
    ///   - ``ContactsError/accessDenied`` if contacts access not granted.
    ///   - ``ContactsError/contactNotFound(_:)`` if either contact doesn't exist.
    ///   - ``ContactsError/saveFailed(_:)`` if merge or delete operation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let merged = try await service.mergeContacts(
    ///     primaryIdentifier: "ABC123",
    ///     duplicateIdentifier: "XYZ789"
    /// )
    /// print("Merged into: \(merged.displayName)")
    /// ```
    func mergeContacts(primaryIdentifier: String, duplicateIdentifier: String) async throws -> Contact
}
