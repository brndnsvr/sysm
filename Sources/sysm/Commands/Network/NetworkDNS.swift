import ArgumentParser
import Foundation
import SysmCore

struct NetworkDNS: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dns",
        abstract: "Show DNS servers"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.network()
        let servers = try service.getDNS()

        if json {
            try OutputFormatter.printJSON(servers)
        } else {
            if servers.isEmpty {
                print("No DNS servers found")
            } else {
                print("DNS Servers:")
                for server in servers {
                    print("  \(server)")
                }
            }
        }
    }
}
