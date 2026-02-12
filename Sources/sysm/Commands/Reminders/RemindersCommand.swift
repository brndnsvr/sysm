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
            RemindersSearch.self,
            RemindersToday.self,
            RemindersAdd.self,
            RemindersEdit.self,
            RemindersMove.self,
            RemindersDelete.self,
            RemindersComplete.self,
            RemindersAddTags.self,
            RemindersRemoveTags.self,
            RemindersListTags.self,
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
