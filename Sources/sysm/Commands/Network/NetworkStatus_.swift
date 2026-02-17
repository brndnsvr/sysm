import ArgumentParser
import Foundation
import SysmCore

struct NetworkStatus_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show network connectivity status"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.network()
        let status = try service.getStatus()

        if json {
            try OutputFormatter.printJSON(status)
        } else {
            print("Network Status:")
            print("  Connected: \(status.connected ? "Yes" : "No")")
            if let primary = status.primaryInterface {
                print("  Primary Interface: \(primary)")
            }
            if !status.interfaces.isEmpty {
                print("  Active Interfaces: \(status.interfaces.joined(separator: ", "))")
            }
            if let ip = status.externalIP {
                print("  External IP: \(ip)")
            }
        }
    }
}
