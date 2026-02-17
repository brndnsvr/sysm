import ArgumentParser
import SysmCore

struct ClipboardClear: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear",
        abstract: "Clear the clipboard"
    )

    func run() throws {
        let service = Services.clipboard()
        service.clear()
        print("Clipboard cleared")
    }
}
