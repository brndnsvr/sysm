import ArgumentParser
import Foundation
import SysmCore

struct NotifyRemove: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove pending notifications"
    )

    @Argument(help: "Notification identifier to remove")
    var identifier: String?

    @Flag(name: .long, help: "Remove all pending notifications")
    var all = false

    func run() async throws {
        let service = Services.notification()

        if all {
            try await service.removeAllPending()
            print("All pending notifications removed")
        } else if let id = identifier {
            try await service.removePending(identifier: id)
            print("Notification \(id) removed")
        } else {
            throw ValidationError("Provide a notification identifier or use --all")
        }
    }
}
