import ArgumentParser
import Foundation
import SysmCore

struct NotesCreate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new note"
    )

    @Argument(help: "Title of the note")
    var title: String

    @Option(name: .shortAndLong, help: "Body content of the note")
    var body: String?

    @Option(name: .shortAndLong, help: "Folder to create the note in")
    var folder: String?

    @Flag(name: .long, help: "Read body content from stdin")
    var stdin: Bool = false

    func run() throws {
        let service = Services.notes()

        var noteBody = body ?? ""

        if stdin {
            var input = ""
            while let line = readLine(strippingNewline: false) {
                input += line
            }
            noteBody = input.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        do {
            let noteId = try service.createNote(name: title, body: noteBody, folder: folder)
            print("Created note '\(title)'")
            print("ID: \(noteId)")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
