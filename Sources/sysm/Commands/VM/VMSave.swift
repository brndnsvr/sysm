import ArgumentParser
import Foundation
import SysmCore

struct VMSave: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "save",
        abstract: "Save a running VM's state to disk (macOS 14+)"
    )

    @Argument(help: "VM name")
    var name: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.virtualization()
        try service.saveVM(name: name)

        if json {
            try OutputFormatter.printJSON(["status": "saving", "name": name])
        } else {
            print("Save signal sent to VM '\(name)'. The VM will save state and stop.")
        }
    }
}
