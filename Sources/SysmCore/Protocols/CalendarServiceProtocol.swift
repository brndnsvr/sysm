import Foundation

/// Protocol defining calendar service operations for accessing and managing macOS Calendar events.
///
/// This protocol provides comprehensive access to the user's calendars and events through EventKit,
/// supporting queries by date range, search, calendar filtering, and full CRUD operations.
/// All operations require Calendar access permission from the user.
///
/// ## Permission Requirements
///
/// Before using any calendar operations, the app must request and obtain Calendar access:
/// - System Settings > Privacy & Security > Calendars
/// - Use ``requestAccess()`` to prompt the user for permission
///
/// ## Usage Example
///
/// ```swift
/// let service = CalendarService()
///
/// // Request access first
/// try await service.requestAccess()
///
/// // Get today's events
/// let events = try await service.getTodayEvents()
/// for event in events {
///     print("\(event.title) at \(event.startDate)")
/// }
///
/// // Create a new event
/// let tomorrow = Date().addingTimeInterval(86400)
/// let end = tomorrow.addingTimeInterval(3600)
/// let event = try await service.addEvent(
///     title: "Team Meeting",
///     startDate: tomorrow,
///     endDate: end,
///     calendarName: nil,
///     location: "Conference Room A",
///     notes: "Q1 Planning",
///     isAllDay: false
/// )
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// EventKit operations are performed on the main actor internally.
///
/// ## Error Handling
///
/// All methods can throw ``CalendarError`` variants:
/// - ``CalendarError/accessDenied`` - Calendar permission not granted
/// - ``CalendarError/calendarNotFound(_:)`` - Specified calendar doesn't exist
/// - ``CalendarError/noDefaultCalendar`` - No default calendar configured
/// - ``CalendarError/eventNotFound(_:)`` - Event not found by title or ID
/// - ``CalendarError/invalidDateFormat(_:)`` - Date parsing failed
/// - ``CalendarError/calendarReadOnly`` - Calendar cannot be modified
/// - ``CalendarError/invalidColor(_:)`` - Invalid hex color format
/// - ``CalendarError/invalidYear(_:)`` - Year outside valid range (2000-2100)
///
public protocol CalendarServiceProtocol: Sendable {
    // MARK: - Access Management

    /// Requests access to the user's calendar data.
    ///
    /// This method must be called before any other calendar operations. It will prompt
    /// the user for permission if not already granted. Subsequent calls return the
    /// cached permission status.
    ///
    /// - Returns: `true` if access was granted, `false` if denied.
    /// - Throws: ``CalendarError/accessDenied`` if permission is denied or restricted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     let granted = try await service.requestAccess()
    ///     if granted {
    ///         print("Calendar access granted")
    ///     }
    /// } catch CalendarError.accessDenied {
    ///     print("User denied calendar access")
    /// }
    /// ```
    func requestAccess() async throws -> Bool

    // MARK: - Calendar Management

    /// Lists all available calendars by name.
    ///
    /// Returns calendar names in the order they appear in the Calendar app.
    /// Includes both local and synced (iCloud, Exchange) calendars.
    ///
    /// - Returns: Array of calendar names.
    /// - Throws: ``CalendarError/accessDenied`` if calendar access not granted.
    func listCalendars() async throws -> [String]

    /// Lists all calendars with detailed information including color and type.
    ///
    /// Provides full calendar metadata including title, color, whether it's the default,
    /// and calendar type (Local, CalDAV, Exchange, etc.).
    ///
    /// - Returns: Array of ``Calendar`` objects with full details.
    /// - Throws: ``CalendarError/accessDenied`` if calendar access not granted.
    func listCalendarsDetailed() async throws -> [Calendar]

    /// Renames an existing calendar.
    ///
    /// - Parameters:
    ///   - name: Current calendar name (must match exactly).
    ///   - newName: New calendar name.
    /// - Returns: `true` if renamed successfully.
    /// - Throws:
    ///   - ``CalendarError/calendarNotFound(_:)`` if calendar doesn't exist.
    ///   - ``CalendarError/calendarReadOnly`` if calendar is not editable.
    func renameCalendar(name: String, newName: String) async throws -> Bool

    /// Sets a calendar's display color.
    ///
    /// - Parameters:
    ///   - name: Calendar name.
    ///   - hexColor: Hex color string in format `#RRGGBB` (e.g., "#FF5733").
    /// - Returns: `true` if color was set successfully.
    /// - Throws:
    ///   - ``CalendarError/calendarNotFound(_:)`` if calendar doesn't exist.
    ///   - ``CalendarError/invalidColor(_:)`` if hex color format is invalid.
    func setCalendarColor(name: String, hexColor: String) async throws -> Bool

    // MARK: - Event Queries

    /// Retrieves events within a specific date range.
    ///
    /// Returns all events that overlap with the specified date range, optionally
    /// filtered by calendar name.
    ///
    /// - Parameters:
    ///   - startDate: Start of the date range (inclusive).
    ///   - endDate: End of the date range (inclusive).
    ///   - calendar: Optional calendar name to filter by. If `nil`, searches all calendars.
    /// - Returns: Array of ``CalendarEvent`` objects in the range.
    /// - Throws:
    ///   - ``CalendarError/accessDenied`` if calendar access not granted.
    ///   - ``CalendarError/calendarNotFound(_:)`` if specified calendar doesn't exist.
    func getEvents(from startDate: Date, to endDate: Date, calendar: String?) async throws -> [CalendarEvent]

    /// Retrieves all events for today (midnight to midnight in local time).
    ///
    /// Convenience method equivalent to calling ``getEvents(from:to:calendar:)``
    /// with today's start and end times.
    ///
    /// - Returns: Array of today's ``CalendarEvent`` objects.
    /// - Throws: ``CalendarError/accessDenied`` if calendar access not granted.
    func getTodayEvents() async throws -> [CalendarEvent]

    /// Retrieves all events for the current week (Sunday to Saturday).
    ///
    /// Uses the current calendar's week definition (may vary by locale).
    ///
    /// - Returns: Array of ``CalendarEvent`` objects for the week.
    /// - Throws: ``CalendarError/accessDenied`` if calendar access not granted.
    func getWeekEvents() async throws -> [CalendarEvent]

    /// Searches events by title or content within a future time window.
    ///
    /// Searches event titles and notes for the query string (case-insensitive).
    ///
    /// - Parameters:
    ///   - query: Search query string.
    ///   - daysAhead: Number of days ahead to search (from today).
    /// - Returns: Array of matching ``CalendarEvent`` objects.
    /// - Throws: ``CalendarError/accessDenied`` if calendar access not granted.
    func searchEvents(query: String, daysAhead: Int) async throws -> [CalendarEvent]

    // MARK: - Event CRUD Operations

    /// Creates a new calendar event with comprehensive options.
    ///
    /// Creates an event with all available EventKit properties including recurrence,
    /// alarms, attendees, and geofencing locations.
    ///
    /// - Parameters:
    ///   - title: Event title (required).
    ///   - startDate: Event start time.
    ///   - endDate: Event end time (must be after start).
    ///   - calendarName: Calendar to add event to. Uses default if `nil`.
    ///   - location: Optional human-readable location.
    ///   - notes: Optional event notes/description.
    ///   - isAllDay: Whether this is an all-day event (ignores time components).
    ///   - recurrence: Optional ``RecurrenceRule`` for repeating events.
    ///   - alarmMinutes: Minutes before event to trigger alarms (negative values).
    ///   - url: Optional URL associated with the event.
    ///   - availability: Event availability status (busy, free, tentative, unavailable).
    ///   - attendeeEmails: Email addresses of attendees (sends invites if supported).
    ///   - structuredLocation: Location with coordinates for geofencing reminders.
    /// - Returns: The created ``CalendarEvent`` with ID assigned.
    /// - Throws:
    ///   - ``CalendarError/accessDenied`` if calendar access not granted.
    ///   - ``CalendarError/noDefaultCalendar`` if no calendar specified and no default.
    ///   - ``CalendarError/calendarNotFound(_:)`` if specified calendar doesn't exist.
    ///   - ``CalendarError/calendarReadOnly`` if calendar is not editable.
    func addEvent(title: String, startDate: Date, endDate: Date, calendarName: String?,
                  location: String?, notes: String?, isAllDay: Bool,
                  recurrence: RecurrenceRule?, alarmMinutes: [Int]?,
                  url: String?, availability: EventAvailability?,
                  attendeeEmails: [String]?, structuredLocation: StructuredLocation?) async throws -> CalendarEvent

    /// Retrieves a single event by its unique identifier.
    ///
    /// - Parameter id: The event's EventKit identifier.
    /// - Returns: The ``CalendarEvent`` if found, `nil` otherwise.
    /// - Throws: ``CalendarError/accessDenied`` if calendar access not granted.
    func getEvent(id: String) async throws -> CalendarEvent?

    /// Deletes an event by title.
    ///
    /// If multiple events have the same title, deletes the first occurrence found.
    /// For recurring events, prompts to delete this occurrence or all future occurrences.
    ///
    /// - Parameter title: Title of the event to delete (exact match).
    /// - Returns: `true` if an event was deleted, `false` if not found.
    /// - Throws:
    ///   - ``CalendarError/accessDenied`` if calendar access not granted.
    ///   - ``CalendarError/eventNotFound(_:)`` if no event with that title exists.
    func deleteEvent(title: String) async throws -> Bool

    /// Updates an existing event's properties.
    ///
    /// Only non-nil parameters are updated. Finds the first event matching the title.
    ///
    /// - Parameters:
    ///   - title: Current title of the event to edit (exact match).
    ///   - newTitle: Optional new title.
    ///   - newStart: Optional new start time.
    ///   - newEnd: Optional new end time.
    /// - Returns: `true` if the event was updated.
    /// - Throws:
    ///   - ``CalendarError/accessDenied`` if calendar access not granted.
    ///   - ``CalendarError/eventNotFound(_:)`` if no event with that title exists.
    ///   - ``CalendarError/calendarReadOnly`` if event's calendar is not editable.
    func editEvent(title: String, newTitle: String?, newStart: Date?, newEnd: Date?) async throws -> Bool

    // MARK: - Advanced Operations

    /// Validates all events and returns those with potential issues.
    ///
    /// Checks for events with:
    /// - End time before start time
    /// - Missing required fields
    /// - Malformed data
    ///
    /// - Returns: Array of ``CalendarEvent`` objects that may have issues.
    /// - Throws: ``CalendarError/accessDenied`` if calendar access not granted.
    func validateEvents() async throws -> [CalendarEvent]

    /// Lists all attendees for a specific event.
    ///
    /// Returns attendee information including name, email, and RSVP status.
    /// Only events with attendees will return results.
    ///
    /// - Parameter eventId: The event's unique identifier.
    /// - Returns: Array of ``EventAttendee`` objects with RSVP status.
    /// - Throws:
    ///   - ``CalendarError/accessDenied`` if calendar access not granted.
    ///   - ``CalendarError/eventNotFound(_:)`` if event doesn't exist.
    func listAttendees(eventId: String) async throws -> [EventAttendee]

    /// Detects scheduling conflicts for a proposed time slot.
    ///
    /// Finds all existing events that overlap with the specified time range.
    /// Useful for checking availability before creating new events.
    ///
    /// - Parameters:
    ///   - startDate: Start of the time slot to check.
    ///   - endDate: End of the time slot to check.
    ///   - calendarName: Optional calendar to check. If `nil`, checks all calendars.
    /// - Returns: Array of ``CalendarEvent`` objects that conflict with the time slot.
    /// - Throws:
    ///   - ``CalendarError/accessDenied`` if calendar access not granted.
    ///   - ``CalendarError/calendarNotFound(_:)`` if specified calendar doesn't exist.
    func detectConflicts(startDate: Date, endDate: Date, calendarName: String?) async throws -> [CalendarEvent]

    // MARK: - Import/Export

    /// Exports calendar events to iCalendar (ICS) format.
    ///
    /// Creates a standard iCalendar file content that can be imported into other
    /// calendar applications. Includes all event properties.
    ///
    /// - Parameters:
    ///   - calendarName: Calendar to export.
    ///   - startDate: Start of date range to export.
    ///   - endDate: End of date range to export.
    /// - Returns: iCalendar formatted string (text/calendar MIME type).
    /// - Throws:
    ///   - ``CalendarError/accessDenied`` if calendar access not granted.
    ///   - ``CalendarError/calendarNotFound(_:)`` if specified calendar doesn't exist.
    func exportToICS(calendarName: String, startDate: Date, endDate: Date) async throws -> String

    /// Imports events from an iCalendar (ICS) file.
    ///
    /// Parses iCalendar format and creates events in the specified calendar.
    /// Skips events that already exist (based on UID).
    ///
    /// - Parameters:
    ///   - icsContent: iCalendar formatted content (RFC 5545).
    ///   - calendarName: Calendar to import events into.
    /// - Returns: Number of events successfully imported.
    /// - Throws:
    ///   - ``CalendarError/accessDenied`` if calendar access not granted.
    ///   - ``CalendarError/calendarNotFound(_:)`` if specified calendar doesn't exist.
    ///   - ``CalendarError/invalidDateFormat(_:)`` if ICS contains invalid dates.
    func importFromICS(icsContent: String, calendarName: String) async throws -> Int
}

// MARK: - Default Implementations

/// Default implementations for simplified event creation.
extension CalendarServiceProtocol {
    /// Creates a basic calendar event with minimal parameters.
    ///
    /// Convenience method for creating simple events without advanced features.
    /// Uses default calendar and no recurrence, alarms, or attendees.
    ///
    /// - Parameters:
    ///   - title: Event title.
    ///   - startDate: Event start time.
    ///   - endDate: Event end time.
    ///   - calendarName: Optional calendar name. Uses default if `nil`.
    ///   - location: Optional location.
    ///   - notes: Optional notes.
    ///   - isAllDay: Whether this is an all-day event. Default is `false`.
    /// - Returns: The created ``CalendarEvent``.
    public func addEvent(title: String, startDate: Date, endDate: Date, calendarName: String? = nil,
                         location: String? = nil, notes: String? = nil, isAllDay: Bool = false) async throws -> CalendarEvent {
        try await addEvent(title: title, startDate: startDate, endDate: endDate, calendarName: calendarName,
                          location: location, notes: notes, isAllDay: isAllDay,
                          recurrence: nil, alarmMinutes: nil, url: nil, availability: nil,
                          attendeeEmails: nil, structuredLocation: nil)
    }
}
