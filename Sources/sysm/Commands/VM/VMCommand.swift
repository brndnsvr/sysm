import ArgumentParser
import SysmCore

struct VMCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "vm",
        abstract: "Create and manage virtual machines",
        subcommands: [
            VMList.self,
            VMCreate.self,
            VMStart.self,
            VMStop.self,
            VMInfoCmd.self,
            VMDelete.self,
            VMResize.self,
            VMShare.self,
            VMRosetta.self,
            VMSave.self,
            VMRestore.self,
        ]
    )
}
