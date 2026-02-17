import ArgumentParser
import Foundation
import SysmCore

struct DiskEject: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "eject",
        abstract: "Eject a volume"
    )

    @Argument(help: "Volume name to eject")
    var name: String

    func run() throws {
        let service = Services.disk()
        try service.ejectVolume(name: name)
        print("Ejected: \(name)")
    }
}
