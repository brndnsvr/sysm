import ArgumentParser
import SysmCore

struct NetworkCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "network",
        abstract: "Network information and diagnostics",
        subcommands: [
            NetworkStatus_.self,
            NetworkWiFi.self,
            NetworkScan.self,
            NetworkInterfaces.self,
            NetworkDNS.self,
            NetworkPing.self,
        ]
    )
}
