import ArgumentParser
import Foundation

struct CalendarCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendar",
        abstract: "Manage Apple Calendar events",
        subcommands: [
            CalendarCalendars.self,
            CalendarToday.self,
            CalendarWeek.self,
            CalendarList.self,
            CalendarSearch.self,
            CalendarAdd.self,
            CalendarEdit.self,
            CalendarDelete.self,
            CalendarValidate.self,
        ],
        defaultSubcommand: CalendarToday.self
    )
}
