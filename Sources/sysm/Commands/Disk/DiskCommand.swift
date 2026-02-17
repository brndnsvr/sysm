import ArgumentParser
import SysmCore

struct DiskCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "disk",
        abstract: "Disk and volume management",
        subcommands: [
            DiskList.self,
            DiskInfo.self,
            DiskUsage.self,
            DiskEject.self,
        ]
    )
}
