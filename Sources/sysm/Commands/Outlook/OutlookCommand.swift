import ArgumentParser

struct OutlookCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "outlook",
        abstract: "Microsoft Outlook email, calendar, and tasks",
        subcommands: [
            OutlookInbox.self,
            OutlookUnread.self,
            OutlookSearch.self,
            OutlookRead.self,
            OutlookSend.self,
            OutlookCalendar_.self,
            OutlookTasks.self,
        ]
    )
}
