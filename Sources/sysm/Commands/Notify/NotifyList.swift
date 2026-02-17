import ArgumentParser
import Foundation
import SysmCore

struct NotifyList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List pending notifications"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.notification()
        let pending = try await service.listPending()

        if json {
            try OutputFormatter.printJSON(pending)
        } else {
            if pending.isEmpty {
                print("No pending notifications")
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short

                print("Pending notifications (\(pending.count)):\n")
                for n in pending {
                    print("  [\(n.identifier)]")
                    print("   Title: \(n.title)")
                    if !n.body.isEmpty {
                        print("   Body: \(n.body)")
                    }
                    if let sub = n.subtitle {
                        print("   Subtitle: \(sub)")
                    }
                    if let date = n.triggerDate {
                        print("   Trigger: \(formatter.string(from: date))")
                    }
                    print()
                }
            }
        }
    }
}
