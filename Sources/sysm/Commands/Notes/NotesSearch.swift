import ArgumentParser
import Foundation
import SysmCore

struct NotesSearch: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search notes by title or content"
    )

    @Argument(help: "Search query")
    var query: String

    @Option(name: .long, help: "Search in specific folder only")
    var folder: String?

    @Flag(name: .long, help: "Search in note body (not just title)")
    var body: Bool = false

    @Flag(name: .long, help: "Show note content in results")
    var showContent: Bool = false

    @Flag(name: .shortAndLong, help: "Output as JSON")
    var json: Bool = false

    func run() throws {
        let service = Services.notes()
        let results = try service.searchNotes(query: query, searchBody: body, folder: folder)

        if json {
            try OutputFormatter.printJSON(results)
        } else {
            if results.isEmpty {
                let scope = folder.map { " in folder '\($0)'" } ?? ""
                let searchType = body ? "title and body" : "title"
                print("No notes found matching '\(query)' (\(searchType)\(scope))")
            } else {
                let scope = folder.map { " in folder '\($0)'" } ?? ""
                let searchType = body ? "title and body" : "title"
                print("Found \(results.count) note(s) matching '\(query)' (\(searchType)\(scope)):\n")

                for note in results {
                    print("[\(note.id)] \(note.name)")
                    print("  Folder: \(note.folder)")
                    if let created = note.creationDate {
                        print("  Created: \(formatDate(created))")
                    }
                    if showContent {
                        let preview = extractTextPreview(from: note.body)
                        print("  Preview: \(preview)")
                    }
                    print("")
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func extractTextPreview(from html: String, maxLength: Int = 150) -> String {
        // Strip HTML tags for preview
        let pattern = "<[^>]+>"
        let stripped = html.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if stripped.count > maxLength {
            return String(stripped.prefix(maxLength)) + "..."
        }
        return stripped
    }
}
