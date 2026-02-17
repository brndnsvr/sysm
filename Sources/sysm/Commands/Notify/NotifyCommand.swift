import ArgumentParser
import SysmCore

struct NotifyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "notify",
        abstract: "Send and manage notifications",
        subcommands: [
            NotifySend.self,
            NotifySchedule.self,
            NotifyList.self,
            NotifyRemove.self,
        ]
    )
}
