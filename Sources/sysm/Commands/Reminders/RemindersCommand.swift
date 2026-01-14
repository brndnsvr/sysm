import ArgumentParser
import Foundation

struct RemindersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reminders",
        abstract: "Manage Apple Reminders",
        subcommands: [
            RemindersLists.self,
            RemindersList.self,
            RemindersToday.self,
            RemindersAdd.self,
            RemindersComplete.self,
            RemindersValidate.self,
            RemindersTrack.self,
            RemindersDismiss.self,
            RemindersTracked.self,
            RemindersDone.self,
            RemindersUntrack.self,
            RemindersNew.self,
            RemindersSync.self,
        ],
        defaultSubcommand: RemindersList.self
    )
}
