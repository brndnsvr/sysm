import ArgumentParser
import Foundation
import SysmCore

struct BluetoothStatus_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show Bluetooth status"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.bluetooth()
        let status = try service.getStatus()

        if json {
            try OutputFormatter.printJSON(status)
        } else {
            print("Bluetooth Status:")
            print("  Powered: \(status.powered ? "On" : "Off")")
            print("  Discoverable: \(status.discoverable ? "Yes" : "No")")
            if let address = status.address {
                print("  Address: \(address)")
            }
        }
    }
}
