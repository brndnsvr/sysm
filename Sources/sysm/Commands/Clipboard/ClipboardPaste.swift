import ArgumentParser
import Foundation
import SysmCore

struct ClipboardPaste: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "paste",
        abstract: "Output current clipboard text"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.clipboard()

        if json {
            let result = ["text": service.getText() ?? ""]
            try OutputFormatter.printJSON(result)
        } else {
            if let text = service.getText() {
                print(text)
            } else {
                fputs("Clipboard is empty or contains non-text data\n", stderr)
            }
        }
    }
}
