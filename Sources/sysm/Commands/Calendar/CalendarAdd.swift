import ArgumentParser
import Foundation

struct CalendarAdd: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a new calendar event"
    )

    @Argument(help: "Event title")
    var title: String

    @Option(name: .long, help: "Start date/time (e.g., 'tomorrow 2pm', 'next monday 10:00')")
    var start: String

    @Option(name: .long, help: "End date/time (defaults to 1 hour after start)")
    var end: String?

    @Option(name: .long, help: "Calendar name (uses default calendar if not specified)")
    var calendar: String?

    @Option(name: .long, help: "Event location")
    var location: String?

    @Option(name: .long, help: "Event notes")
    var notes: String?

    @Flag(name: .long, help: "Create as all-day event")
    var allDay = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        guard let startDate = DateParser.parse(start) else {
            throw CalendarError.invalidDateFormat(start)
        }

        let cal = Foundation.Calendar.current
        let endDate: Date
        if let endStr = end {
            guard let parsed = DateParser.parse(endStr) else {
                throw CalendarError.invalidDateFormat(endStr)
            }
            endDate = parsed
        } else if allDay {
            endDate = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: startDate))!
        } else {
            endDate = cal.date(byAdding: .hour, value: 1, to: startDate)!
        }

        let service = CalendarService()
        let event = try await service.addEvent(
            title: title,
            startDate: allDay ? cal.startOfDay(for: startDate) : startDate,
            endDate: endDate,
            calendarName: calendar,
            location: location,
            notes: notes,
            isAllDay: allDay
        )

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(event)
            print(String(data: data, encoding: .utf8)!)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = allDay ? .none : .short

            print("Created event: \(event.title)")
            print("  Calendar: \(event.calendarName)")
            print("  Start: \(formatter.string(from: event.startDate))")
            print("  End: \(formatter.string(from: event.endDate))")
            if let loc = event.location, !loc.isEmpty {
                print("  Location: \(loc)")
            }
        }
    }
}
