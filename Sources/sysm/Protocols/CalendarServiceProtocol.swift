import Foundation

/// Protocol defining calendar service operations for accessing and managing macOS Calendar events.
///
/// Implementations provide access to the user's calendars and events through EventKit,
/// supporting queries by date range, search, and calendar filtering.
protocol CalendarServiceProtocol: Sendable {
    /// Requests access to the user's calendar data.
    /// - Returns: `true` if access was granted.
    /// - Throws: If access cannot be determined.
    func requestAccess() async throws -> Bool

    /// Lists all available calendars.
    /// - Returns: Array of calendar names.
    func listCalendars() async throws -> [String]

    /// Retrieves events within a date range.
    /// - Parameters:
    ///   - startDate: Start of the date range.
    ///   - endDate: End of the date range.
    ///   - calendar: Optional calendar name to filter by.
    /// - Returns: Array of events in the range.
    func getEvents(from startDate: Date, to endDate: Date, calendar: String?) async throws -> [CalendarEvent]

    /// Retrieves all events for today.
    /// - Returns: Array of today's events.
    func getTodayEvents() async throws -> [CalendarEvent]

    /// Retrieves all events for the current week.
    /// - Returns: Array of events for the week.
    func getWeekEvents() async throws -> [CalendarEvent]

    /// Searches events by title or content.
    /// - Parameters:
    ///   - query: Search query string.
    ///   - daysAhead: Number of days ahead to search.
    /// - Returns: Array of matching events.
    func searchEvents(query: String, daysAhead: Int) async throws -> [CalendarEvent]

    /// Creates a new calendar event.
    /// - Parameters:
    ///   - title: Event title.
    ///   - startDate: Event start time.
    ///   - endDate: Event end time.
    ///   - calendarName: Optional calendar to add event to.
    ///   - location: Optional event location.
    ///   - notes: Optional event notes.
    ///   - isAllDay: Whether this is an all-day event.
    /// - Returns: The created event.
    func addEvent(title: String, startDate: Date, endDate: Date, calendarName: String?,
                  location: String?, notes: String?, isAllDay: Bool) async throws -> CalendarEvent

    /// Deletes an event by title.
    /// - Parameter title: Title of the event to delete.
    /// - Returns: `true` if the event was deleted.
    func deleteEvent(title: String) async throws -> Bool

    /// Edits an existing event.
    /// - Parameters:
    ///   - title: Current title of the event to edit.
    ///   - newTitle: Optional new title.
    ///   - newStart: Optional new start time.
    ///   - newEnd: Optional new end time.
    /// - Returns: `true` if the event was updated.
    func editEvent(title: String, newTitle: String?, newStart: Date?, newEnd: Date?) async throws -> Bool

    /// Validates and returns events that may have issues.
    /// - Returns: Array of events with validation concerns.
    func validateEvents() async throws -> [CalendarEvent]
}
