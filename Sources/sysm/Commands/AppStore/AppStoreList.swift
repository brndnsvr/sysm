import ArgumentParser
import Foundation
import SysmCore

struct AppStoreList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List installed App Store apps"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.appStore()
        let apps = try service.listInstalled()

        if json {
            try OutputFormatter.printJSON(apps)
        } else {
            if apps.isEmpty {
                print("No App Store apps installed")
            } else {
                print("Installed App Store apps (\(apps.count)):\n")
                for app in apps {
                    let version = app.version.map { " (\($0))" } ?? ""
                    print("  [\(app.id)] \(app.name)\(version)")
                }
            }
        }
    }
}
