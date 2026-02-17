import ArgumentParser
import SysmCore

struct AppStoreCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "appstore",
        abstract: "Mac App Store management (requires mas)",
        subcommands: [
            AppStoreList.self,
            AppStoreOutdated.self,
            AppStoreSearch.self,
            AppStoreUpdate.self,
        ]
    )
}
