import Foundation

/// Represents a CalDAV calendar collection discovered on the server.
public struct CalDAVCalendar: Codable, Sendable {
    public let href: String
    public let displayName: String
    public let ctag: String?

    public init(href: String, displayName: String, ctag: String? = nil) {
        self.href = href
        self.displayName = displayName
        self.ctag = ctag
    }
}

/// Represents a CalDAV event resource fetched from the server.
public struct CalDAVEventResource: Codable, Sendable {
    public let href: String
    public let etag: String
    public let icsData: String

    public init(href: String, etag: String, icsData: String) {
        self.href = href
        self.etag = etag
        self.icsData = icsData
    }
}

/// Errors specific to CalDAV operations.
public enum CalDAVError: LocalizedError {
    case notConfigured
    case authenticationFailed
    case networkError(String)
    case serverError(Int, String)
    case eventNotFound(String)
    case calendarNotFound(String)
    case xmlParseError(String)
    case invalidResponse(String)
    case syncPending

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "CalDAV credentials not configured"
        case .authenticationFailed:
            return "CalDAV authentication failed"
        case .networkError(let detail):
            return "CalDAV network error: \(detail)"
        case .serverError(let code, let detail):
            return "CalDAV server error (HTTP \(code)): \(detail)"
        case .eventNotFound(let uid):
            return "Event not found on CalDAV server (UID: \(uid))"
        case .calendarNotFound(let name):
            return "Calendar '\(name)' not found on CalDAV server"
        case .xmlParseError(let detail):
            return "Failed to parse CalDAV response: \(detail)"
        case .invalidResponse(let detail):
            return "Invalid CalDAV response: \(detail)"
        case .syncPending:
            return "Event has not synced to iCloud yet"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notConfigured:
            return """
            Configure CalDAV credentials to enable attendee invitations:

            1. Generate an app-specific password at https://appleid.apple.com
               (Sign-In and Security > App-Specific Passwords)
            2. Run: sysm calendar caldav-auth --apple-id your@icloud.com --app-password xxxx-xxxx-xxxx-xxxx
            """
        case .authenticationFailed:
            return """
            Check your CalDAV credentials:

            - Ensure your Apple ID is correct
            - Generate a new app-specific password at https://appleid.apple.com
            - Update credentials: sysm calendar caldav-auth --apple-id your@icloud.com --app-password xxxx-xxxx-xxxx-xxxx
            """
        case .networkError:
            return "Check your internet connection and try again."
        case .serverError:
            return "The iCloud CalDAV server returned an error. Try again later."
        case .eventNotFound:
            return """
            The event could not be found on the CalDAV server.

            Try:
            - Wait a moment for iCloud sync to complete
            - Use: sysm calendar invite <event-id> --attendee email@example.com
            """
        case .calendarNotFound:
            return """
            The calendar was not found on the CalDAV server.

            Try:
            - List available calendars: sysm calendar calendars
            - Verify the calendar syncs to iCloud (local-only calendars are not supported)
            """
        case .xmlParseError, .invalidResponse:
            return "This may indicate a server-side issue. Try again later."
        case .syncPending:
            return """
            The event was created locally but hasn't synced to iCloud yet.

            Try:
            - Wait a few seconds and use: sysm calendar invite <event-id> --attendee email@example.com
            - Ensure the calendar syncs to iCloud (local-only calendars do not support attendees)
            """
        }
    }
}
