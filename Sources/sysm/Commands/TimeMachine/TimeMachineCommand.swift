import ArgumentParser
import SysmCore

struct TimeMachineCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "timemachine",
        abstract: "Time Machine backup management",
        subcommands: [
            TimeMachineStatus_.self,
            TimeMachineBackups.self,
            TimeMachineStart.self,
        ]
    )
}
