import ArgumentParser
import Foundation
import SysmCore

struct VMStop: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stop",
        abstract: "Stop a running virtual machine"
    )

    @Argument(help: "VM name")
    var name: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.virtualization()
        try service.stopVM(name: name)

        if json {
            try OutputFormatter.printJSON(["status": "stopped", "name": name])
        } else {
            print("Stop signal sent to VM '\(name)'")
        }
    }
}
