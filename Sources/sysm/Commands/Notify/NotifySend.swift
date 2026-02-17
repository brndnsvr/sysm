import ArgumentParser
import Foundation
import SysmCore

struct NotifySend: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send a notification immediately"
    )

    @Argument(help: "Notification title")
    var title: String

    @Argument(help: "Notification body")
    var body: String

    @Option(name: .long, help: "Notification subtitle")
    var subtitle: String?

    @Flag(name: .long, help: "Play notification sound")
    var sound = false

    func run() async throws {
        let service = Services.notification()
        try await service.send(title: title, body: body, subtitle: subtitle, sound: sound)
        print("Notification sent: \(title)")
    }
}
