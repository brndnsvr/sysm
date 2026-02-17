import ArgumentParser
import SysmCore

struct SystemCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "system",
        abstract: "System information and diagnostics",
        subcommands: [
            SystemInfo_.self,
            SystemBattery.self,
            SystemUptime.self,
            SystemMemory.self,
            SystemDisk.self,
        ]
    )
}
