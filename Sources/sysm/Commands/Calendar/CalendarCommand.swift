import ArgumentParser
import Foundation
import SysmCore

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
            CalendarAttendees.self,
            CalendarRename.self,
            CalendarSetColor.self,
            CalendarConflicts.self,
            CalendarImport.self,
            CalendarExport.self,
        ]
    )
}
