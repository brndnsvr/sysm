import ArgumentParser
import Foundation
import SysmCore

struct VMRosetta: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rosetta",
        abstract: "Manage Rosetta for Linux VMs (Apple Silicon)",
        subcommands: [
            VMRosettaEnable.self,
        ]
    )
}

struct VMRosettaEnable: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "enable",
        abstract: "Enable Rosetta x86_64 translation in a Linux VM"
    )

    @Argument(help: "VM name")
    var name: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.virtualization()
        try service.enableRosetta(name: name)

        if json {
            try OutputFormatter.printJSON(["status": "enabled", "vm": name, "feature": "rosetta"])
        } else {
            print("Rosetta enabled for VM '\(name)'")
            print("  Mount in guest: mount -t virtiofs rosetta /mnt/rosetta")
            print("  Register: update-binfmts --install rosetta /mnt/rosetta/rosetta --magic '\\x7fELF\\x02\\x01\\x01\\x00...' --mask '\\xff\\xff\\xff\\xff\\xff\\xfe\\xfe\\x00...'")
        }
    }
}
