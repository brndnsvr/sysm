import ArgumentParser
import Foundation
import SysmCore

struct NetworkWiFi: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "wifi",
        abstract: "Show current WiFi connection info"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.network()
        guard let info = try service.getWiFiInfo() else {
            print("Not connected to WiFi")
            return
        }

        if json {
            try OutputFormatter.printJSON(info)
        } else {
            print("WiFi Connection:")
            print("  SSID: \(info.ssid)")
            if let bssid = info.bssid {
                print("  BSSID: \(bssid)")
            }
            if let channel = info.channel {
                print("  Channel: \(channel)")
            }
            if let rssi = info.rssi {
                print("  Signal: \(rssi) dBm \(signalQuality(rssi))")
            }
            if let noise = info.noise {
                print("  Noise: \(noise) dBm")
            }
            if let security = info.security {
                print("  Security: \(security)")
            }
        }
    }

    private func signalQuality(_ rssi: Int) -> String {
        switch rssi {
        case -30...0: return "(Excellent)"
        case -50 ... -31: return "(Good)"
        case -70 ... -51: return "(Fair)"
        default: return "(Weak)"
        }
    }
}
