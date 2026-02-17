import ArgumentParser
import Foundation
import SysmCore

struct DiskInfo: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Show volume information for a path"
    )

    @Argument(help: "Path to check (defaults to /)")
    var path: String = "/"

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.disk()
        let vol = try service.getVolume(path: path)

        if json {
            try OutputFormatter.printJSON(vol)
        } else {
            print("Volume: \(vol.name)")
            print("  Mount Point: \(vol.mountPoint)")
            if let fs = vol.fileSystem {
                print("  File System: \(fs)")
            }
            print("  Total: \(vol.totalSizeFormatted)")
            print("  Used: \(vol.usedSpaceFormatted) (\(String(format: "%.1f", vol.usedPercent))%)")
            print("  Free: \(vol.freeSpaceFormatted)")
            print("  Internal: \(vol.isInternal ? "Yes" : "No")")
            print("  Removable: \(vol.isRemovable ? "Yes" : "No")")
        }
    }
}
