import ArgumentParser
import Foundation

struct NotesFolders: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "folders",
        abstract: "List all note folders"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = NotesService()
        let folders = try service.listFolders()

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(folders)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print("Note Folders:")
            for folder in folders {
                print("  - \(folder)")
            }
        }
    }
}
