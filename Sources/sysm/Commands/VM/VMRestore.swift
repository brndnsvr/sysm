import ArgumentParser
import Foundation
import SysmCore

struct VMRestore: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "restore",
        abstract: "Restore a VM from saved state (macOS 14+)"
    )

    @Argument(help: "VM name")
    var name: String

    func run() async throws {
        let service = Services.virtualization()
        try await service.restoreVM(name: name)
    }
}
