import ArgumentParser
import Foundation
import SysmCore

struct SafariCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "safari",
        abstract: "Manage Safari reading list, bookmarks, and tabs",
        subcommands: [
            SafariReadingList.self,
            SafariBookmarks.self,
            SafariTabs.self,
        ]
    )
}
