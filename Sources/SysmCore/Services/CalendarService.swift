import EventKit
import Foundation

public actor CalendarService: CalendarServiceProtocol {
    private let store = EKEventStore()

    public func requestAccess() async throws -> Bool {
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

    public func ensureAccess() async throws {
        let granted = try await requestAccess()
        if !granted {
            throw CalendarError.accessDenied
        }
    }

    public func listCalendars() async throws -> [String] {
        try await ensureAccess()
        let calendars = store.calendars(for: .event)
        return calendars.map { $0.title }
    }

    public func listCalendarsDetailed() async throws -> [CalendarInfo] {
        try await ensureAccess()
        let ekCalendars = store.calendars(for: .event)
        return ekCalendars.map { CalendarInfo(from: $0) }
    }

    public func renameCalendar(name: String, newName: String) async throws -> Bool {
        try await ensureAccess()

        guard let calendar = store.calendars(for: .event).first(where: { $0.title == name }) else {
            throw CalendarError.calendarNotFound(name)
        }

        guard calendar.allowsContentModifications else {
            throw CalendarError.calendarReadOnly(name)
        }

        calendar.title = newName
        try store.saveCalendar(calendar, commit: true)
        return true
    }

    public func setCalendarColor(name: String, hexColor: String) async throws -> Bool {
        try await ensureAccess()

        guard let calendar = store.calendars(for: .event).first(where: { $0.title == name }) else {
            throw CalendarError.calendarNotFound(name)
        }

        guard calendar.allowsContentModifications else {
            throw CalendarError.calendarReadOnly(name)
        }

        guard let cgColor = hexColor.toCGColor() else {
            throw CalendarError.invalidColor(hexColor)
        }

        calendar.cgColor = cgColor
        try store.saveCalendar(calendar, commit: true)
        return true
    }

    public func getEvents(from startDate: Date, to endDate: Date, calendar: String? = nil) async throws -> [CalendarEvent] {
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

    public func getTodayEvents() async throws -> [CalendarEvent] {
        let cal = Foundation.Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay)!
        return try await getEvents(from: startOfDay, to: endOfDay)
    }

    public func getWeekEvents() async throws -> [CalendarEvent] {
        let cal = Foundation.Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        let endOfWeek = cal.date(byAdding: .day, value: 7, to: startOfDay)!
        return try await getEvents(from: startOfDay, to: endOfWeek)
    }

    public func searchEvents(query: String, daysAhead: Int = 30) async throws -> [CalendarEvent] {
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

    public func addEvent(title: String, startDate: Date, endDate: Date, calendarName: String? = nil,
                         location: String? = nil, notes: String? = nil, isAllDay: Bool = false,
                         recurrence: RecurrenceRule? = nil, alarmMinutes: [Int]? = nil,
                         url: String? = nil, availability: EventAvailability? = nil,
                         attendeeEmails: [String]? = nil, structuredLocation: StructuredLocation? = nil) async throws -> CalendarEvent {
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

        // Set location (prefer structured location if provided)
        if let structLoc = structuredLocation {
            event.structuredLocation = structLoc.toEKStructuredLocation()
            event.location = structLoc.title
        } else if let loc = location {
            event.location = loc
        }

        event.notes = notes

        // Add recurrence rule
        if let recurrence = recurrence {
            event.addRecurrenceRule(recurrence.toEKRecurrenceRule())
        }

        // Add alarms
        if let alarmMinutes = alarmMinutes {
            for minutes in alarmMinutes {
                let alarm = EKAlarm(relativeOffset: TimeInterval(-minutes * 60))
                event.addAlarm(alarm)
            }
        }

        // Set URL
        if let urlString = url, let eventUrl = URL(string: urlString) {
            event.url = eventUrl
        }

        // Set availability
        if let availability = availability {
            event.availability = availability.ekAvailability
        }

        // Note: EventKit on macOS does not support programmatically adding attendees
        // The attendeeEmails parameter is kept for API consistency but ignored
        // Attendees must be added through Calendar.app or via calendar invitations

        try store.save(event, span: .thisEvent)
        return CalendarEvent(from: event)
    }

    public func getEvent(id: String) async throws -> CalendarEvent? {
        try await ensureAccess()
        guard let event = store.event(withIdentifier: id) else {
            return nil
        }
        return CalendarEvent(from: event)
    }

    public func deleteEvent(title: String) async throws -> Bool {
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

    public func editEvent(title: String, newTitle: String? = nil, newStart: Date? = nil, newEnd: Date? = nil) async throws -> Bool {
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

    public func validateEvents() async throws -> [CalendarEvent] {
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

    public func listAttendees(eventId: String) async throws -> [EventAttendee] {
        try await ensureAccess()

        guard let event = store.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound(eventId)
        }

        if let attendees = event.attendees {
            return attendees.map { EventAttendee(from: $0) }
        }
        return []
    }

    public func detectConflicts(startDate: Date, endDate: Date, calendarName: String? = nil) async throws -> [CalendarEvent] {
        try await ensureAccess()

        let calendars: [EKCalendar]
        if let calendarName = calendarName {
            guard let cal = store.calendars(for: .event).first(where: { $0.title == calendarName }) else {
                throw CalendarError.calendarNotFound(calendarName)
            }
            calendars = [cal]
        } else {
            calendars = store.calendars(for: .event)
        }

        // Get all events in a wider range to catch potential conflicts
        let searchStart = Foundation.Calendar.current.date(byAdding: .day, value: -1, to: startDate)!
        let searchEnd = Foundation.Calendar.current.date(byAdding: .day, value: 1, to: endDate)!

        let predicate = store.predicateForEvents(withStart: searchStart, end: searchEnd, calendars: calendars)
        let ekEvents = store.events(matching: predicate)

        // Filter events that actually conflict with the requested time slot
        let conflicts = ekEvents.filter { event in
            // Skip all-day events for conflict detection
            guard !event.isAllDay else { return false }

            // Check if events overlap
            // Events overlap if: event.start < slot.end AND event.end > slot.start
            return event.startDate < endDate && event.endDate > startDate
        }

        return conflicts.map { CalendarEvent(from: $0) }
            .sorted { $0.startDate < $1.startDate }
    }

    public func exportToICS(calendarName: String, startDate: Date, endDate: Date) async throws -> String {
        try await ensureAccess()

        guard let calendar = store.calendars(for: .event).first(where: { $0.title == calendarName }) else {
            throw CalendarError.calendarNotFound(calendarName)
        }

        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
        let ekEvents = store.events(matching: predicate)

        return ICSGenerator.generate(events: ekEvents, calendarName: calendarName)
    }

    public func importFromICS(icsContent: String, calendarName: String) async throws -> Int {
        try await ensureAccess()

        guard let calendar = store.calendars(for: .event).first(where: { $0.title == calendarName }) else {
            throw CalendarError.calendarNotFound(calendarName)
        }

        let parser = ICSParser(content: icsContent)
        let parsedEvents = try parser.parse()

        var importedCount = 0
        for eventData in parsedEvents {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = eventData.title
            event.startDate = eventData.startDate
            event.endDate = eventData.endDate
            event.isAllDay = eventData.isAllDay
            event.location = eventData.location
            event.notes = eventData.notes

            try store.save(event, span: .thisEvent)
            importedCount += 1
        }

        return importedCount
    }
}

public enum CalendarError: LocalizedError {
    case accessDenied
    case calendarNotFound(String)
    case noDefaultCalendar
    case invalidYear(Int)
    case eventNotFound(String)
    case invalidDateFormat(String)
    case calendarReadOnly(String)
    case invalidColor(String)

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied"
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
        case .calendarReadOnly(let name):
            return "Calendar '\(name)' is read-only and cannot be modified"
        case .invalidColor(let color):
            return "Invalid hex color '\(color)'. Expected format: #RRGGBB"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .accessDenied:
            return """
            Grant calendar access in System Settings:
            1. Open System Settings
            2. Navigate to Privacy & Security > Calendars
            3. Enable access for Terminal (or your terminal app)
            4. Restart sysm

            Quick: open "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
            """
        case .calendarNotFound(let name):
            return """
            The calendar '\(name)' doesn't exist.

            Try:
            - List available calendars: sysm calendar list
            - Use default calendar (omit --calendar flag)
            """
        case .noDefaultCalendar:
            return """
            No default calendar is configured.

            Try:
            - Specify a calendar: sysm calendar add "Event" --calendar "Work"
            - List available calendars: sysm calendar list
            """
        case .invalidYear:
            return "Use a year between 2000 and 2100"
        case .eventNotFound(let title):
            return """
            Event '\(title)' not found.

            Try:
            - List today's events: sysm calendar today
            - Search events: sysm calendar search '\(title)'
            - List all calendars: sysm calendar list
            """
        case .invalidDateFormat(let date):
            return """
            Invalid date format: '\(date)'

            Supported formats:
            - "tomorrow 2pm"
            - "2024-12-25 14:00"
            - "next monday 9am"
            - "today"
            """
        case .calendarReadOnly:
            return "This calendar cannot be modified. Use a different calendar or create a new one."
        case .invalidColor:
            return """
            Hex color must be in format #RRGGBB

            Examples:
            - #FF5733 (red-orange)
            - #3498DB (blue)
            - #2ECC71 (green)
            """
        }
    }
}

extension String {
    func toCGColor() -> CGColor? {
        var hexSanitized = self.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        return CGColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
