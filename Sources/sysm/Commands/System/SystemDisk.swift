import ArgumentParser
import Foundation
import SysmCore

struct SystemDisk: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "disk",
        abstract: "Show disk usage"
    )

    @Option(name: .long, help: "Mount point to check (default: /)")
    var path: String = "/"

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.system()
        let disk = try service.getDiskUsage(path: path)

        if json {
            try OutputFormatter.printJSON(disk)
        } else {
            print("Mount:  \(disk.mountPoint)")
            print("Total:  \(disk.totalGB) GB")
            print("Used:   \(disk.usedGB) GB (\(disk.percentUsed)%)")
            print("Free:   \(disk.freeGB) GB")
        }
    }
}
