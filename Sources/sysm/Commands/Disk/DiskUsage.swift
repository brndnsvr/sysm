import ArgumentParser
import Foundation
import SysmCore

struct DiskUsage: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "usage",
        abstract: "Show directory size"
    )

    @Argument(help: "Directory path")
    var path: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.disk()
        let usage = try service.getDirectorySize(path: path)

        if json {
            try OutputFormatter.printJSON(usage)
        } else {
            print("Directory: \(usage.path)")
            print("  Size: \(usage.sizeFormatted)")
            print("  Files: \(usage.fileCount)")
        }
    }
}
