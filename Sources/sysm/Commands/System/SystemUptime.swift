import ArgumentParser
import Foundation
import SysmCore

struct SystemUptime: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uptime",
        abstract: "Show system uptime"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.system()
        let seconds = service.getUptime()

        if json {
            try OutputFormatter.printJSON(["uptimeSeconds": Int(seconds)])
        } else {
            let days = Int(seconds) / 86400
            let hours = (Int(seconds) % 86400) / 3600
            let minutes = (Int(seconds) % 3600) / 60

            var parts: [String] = []
            if days > 0 { parts.append("\(days) day\(days == 1 ? "" : "s")") }
            if hours > 0 { parts.append("\(hours) hour\(hours == 1 ? "" : "s")") }
            parts.append("\(minutes) minute\(minutes == 1 ? "" : "s")")

            print("Up \(parts.joined(separator: ", "))")
        }
    }
}
