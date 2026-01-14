import ArgumentParser
import Foundation

struct FocusList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available Focus modes"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = FocusService()
        let modes = try service.listFocusModes()

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonModes = modes.map { ["name": $0] }
            let data = try encoder.encode(jsonModes)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
        } else {
            print("Focus Modes (\(modes.count)):")
            for mode in modes {
                print("  - \(mode)")
            }
        }
    }
}
