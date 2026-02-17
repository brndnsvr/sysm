import ArgumentParser
import Foundation
import SysmCore

struct BluetoothDevices: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "devices",
        abstract: "List paired Bluetooth devices"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.bluetooth()
        let devices = try service.listDevices()

        if json {
            try OutputFormatter.printJSON(devices)
        } else {
            if devices.isEmpty {
                print("No paired Bluetooth devices")
            } else {
                print("Paired Bluetooth Devices (\(devices.count)):\n")
                for device in devices {
                    let status = device.connected ? "Connected" : "Not Connected"
                    let type = device.deviceType.map { " (\($0))" } ?? ""
                    print("  \(device.name)\(type) [\(status)]")
                    print("    Address: \(device.address)")
                }
            }
        }
    }
}
