import EventKit
import Foundation

actor CalendarService: CalendarServiceProtocol {
    private let store = EKEventStore()

    func requestAccess() async throws -> Bool {
        if #available(macOS 14.0, *) {
            return try await store.requestFullAccessToEvents()
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    func ensureAccess() async throws {
        let granted = try await requestAccess()
        if !granted {
            throw CalendarError.accessDenied
        }
    }

    func listCalendars() async throws -> [String] {
        try await ensureAccess()
        let calendars = store.calendars(for: .event)
        return calendars.map { $0.title }
    }

    func getEvents(from startDate: Date, to endDate: Date, calendar: String? = nil) async throws -> [CalendarEvent] {
        try await ensureAccess()

        let calendars: [EKCalendar]
        if let calendarName = calendar {
            guard let cal = store.calendars(for: .event).first(where: { $0.title == calendarName }) else {
                throw CalendarError.calendarNotFound(calendarName)
            }
            calendars = [cal]
        } else {
            calendars = store.calendars(for: .event)
        }

        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let ekEvents = store.events(matching: predicate)

        return ekEvents.map { CalendarEvent(from: $0) }
            .sorted { $0.startDate < $1.startDate }
    }

    func getTodayEvents() async throws -> [CalendarEvent] {
        let cal = Foundation.Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!
        return try await getEvents(from: startOfDay, to: endOfDay)
    }

    func getWeekEvents() async throws -> [CalendarEvent] {
        let cal = Foundation.Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        let endOfWeek = cal.date(byAdding: .day, value: 7, to: startOfDay)!
        return try await getEvents(from: startOfDay, to: endOfWeek)
    }

    func searchEvents(query: String, daysAhead: Int = 30) async throws -> [CalendarEvent] {
        try await ensureAccess()

        let cal = Foundation.Calendar.current
        let startDate = cal.startOfDay(for: Date())
        let endDate = cal.date(byAdding: .day, value: daysAhead, to: startDate)!

        let calendars = store.calendars(for: .event)
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let ekEvents = store.events(matching: predicate)

        let lowercaseQuery = query.lowercased()
        return ekEvents
            .filter { event in
                (event.title?.lowercased().contains(lowercaseQuery) ?? false) ||
                (event.location?.lowercased().contains(lowercaseQuery) ?? false) ||
                (event.notes?.lowercased().contains(lowercaseQuery) ?? false)
            }
            .map { CalendarEvent(from: $0) }
            .sorted { $0.startDate < $1.startDate }
    }

    func addEvent(title: String, startDate: Date, endDate: Date, calendarName: String? = nil, location: String? = nil, notes: String? = nil, isAllDay: Bool = false) async throws -> CalendarEvent {
        try await ensureAccess()

        let calendar: EKCalendar
        if let name = calendarName {
            guard let cal = store.calendars(for: .event).first(where: { $0.title == name }) else {
                throw CalendarError.calendarNotFound(name)
            }
            calendar = cal
        } else {
            guard let defaultCal = store.defaultCalendarForNewEvents else {
                throw CalendarError.noDefaultCalendar
            }
            calendar = defaultCal
        }

        let year = Foundation.Calendar.current.component(.year, from: startDate)
        if year < 2000 || year > 2100 {
            throw CalendarError.invalidYear(year)
        }

        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = calendar
        event.isAllDay = isAllDay
        event.location = location
        event.notes = notes

        try store.save(event, span: .thisEvent)
        return CalendarEvent(from: event)
    }

    func deleteEvent(title: String) async throws -> Bool {
        try await ensureAccess()

        let cal = Foundation.Calendar.current
        let startDate = cal.date(byAdding: .day, value: -30, to: Date())!
        let endDate = cal.date(byAdding: .day, value: 365, to: Date())!

        let calendars = store.calendars(for: .event)
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let ekEvents = store.events(matching: predicate)

        guard let event = ekEvents.first(where: { $0.title == title }) else {
            return false
        }

        try store.remove(event, span: .thisEvent)
        return true
    }

    func editEvent(title: String, newTitle: String? = nil, newStart: Date? = nil, newEnd: Date? = nil) async throws -> Bool {
        try await ensureAccess()

        let cal = Foundation.Calendar.current
        let startDate = cal.date(byAdding: .day, value: -30, to: Date())!
        let endDate = cal.date(byAdding: .day, value: 365, to: Date())!

        let calendars = store.calendars(for: .event)
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let ekEvents = store.events(matching: predicate)

        guard let event = ekEvents.first(where: { $0.title == title }) else {
            return false
        }

        if let newTitle = newTitle {
            event.title = newTitle
        }
        if let newStart = newStart {
            let year = Foundation.Calendar.current.component(.year, from: newStart)
            if year < 2000 || year > 2100 {
                throw CalendarError.invalidYear(year)
            }
            event.startDate = newStart
        }
        if let newEnd = newEnd {
            event.endDate = newEnd
        }

        try store.save(event, span: .thisEvent)
        return true
    }

    func validateEvents() async throws -> [CalendarEvent] {
        try await ensureAccess()

        let cal = Foundation.Calendar.current
        let startDate = cal.date(byAdding: .year, value: -10, to: Date())!
        let endDate = cal.date(byAdding: .year, value: 100, to: Date())!

        let calendars = store.calendars(for: .event)
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let ekEvents = store.events(matching: predicate)

        return ekEvents.compactMap { event -> CalendarEvent? in
            let year = Foundation.Calendar.current.component(.year, from: event.startDate)
            if year < 2000 || year > 2100 {
                return CalendarEvent(from: event)
            }
            return nil
        }
    }
}

enum CalendarError: LocalizedError {
    case accessDenied
    case calendarNotFound(String)
    case noDefaultCalendar
    case invalidYear(Int)
    case eventNotFound(String)
    case invalidDateFormat(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied. Grant permission in System Settings > Privacy & Security > Calendars"
        case .calendarNotFound(let name):
            return "Calendar '\(name)' not found"
        case .noDefaultCalendar:
            return "No default calendar configured"
        case .invalidYear(let year):
            return "Year \(year) out of valid range (2000-2100)"
        case .eventNotFound(let name):
            return "Event '\(name)' not found"
        case .invalidDateFormat(let date):
            return "Invalid date format '\(date)'"
        }
    }
}
