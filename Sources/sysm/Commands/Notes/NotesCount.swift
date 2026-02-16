import ArgumentParser
import Foundation
import SysmCore

struct NotesCount: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "count",
        abstract: "Count notes in a folder or all folders"
    )

    @Option(name: .long, help: "Folder name (counts all notes if omitted)")
    var folder: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    private struct CountResult: Codable {
        let count: Int
        let folder: String
    }

    func run() throws {
        let service = Services.notes()
        let count = try service.countNotes(folder: folder)

        if json {
            try OutputFormatter.printJSON(CountResult(count: count, folder: folder ?? "all"))
        } else {
            if let folder = folder {
                print("\(count) note(s) in '\(folder)'")
            } else {
                print("\(count) note(s) total")
            }
        }
    }
}
