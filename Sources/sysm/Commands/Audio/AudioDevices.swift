import ArgumentParser
import Foundation
import SysmCore

struct AudioDevices: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "devices",
        abstract: "List audio devices"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.audio()
        let devices = try service.listDevices()

        if json {
            try OutputFormatter.printJSON(devices)
        } else {
            if devices.isEmpty {
                print("No audio devices found")
                return
            }
            for device in devices {
                var types: [String] = []
                if device.isInput { types.append("Input") }
                if device.isOutput { types.append("Output") }
                let typeStr = types.joined(separator: "/")
                print("  \(device.name) [\(typeStr)]")
                if let manufacturer = device.manufacturer {
                    print("    Manufacturer: \(manufacturer)")
                }
                print("    Sample Rate: \(Int(device.sampleRate)) Hz, Channels: \(device.channels)")
            }
        }
    }
}
