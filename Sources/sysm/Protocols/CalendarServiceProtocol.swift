import Foundation

/// Protocol for calendar service operations
protocol CalendarServiceProtocol: Sendable {
    func requestAccess() async throws -> Bool
    func listCalendars() async throws -> [String]
    func getEvents(from startDate: Date, to endDate: Date, calendar: String?) async throws -> [CalendarEvent]
    func getTodayEvents() async throws -> [CalendarEvent]
    func getWeekEvents() async throws -> [CalendarEvent]
    func searchEvents(query: String, daysAhead: Int) async throws -> [CalendarEvent]
    func addEvent(title: String, startDate: Date, endDate: Date, calendarName: String?,
                  location: String?, notes: String?, isAllDay: Bool) async throws -> CalendarEvent
    func deleteEvent(title: String) async throws -> Bool
    func editEvent(title: String, newTitle: String?, newStart: Date?, newEnd: Date?) async throws -> Bool
    func validateEvents() async throws -> [CalendarEvent]
}
