import ArgumentParser
import Foundation
import SysmCore

struct VMStart: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start a virtual machine (foreground)"
    )

    @Argument(help: "VM name")
    var name: String

    @Option(name: .long, help: "Path to ISO installer image (Linux only)")
    var iso: String?

    func run() async throws {
        let service = Services.virtualization()
        try await service.startVM(name: name, isoPath: iso)
    }
}
