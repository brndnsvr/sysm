import EventKit
import Foundation

public actor CalendarService: CalendarServiceProtocol {
    private let store = EKEventStore()

    static let validYearRange = 2000...2100

    private func validateYear(of date: Date) throws {
        let year = Foundation.Calendar.current.component(.year, from: date)
        guard Self.validYearRange.contains(year) else {
            throw CalendarError.invalidYear(year)
        }
    }

    public func requestAccess() async throws -> Bool {
        return try await store.requestFullAccessToEvents()
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

        try validateYear(of: startDate)

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

    public func findEvent(_ selector: EventSelector) async throws -> CalendarEvent {
        try await ensureAccess()
        return CalendarEvent(from: try resolveEvent(selector))
    }

    public func deleteEvent(_ selector: EventSelector, includeFuture: Bool) async throws -> CalendarEvent {
        try await ensureAccess()

        let event = try resolveEvent(selector)
        let deleted = CalendarEvent(from: event)
        try store.remove(event, span: Self.span(for: event, includeFuture: includeFuture))
        return deleted
    }

    public func editEvent(_ selector: EventSelector, newTitle: String? = nil, newStart: Date? = nil,
                          newEnd: Date? = nil, includeFuture: Bool = false) async throws -> CalendarEvent {
        try await ensureAccess()

        let event = try resolveEvent(selector)

        if let newTitle = newTitle {
            event.title = newTitle
        }
        if let newStart = newStart {
            try validateYear(of: newStart)
            event.startDate = newStart
        }
        if let newEnd = newEnd {
            event.endDate = newEnd
        }

        try store.save(event, span: Self.span(for: event, includeFuture: includeFuture))
        return CalendarEvent(from: event)
    }

    /// Finds the one occurrence a delete or edit acts on.
    ///
    /// Occurrences of a recurring event share an identifier, so an ID or a
    /// title can match many, and EventKit returns them in no set order.
    /// Taking the first match hit an arbitrary occurrence. The earliest
    /// occurrence that has not ended wins, else the latest past one. A title
    /// shared by different events is refused rather than guessed.
    private func resolveEvent(_ selector: EventSelector) throws -> EKEvent {
        let now = Date()
        let cal = Foundation.Calendar.current
        let predicate = store.predicateForEvents(
            withStart: cal.date(byAdding: .day, value: -30, to: now)!,
            end: cal.date(byAdding: .day, value: 365, to: now)!,
            calendars: nil
        )
        let events = store.events(matching: predicate)

        let matches: [EKEvent]
        switch selector {
        case .id(let id):
            matches = events.filter { $0.eventIdentifier == id }
            // Outside the search window, fall back to EventKit's own lookup,
            // which returns a recurring event's first occurrence.
            if matches.isEmpty, let event = store.event(withIdentifier: id) {
                return event
            }
        case .title(let title):
            matches = events.filter { $0.title == title }
            let series = Dictionary(grouping: matches) { $0.eventIdentifier ?? "" }
            if series.count > 1 {
                let candidates = series.values
                    .compactMap { occurrences in Self.preferredOccurrence(of: occurrences, now: now) }
                    .sorted { $0.startDate < $1.startDate }
                    .map { CalendarEvent(from: $0) }
                throw CalendarError.ambiguousEvent(title, candidates)
            }
        }

        guard let event = Self.preferredOccurrence(of: matches, now: now) else {
            throw CalendarError.eventNotFound(selector.description)
        }
        return event
    }

    /// The occurrence to act on: the earliest that has not ended, else the latest.
    static func preferredOccurrence<Event>(of events: [Event], now: Date,
                                           start: (Event) -> Date, end: (Event) -> Date) -> Event? {
        let byStart = events.sorted { start($0) < start($1) }
        return byStart.first { end($0) > now } ?? byStart.last
    }

    private static func preferredOccurrence(of events: [EKEvent], now: Date) -> EKEvent? {
        preferredOccurrence(of: events, now: now, start: { $0.startDate }, end: { $0.endDate })
    }

    private static func span(for event: EKEvent, includeFuture: Bool) -> EKSpan {
        includeFuture && event.hasRecurrenceRules ? .futureEvents : .thisEvent
    }

    public func validateEvents() async throws -> [CalendarEvent] {
        try await ensureAccess()

        // Birthdays come from Contacts and legitimately start before 2000.
        let calendars = store.calendars(for: .event).filter { $0.type != .birthday }
        var checked = Set<String>()
        var invalid: [CalendarEvent] = []

        for window in Self.validationWindows() {
            let predicate = store.predicateForEvents(withStart: window.start, end: window.end, calendars: calendars)
            for event in store.events(matching: predicate) {
                let key = event.eventIdentifier ?? UUID().uuidString
                guard checked.insert(key).inserted else { continue }

                // A series is judged by its first occurrence: a yearly event
                // begun in 2024 legitimately recurs past 2100.
                let first = event.hasRecurrenceRules ? store.event(withIdentifier: key) ?? event : event
                let year = Self.gregorian.component(.year, from: first.startDate)
                if !Self.validYearRange.contains(year) {
                    invalid.append(CalendarEvent(from: first))
                }
            }
        }
        return invalid
    }

    static let gregorian = Foundation.Calendar(identifier: .gregorian)

    /// Windows covering the years outside `validYearRange`.
    ///
    /// EventKit shortens an event predicate longer than four years to its
    /// first four (EKEventStore.h), so the old single -10y..+100y predicate
    /// only ever scanned its oldest four years. Only out-of-range years can
    /// hold an invalid event, so the valid span is skipped. Three-year
    /// windows stay under the limit whatever the leap days.
    static func validationWindows(calendar: Foundation.Calendar = gregorian) -> [DateInterval] {
        let spans = [
            (1, validYearRange.lowerBound),
            (validYearRange.upperBound + 1, validYearRange.upperBound + 101),
        ]
        var windows: [DateInterval] = []
        for (firstYear, endYear) in spans {
            var year = firstYear
            while year < endYear {
                let next = min(year + 3, endYear)
                let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
                let end = calendar.date(from: DateComponents(year: next, month: 1, day: 1))!
                windows.append(DateInterval(start: start, end: end))
                year = next
            }
        }
        return windows
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

        // events(matching:) returns every occurrence in the range. A repeating
        // series is exported once, from its first occurrence, with its rule;
        // an occurrence edited on its own stays as an exception.
        var seriesSeen = Set<String>()
        var exported: [EKEvent] = []
        for event in store.events(matching: predicate).sorted(by: { $0.startDate < $1.startDate }) {
            guard event.hasRecurrenceRules, !event.isDetached, let id = event.eventIdentifier else {
                exported.append(event)
                continue
            }
            if seriesSeen.insert(id).inserted {
                exported.append(store.event(withIdentifier: id) ?? event)
            }
        }

        return ICSGenerator.generate(events: exported, calendarName: calendarName)
    }

    public func importFromICS(icsContent: String, calendarName: String) async throws -> ICSImportSummary {
        try await ensureAccess()

        guard let calendar = store.calendars(for: .event).first(where: { $0.title == calendarName }) else {
            throw CalendarError.calendarNotFound(calendarName)
        }

        let parser = ICSParser(content: icsContent)
        let parsedEvents = try parser.parse()

        var imported = 0
        var skipped = 0
        for eventData in parsedEvents {
            if isAlreadyPresent(eventData, in: calendar) {
                skipped += 1
                continue
            }

            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = eventData.title
            event.startDate = eventData.startDate
            event.endDate = eventData.endDate
            event.isAllDay = eventData.isAllDay
            event.location = eventData.location
            event.notes = eventData.notes

            try store.save(event, span: .thisEvent)
            imported += 1
        }

        return ICSImportSummary(imported: imported, skippedExisting: skipped)
    }

    /// Whether the calendar already has an event the file describes: one whose
    /// external identifier is the file's UID, or one with the same title,
    /// start, and end. A saved event gets its external identifier from
    /// EventKit, not from the file, so the UID alone misses a second import of
    /// the same file.
    private func isAlreadyPresent(_ event: ICSEventData, in calendar: EKCalendar) -> Bool {
        if let uid = event.uid, !uid.isEmpty,
           store.calendarItems(withExternalIdentifier: uid)
               .contains(where: { $0.calendar?.calendarIdentifier == calendar.calendarIdentifier }) {
            return true
        }
        let predicate = store.predicateForEvents(withStart: event.startDate, end: event.endDate, calendars: [calendar])
        let existing: [(title: String, start: Date, end: Date)] = store.events(matching: predicate).map {
            ($0.title ?? "", $0.startDate, $0.endDate)
        }
        return Self.matchesExisting(event, existing)
    }

    /// Whether `existing` holds an event with the same title, start, and end.
    static func matchesExisting(_ event: ICSEventData, _ existing: [(title: String, start: Date, end: Date)]) -> Bool {
        existing.contains { $0.title == event.title && $0.start == event.startDate && $0.end == event.endDate }
    }
}

/// What an ICS import did.
public struct ICSImportSummary: Codable, Sendable {
    /// Events created in the calendar.
    public let imported: Int
    /// Events skipped because the calendar already had them.
    public let skippedExisting: Int

    public init(imported: Int, skippedExisting: Int) {
        self.imported = imported
        self.skippedExisting = skippedExisting
    }
}

/// Picks the event a delete or edit acts on.
public enum EventSelector: Sendable, CustomStringConvertible {
    /// An EventKit event identifier, as shown in `--json` output.
    case id(String)
    /// An exact event title.
    case title(String)

    public var description: String {
        switch self {
        case .id(let id): return id
        case .title(let title): return title
        }
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
    case ambiguousEvent(String, [CalendarEvent])

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access denied"
        case .calendarNotFound(let name):
            return "Calendar '\(name)' not found"
        case .noDefaultCalendar:
            return "No default calendar configured"
        case .invalidYear(let year):
            return "Year \(year) out of valid range (\(CalendarService.validYearRange.lowerBound)-\(CalendarService.validYearRange.upperBound))"
        case .eventNotFound(let name):
            return "Event '\(name)' not found"
        case .invalidDateFormat(let date):
            return "Invalid date format '\(date)'"
        case .calendarReadOnly(let name):
            return "Calendar '\(name)' is read-only and cannot be modified"
        case .invalidColor(let color):
            return "Invalid hex color '\(color)'. Expected format: #RRGGBB"
        case .ambiguousEvent(let title, let candidates):
            let choices = candidates.map {
                "  \($0.id)  \(DateFormatters.fullDateTime.string(from: $0.startDate))  (\($0.calendarName))"
            }
            return "\(candidates.count) different events are titled '\(title)'; choose one with --id:\n"
                + choices.joined(separator: "\n")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .ambiguousEvent:
            return "Pass the event's ID with --id instead of its title."
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
