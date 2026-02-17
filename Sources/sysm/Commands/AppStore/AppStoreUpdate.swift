import ArgumentParser
import Foundation
import SysmCore

struct AppStoreUpdate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update App Store apps"
    )

    @Argument(help: "App ID to update (updates all if omitted)")
    var appId: String?

    func run() throws {
        let service = Services.appStore()
        let result = try service.update(appId: appId)

        if result.isEmpty {
            print(appId != nil ? "App \(appId!) is up to date" : "All apps are up to date")
        } else {
            print(result)
        }
    }
}
