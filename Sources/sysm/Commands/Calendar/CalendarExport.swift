import ArgumentParser
import Foundation
import SysmCore

struct CalendarExport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export calendar events to iCalendar (.ics) format"
    )

    @Argument(help: "Calendar name to export")
    var calendar: String

    @Option(name: .long, help: "Start date for export range (defaults to 1 year ago)")
    var start: String?

    @Option(name: .long, help: "End date for export range (defaults to 1 year ahead)")
    var end: String?

    @Option(name: .long, help: "Output file path (defaults to stdout)")
    var output: String?

    func run() async throws {
        let cal = Foundation.Calendar.current

        let startDate: Date
        if let startStr = start {
            guard let parsed = Services.dateParser().parse(startStr) else {
                throw CalendarError.invalidDateFormat(startStr)
            }
            startDate = parsed
        } else {
            startDate = cal.date(byAdding: .year, value: -1, to: Date())!
        }

        let endDate: Date
        if let endStr = end {
            guard let parsed = Services.dateParser().parse(endStr) else {
                throw CalendarError.invalidDateFormat(endStr)
            }
            endDate = parsed
        } else {
            endDate = cal.date(byAdding: .year, value: 1, to: Date())!
        }

        let service = Services.calendar()
        let icsContent = try await service.exportToICS(
            calendarName: calendar,
            startDate: startDate,
            endDate: endDate
        )

        if let outputPath = output {
            try icsContent.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Exported calendar '\(calendar)' to \(outputPath)")
        } else {
            print(icsContent)
        }
    }
}
