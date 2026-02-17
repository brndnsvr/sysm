import ArgumentParser
import Foundation
import SysmCore

struct AppStoreOutdated: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "outdated",
        abstract: "Show apps with available updates"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.appStore()
        let apps = try service.listOutdated()

        if json {
            try OutputFormatter.printJSON(apps)
        } else {
            if apps.isEmpty {
                print("All apps are up to date")
            } else {
                print("Updates available (\(apps.count)):\n")
                for app in apps {
                    let version = app.version.map { " → \($0)" } ?? ""
                    print("  [\(app.id)] \(app.name)\(version)")
                }
                print("\nRun 'sysm appstore update' to install all updates")
            }
        }
    }
}
