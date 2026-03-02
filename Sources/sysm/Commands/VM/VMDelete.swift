import ArgumentParser
import Foundation
import SysmCore

struct VMDelete: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a virtual machine"
    )

    @Argument(help: "VM name")
    var name: String

    @Flag(name: .shortAndLong, help: "Skip confirmation")
    var force = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        if !force {
            guard CLI.confirm("Delete VM '\(name)' and all its data? [y/N] ") else {
                return
            }
        }

        let service = Services.virtualization()
        try service.deleteVM(name: name)

        if json {
            try OutputFormatter.printJSON(["status": "deleted", "name": name])
        } else {
            print("Deleted VM '\(name)'")
        }
    }
}
