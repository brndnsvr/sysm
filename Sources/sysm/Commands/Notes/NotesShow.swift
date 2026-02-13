import ArgumentParser
import Foundation
import SysmCore

struct NotesShow: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Display a specific note's content"
    )

    @Argument(help: "Note ID to display")
    var noteId: String

    @Flag(name: .long, help: "Show raw HTML content instead of plain text")
    var raw: Bool = false

    @Flag(name: .shortAndLong, help: "Output as JSON")
    var json: Bool = false

    func run() throws {
        let service = Services.notes()

        guard let note = try service.getNote(id: noteId) else {
            throw NotesError.noteNotFound(noteId)
        }

        if json {
            try OutputFormatter.printJSON(note)
        } else {
            print("Title: \(note.name)")
            print("Folder: \(note.folder)")
            if let created = note.creationDate {
                print("Created: \(formatDate(created))")
            }
            if let modified = note.modificationDate {
                print("Modified: \(formatDate(modified))")
            }
            print("ID: \(note.id)")
            print("")
            print("Content:")
            print("─────────────────────────────────────────────────────")

            if raw {
                print(note.body)
            } else {
                // Strip HTML for cleaner display
                let plainText = stripHTML(from: note.body)
                print(plainText)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func stripHTML(from html: String) -> String {
        // Basic HTML tag stripping
        let pattern = "<[^>]+>"
        let stripped = html.replacingOccurrences(of: pattern, with: "", options: .regularExpression)

        // Decode common HTML entities
        let decoded = stripped
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")

        return decoded.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
