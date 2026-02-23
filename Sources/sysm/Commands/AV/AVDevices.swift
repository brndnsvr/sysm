import ArgumentParser
import Foundation
import SysmCore

struct AVDevices: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "devices",
        abstract: "List audio input devices"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.av()
        let devices = try await service.listInputDevices()

        if json {
            try OutputFormatter.printJSON(devices)
        } else {
            if devices.isEmpty {
                print("No audio input devices found")
            } else {
                for device in devices {
                    let marker = device.isDefault ? " (default)" : ""
                    print("  \(device.name)\(marker)")
                    print("    ID: \(device.id)")
                }
            }
        }
    }
}
