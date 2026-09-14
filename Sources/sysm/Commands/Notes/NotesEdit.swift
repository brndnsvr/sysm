import ArgumentParser
import Foundation
import SysmCore

struct NotesEdit: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit an existing note"
    )

    @Argument(help: "ID of the note to edit")
    var id: String

    @Option(name: .shortAndLong, help: "New title for the note")
    var title: String?

    @Option(name: .shortAndLong, help: "New body content")
    var body: String?

    @Flag(name: .long, help: "Read body content from stdin")
    var stdin: Bool = false

    @Flag(name: .long, help: "Treat the body as HTML instead of plain text")
    var html = false

    func run() throws {
        let service = Services.notes()

        var noteBody = body

        if stdin {
            var input = ""
            while let line = readLine(strippingNewline: false) {
                input += line
            }
            noteBody = input.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard title != nil || noteBody != nil else {
            fputs("Error: specify --title or --body to update\n", stderr)
            throw ExitCode.failure
        }

        do {
            try service.updateNote(id: id, name: title, body: noteBody.map { html ? $0 : NotesPlainText.html($0) })
            print("Note updated")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
