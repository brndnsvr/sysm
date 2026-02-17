import ArgumentParser
import Foundation
import SysmCore

struct NetworkInterfaces: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "interfaces",
        abstract: "List network interfaces"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.network()
        let interfaces = try service.listInterfaces()

        if json {
            try OutputFormatter.printJSON(interfaces)
        } else {
            if interfaces.isEmpty {
                print("No network interfaces found")
            } else {
                print("Network Interfaces (\(interfaces.count)):\n")
                for iface in interfaces {
                    print("  \(iface.name) [\(iface.status)]")
                    if let ip = iface.ipAddress {
                        print("    IP: \(ip)")
                    }
                    if let mac = iface.macAddress, mac != "(null)" {
                        print("    MAC: \(mac)")
                    }
                }
            }
        }
    }
}
