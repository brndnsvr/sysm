import ArgumentParser
import Foundation
import SysmCore

struct ClipboardCopy: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "copy",
        abstract: "Copy text to clipboard"
    )

    @Argument(help: "Text to copy (reads from stdin if omitted)")
    var text: String?

    func run() throws {
        let service = Services.clipboard()

        let content: String
        if let text = text {
            content = text
        } else {
            // Read from stdin
            guard let stdinData = Optional(FileHandle.standardInput.availableData),
                  let stdinText = String(data: stdinData, encoding: .utf8),
                  !stdinText.isEmpty else {
                throw ValidationError("No text provided. Pass as argument or pipe via stdin.")
            }
            content = stdinText.trimmingCharacters(in: .newlines)
        }

        service.setText(content)
        fputs("Copied to clipboard (\(content.count) chars)\n", stderr)
    }
}
