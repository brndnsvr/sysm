import ArgumentParser
import Foundation
import SysmCore

struct CalendarImport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import events from an iCalendar (.ics) file"
    )

    @Argument(help: "Path to .ics file")
    var file: String

    @Option(name: .long, help: "Calendar name to import into")
    var calendar: String

    @Flag(name: .long, help: "Preview import without creating events")
    var dryRun = false

    func run() async throws {
        guard let icsContent = try? String(contentsOfFile: file, encoding: .utf8) else {
            throw CalendarError.invalidDateFormat("Unable to read file: \(file)")
        }

        let service = Services.calendar()

        if dryRun {
            let parser = ICSParser(content: icsContent)
            let events = try parser.parse()

            print("Preview: Would import \(events.count) event(s) into calendar '\(calendar)':")
            for (index, event) in events.enumerated() {
                print("\n\(index + 1). \(event.title)")
                print("   Start: \(DateFormatters.fullDateTime.string(from: event.startDate))")
                print("   End: \(DateFormatters.fullDateTime.string(from: event.endDate))")
                if let location = event.location {
                    print("   Location: \(location)")
                }
            }
        } else {
            let summary = try await service.importFromICS(
                icsContent: icsContent,
                calendarName: calendar
            )

            let skipped = summary.skippedExisting > 0 ? " (\(summary.skippedExisting) already there, skipped)" : ""
            print("Imported \(summary.imported) event(s) into calendar '\(calendar)'\(skipped)")
        }
    }
}
