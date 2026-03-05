import ArgumentParser
import Foundation
import SysmCore

struct VMResize: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "resize",
        abstract: "Resize a VM's disk (grow only)"
    )

    @Argument(help: "VM name")
    var name: String

    @Option(name: .long, help: "New disk size in GB")
    var disk: Int

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func validate() throws {
        guard disk > 0 else {
            throw ValidationError("Disk size must be positive")
        }
    }

    func run() throws {
        let service = Services.virtualization()
        try service.resizeDisk(name: name, newSizeGB: disk)

        if json {
            try OutputFormatter.printJSON(["status": "resized", "name": name, "diskSizeGB": "\(disk)"])
        } else {
            print("Resized VM '\(name)' disk to \(disk)GB")
        }
    }
}
