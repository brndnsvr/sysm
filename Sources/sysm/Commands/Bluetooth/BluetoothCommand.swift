import ArgumentParser
import SysmCore

struct BluetoothCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "bluetooth",
        abstract: "Bluetooth device management",
        subcommands: [
            BluetoothStatus_.self,
            BluetoothDevices.self,
        ]
    )
}
