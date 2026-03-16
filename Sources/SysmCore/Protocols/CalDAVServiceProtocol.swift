import Foundation

/// Protocol defining CalDAV operations for managing calendar attendees via iCloud.
///
/// This protocol provides CalDAV-based attendee management that bypasses EventKit's
/// read-only limitation on `EKParticipant`. It communicates directly with iCloud's
/// CalDAV server to add attendees and trigger invitation emails.
///
/// ## Authentication
///
/// CalDAV requires an Apple ID and app-specific password for authentication.
/// App-specific passwords are generated at https://appleid.apple.com under
/// Sign-In and Security > App-Specific Passwords.
///
/// ## Usage
///
/// ```swift
/// let service = CalDAVService()
///
/// // Configure credentials
/// try service.setCredentials(appleID: "user@icloud.com", appPassword: "xxxx-xxxx-xxxx-xxxx")
///
/// // Add attendees to an event by its CalDAV UID
/// try await service.addAttendees(
///     emails: ["colleague@example.com"],
///     toEventUID: "1A2B3C4D-5E6F-...",
///     calendarName: "Work"
/// )
/// ```
public protocol CalDAVServiceProtocol: Sendable {

    /// Returns whether CalDAV credentials have been configured.
    func isConfigured() -> Bool

    /// Stores CalDAV credentials in the Keychain.
    ///
    /// - Parameters:
    ///   - appleID: The Apple ID email address.
    ///   - appPassword: An app-specific password generated at appleid.apple.com.
    /// - Throws: If Keychain storage fails.
    func setCredentials(appleID: String, appPassword: String) throws

    /// Removes stored CalDAV credentials from the Keychain.
    /// - Throws: If Keychain deletion fails.
    func removeCredentials() throws

    /// Discovers all calendars available on the CalDAV server.
    ///
    /// Performs the CalDAV discovery chain (principal → calendar home → enumerate)
    /// and returns all calendar collections.
    ///
    /// - Returns: Array of ``CalDAVCalendar`` objects.
    /// - Throws: ``CalDAVError`` if discovery fails.
    func discoverCalendars() async throws -> [CalDAVCalendar]

    /// Adds attendees to an event on the CalDAV server.
    ///
    /// Finds the event by its iCalendar UID, adds ATTENDEE properties,
    /// and PUTs the updated event back. iCloud sends invitation emails
    /// automatically when it sees new attendees.
    ///
    /// - Parameters:
    ///   - emails: Email addresses of attendees to add.
    ///   - uid: The iCalendar UID of the event (from EventKit's `calendarItemExternalIdentifier`).
    ///   - calendarName: Optional calendar name to narrow the search. Searches all calendars if nil.
    ///   - organizerEmail: Optional organizer email. Uses the configured Apple ID if nil.
    /// - Throws: ``CalDAVError`` if the event cannot be found or updated.
    func addAttendees(emails: [String], toEventUID uid: String, calendarName: String?, organizerEmail: String?) async throws
}
