import ArgumentParser
import Foundation
import SysmCore

struct VMInfoCmd: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Show virtual machine details"
    )

    @Argument(help: "VM name")
    var name: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.virtualization()
        let info = try service.getVMInfo(name: name)

        if json {
            try OutputFormatter.printJSON(info)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium

            let state = info.state.rawValue
            print("VM: \(info.name)")
            print("  State: \(state)")
            print("  OS: \(info.os.rawValue)")
            print("  CPUs: \(info.cpus)")
            print("  Memory: \(info.memoryMB)MB")
            print("  Disk: \(info.diskSizeGB)GB")
            print("  Created: \(formatter.string(from: info.createdAt))")
            print("  Disk Path: \(info.diskPath)")

            if info.rosettaEnabled == true {
                print("  Rosetta: enabled")
            }
            if let dirs = info.sharedDirectories, !dirs.isEmpty {
                print("  Shared Directories:")
                for dir in dirs {
                    let mode = dir.readOnly ? "ro" : "rw"
                    print("    [\(dir.tag)] \(dir.hostPath) (\(mode))")
                }
            }

            // Show actual disk usage
            let diskURL = URL(fileURLWithPath: info.diskPath)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: diskURL.path),
               let size = attrs[.size] as? Int64 {
                print("  Disk Usage: \(OutputFormatter.formatFileSize(size))")
            }
        }
    }
}
