import ArgumentParser
import Foundation
import SysmCore

struct RemindersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reminders",
        abstract: "Manage Apple Reminders",
        subcommands: [
            RemindersLists.self,
            RemindersList.self,
            RemindersToday.self,
            RemindersAdd.self,
            RemindersEdit.self,
            RemindersDelete.self,
            RemindersComplete.self,
            RemindersCreateList.self,
            RemindersDeleteList.self,
            RemindersValidate.self,
            RemindersTrack.self,
            RemindersDismiss.self,
            RemindersTracked.self,
            RemindersDone.self,
            RemindersUntrack.self,
            RemindersNew.self,
            RemindersSync.self,
        ]
    )
}
