import ArgumentParser
import Foundation
import SysmCore

struct AVFormats: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "formats",
        abstract: "List supported audio formats"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.av()
        let formats = service.supportedFormats()

        if json {
            try OutputFormatter.printJSON(formats)
        } else {
            for format in formats {
                print("  \(format.displayName) (.\(format.fileExtension))")
            }
        }
    }
}
