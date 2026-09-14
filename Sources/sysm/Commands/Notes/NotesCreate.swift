import ArgumentParser
import Foundation
import SysmCore

struct NotesCreate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new note",
        discussion: """
        Use --from-markdown to create Notes-native structured content. Supported mappings:
          # Title, ## Heading, ### Subheading
          plain paragraphs
          - [ ] unchecked checklist item
          - [x] checked checklist item

        The Markdown source can be a UTF-8 file or '-' for stdin. Structured formatting requires
        Automation and Accessibility permission plus an iCloud or On My Mac Notes folder.
        """
    )

    @Argument(help: "Title of the note")
    var title: String

    @Option(name: .shortAndLong, help: "Body content of the note")
    var body: String?

    @Option(name: .shortAndLong, help: "Folder to create the note in")
    var folder: String?

    @Flag(name: .long, help: "Read body content from stdin")
    var stdin: Bool = false

    @Flag(name: .long, help: "Treat the body as HTML instead of plain text")
    var html = false

    @Option(name: .long, help: "Read structured Notes Markdown from a UTF-8 file, or '-' for stdin")
    var fromMarkdown: String?

    func run() throws {
        if fromMarkdown != nil, body != nil || stdin {
            throw ValidationError("--from-markdown cannot be combined with --body or --stdin")
        }

        do {
            let service = Services.notes()

            let noteId: String
            if let fromMarkdown {
                let markdown = try readMarkdown(from: fromMarkdown)
                noteId = try service.createStructuredNote(name: title, markdown: markdown, folder: folder)
            } else {
                var noteBody = body ?? ""
                if stdin {
                    noteBody = readStandardInput().trimmingCharacters(in: .whitespacesAndNewlines)
                }
                let bodyHTML = html ? noteBody : NotesPlainText.html(noteBody)
                noteId = try service.createNote(name: title, body: bodyHTML, folder: folder)
            }

            print("Created note '\(title)'")
            print("ID: \(noteId)")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }

    private func readMarkdown(from source: String) throws -> String {
        guard source != "-" else { return readStandardInput() }
        return try String(contentsOf: URL(fileURLWithPath: source), encoding: .utf8)
    }

    private func readStandardInput() -> String {
        var input = ""
        while let line = readLine(strippingNewline: false) {
            input += line
        }
        return input
    }
}
