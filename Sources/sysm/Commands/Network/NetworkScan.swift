import ArgumentParser
import Foundation
import SysmCore

struct NetworkScan: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scan",
        abstract: "Scan for available WiFi networks"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.network()
        let networks = try service.scanWiFi()

        if json {
            try OutputFormatter.printJSON(networks)
        } else {
            if networks.isEmpty {
                print("No WiFi networks found")
            } else {
                print("Available WiFi Networks (\(networks.count)):\n")
                for net in networks {
                    let signal = net.rssi.map { "\($0) dBm" } ?? "N/A"
                    let ch = net.channel.map { "Ch \($0)" } ?? ""
                    print("  \(net.ssid)")
                    print("    Signal: \(signal)  \(ch)")
                    if let bssid = net.bssid {
                        print("    BSSID: \(bssid)")
                    }
                }
            }
        }
    }
}
