import ArgumentParser
import Foundation
import SysmCore

struct FocusList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available Focus modes"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.focus()
        let modes = try service.listFocusModes()

        if json {
            let jsonModes = modes.map { ["name": $0] }
            try OutputFormatter.printJSON(jsonModes)
        } else {
            print("Focus Modes (\(modes.count)):")
            for mode in modes {
                print("  - \(mode)")
            }
        }
    }
}
