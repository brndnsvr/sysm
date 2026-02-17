import ArgumentParser
import Foundation
import SysmCore

struct AppStoreSearch: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search the Mac App Store"
    )

    @Argument(help: "Search query")
    var query: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.appStore()
        let apps = try service.search(query: query)

        if json {
            try OutputFormatter.printJSON(apps)
        } else {
            if apps.isEmpty {
                print("No results for: \(query)")
            } else {
                print("Search results for '\(query)':\n")
                for app in apps {
                    let version = app.version.map { " (\($0))" } ?? ""
                    print("  [\(app.id)] \(app.name)\(version)")
                }
            }
        }
    }
}
