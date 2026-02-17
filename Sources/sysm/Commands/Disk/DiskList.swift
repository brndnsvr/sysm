import ArgumentParser
import Foundation
import SysmCore

struct DiskList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List mounted volumes"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.disk()
        let volumes = try service.listVolumes()

        if json {
            try OutputFormatter.printJSON(volumes)
        } else {
            if volumes.isEmpty {
                print("No volumes found")
            } else {
                print("Volumes (\(volumes.count)):\n")
                for vol in volumes {
                    let type = vol.isRemovable ? " [removable]" : ""
                    print("  \(vol.name)\(type)")
                    print("    Mount: \(vol.mountPoint)")
                    print("    Size: \(vol.totalSizeFormatted) (used: \(vol.usedSpaceFormatted), free: \(vol.freeSpaceFormatted))")
                    print("    Used: \(String(format: "%.1f", vol.usedPercent))%")
                    if let fs = vol.fileSystem {
                        print("    FS: \(fs)")
                    }
                    print()
                }
            }
        }
    }
}
